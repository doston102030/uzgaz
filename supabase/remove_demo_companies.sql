-- Run in Supabase SQL Editor as the project owner.
-- The public client cannot delete companies under the existing RLS policy.
-- Demo sellers and their 13 products were already removed after a local backup.
-- Match both ID and name so a replacement company is never removed by accident.
begin;

delete from public.companies c
using (values
  ('c1', 'Andijon Gaz Markazi'),
  ('c2', 'Asaka Energiya Servis'),
  ('c3', 'Shahrixon Gaz Ta''minot'),
  ('c4', 'Xo''jaobod Metan Servis'),
  ('c5', 'Marhamat Sanoat Gaz'),
  ('c6', 'Andijon GazPlus')
) as demo(id, name)
where c.id = demo.id and c.name = demo.name
  and not exists (select 1 from public.products p where p.company_id = c.id)
  and not exists (select 1 from public.sellers s where s.id = c.id)
returning c.id, c.name;

commit;
