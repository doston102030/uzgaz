-- Gaz & Energiya — seller logins: the admin gives each company a login and
-- password, the seller signs in to the Seller web panel with them.
--
-- Run once in Supabase Dashboard → SQL Editor → New query → Run, after
-- seller_workflow_setup.sql. Safe to re-run (idempotent).
--
-- Why not Supabase Auth: the project requires email confirmation, sellers
-- have no email, and the anon key cannot set another user's password.
--
-- The table has RLS on and no policies, so the anon key cannot read it —
-- not even the bcrypt hashes. Everything goes through the security-definer
-- functions below.
--
-- SECURITY NOTE: the admin panel has no login yet, so `set_seller_login`
-- is callable with the anon key — same trust model as the open write
-- policies in seller_workflow_setup.sql. Restrict it to a real admin role
-- once the admin panel gets authentication.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.seller_credentials (
  seller_id text primary key references public.sellers(id) on delete cascade,
  login text not null unique,
  password_hash text not null,
  -- Shared by all of the seller's signed-in browsers; a new password
  -- clears it, which signs every one of them out.
  session_token uuid,
  updated_at timestamptz not null default now()
);

alter table public.seller_credentials enable row level security;
revoke all on public.seller_credentials from anon, authenticated;

-- ── admin: give or change a login ─────────────────────────────────
create or replace function public.set_seller_login(
  p_seller_id text,
  p_login text,
  p_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_login text := lower(trim(coalesce(p_login, '')));
begin
  if not exists (select 1 from public.sellers s where s.id = p_seller_id) then
    raise exception 'seller_not_found';
  end if;
  if v_login !~ '^[a-z0-9._-]{3,32}$' then
    raise exception 'login_invalid';
  end if;
  if length(coalesce(p_password, '')) < 6 then
    raise exception 'password_too_short';
  end if;
  if exists (
    select 1 from public.seller_credentials c
    where c.login = v_login and c.seller_id <> p_seller_id
  ) then
    raise exception 'login_taken';
  end if;

  insert into public.seller_credentials (seller_id, login, password_hash, session_token, updated_at)
  values (p_seller_id, v_login, crypt(p_password, gen_salt('bf')), null, now())
  on conflict (seller_id) do update
    set login = excluded.login,
        password_hash = excluded.password_hash,
        session_token = null,
        updated_at = now();
end;
$$;

-- ── admin: which sellers already have a login ─────────────────────
create or replace function public.seller_logins()
returns table (seller_id text, login text, updated_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select c.seller_id, c.login, c.updated_at from public.seller_credentials c;
$$;

-- ── seller panel: sign in ─────────────────────────────────────────
-- Empty result = wrong login or password (deliberately not told apart).
create or replace function public.seller_sign_in(p_login text, p_password text)
returns table (
  token uuid,
  seller_id text,
  company_name text,
  owner_name text,
  status text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_cred public.seller_credentials;
begin
  select * into v_cred
  from public.seller_credentials c
  where c.login = lower(trim(coalesce(p_login, '')));

  if not found or v_cred.password_hash <> crypt(coalesce(p_password, ''), v_cred.password_hash) then
    return;
  end if;

  if v_cred.session_token is null then
    update public.seller_credentials c
    set session_token = gen_random_uuid()
    where c.seller_id = v_cred.seller_id
    returning c.session_token into v_cred.session_token;
  end if;

  return query
    select v_cred.session_token, s.id, s.company_name, s.owner_name, s.status
    from public.sellers s
    where s.id = v_cred.seller_id;
end;
$$;

-- ── seller panel: restore a saved session ─────────────────────────
-- Text, not uuid, so a garbled saved token is "signed out", not an error.
create or replace function public.seller_session(p_token text)
returns table (seller_id text, company_name text, owner_name text, status text)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.company_name, s.owner_name, s.status
  from public.seller_credentials c
  join public.sellers s on s.id = c.seller_id
  where c.session_token is not null and c.session_token::text = p_token;
$$;

revoke all on function public.set_seller_login(text, text, text) from public;
revoke all on function public.seller_logins() from public;
revoke all on function public.seller_sign_in(text, text) from public;
revoke all on function public.seller_session(text) from public;
grant execute on function public.set_seller_login(text, text, text) to anon, authenticated;
grant execute on function public.seller_logins() to anon, authenticated;
grant execute on function public.seller_sign_in(text, text) to anon, authenticated;
grant execute on function public.seller_session(text) to anon, authenticated;

notify pgrst, 'reload schema';
