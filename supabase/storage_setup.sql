-- Gaz & Energiya — Storage setup for image uploads (product photos,
-- profile avatars, company logos).
--
-- Run this once in Supabase Dashboard → SQL Editor → New query → Run.
-- Safe to re-run: bucket inserts are idempotent and policies are dropped
-- before being recreated.

-- 1) Buckets — public read (so images show up in the app for anyone),
--    5 MB cap, images only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('avatars',        'avatars',        true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('company-logos',  'company-logos',  true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2) Policies on storage.objects.
--
-- Demo phase note: the app doesn't sign users into Supabase Auth yet (it
-- still uses local mock accounts — see the "Faqat ulanish" scope agreed
-- earlier), so these policies allow uploads from anyone holding the
-- publishable/anon key, same as the buckets' public read. Once real
-- Supabase Auth is wired, replace "true" in the upload/update/delete
-- policies below with an owner check, e.g.
--   (storage.foldername(name))[1] = auth.uid()::text
-- so users can only write inside their own folder.

drop policy if exists "public read product-images" on storage.objects;
drop policy if exists "public write product-images" on storage.objects;
drop policy if exists "public read avatars" on storage.objects;
drop policy if exists "public write avatars" on storage.objects;
drop policy if exists "public read company-logos" on storage.objects;
drop policy if exists "public write company-logos" on storage.objects;

create policy "public read product-images" on storage.objects
  for select using (bucket_id = 'product-images');
create policy "public write product-images" on storage.objects
  for all using (bucket_id = 'product-images') with check (bucket_id = 'product-images');

create policy "public read avatars" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "public write avatars" on storage.objects
  for all using (bucket_id = 'avatars') with check (bucket_id = 'avatars');

create policy "public read company-logos" on storage.objects
  for select using (bucket_id = 'company-logos');
create policy "public write company-logos" on storage.objects
  for all using (bucket_id = 'company-logos') with check (bucket_id = 'company-logos');
