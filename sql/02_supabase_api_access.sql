-- Smart Retail Analytics | Supabase API access for the demo dashboard
-- Run this ONCE in Supabase Dashboard > SQL Editor, then run: python seed_supabase.py
--
-- This project currently uses its own application login and the Supabase
-- publishable key for REST reads/writes. These grants make the demo tables
-- available to the anon and authenticated API roles. Move to per-user RLS
-- policies before using this setup in production.

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;
alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated;

-- The schema intentionally leaves RLS disabled until Supabase Auth policies
-- are configured. Enforce that demo choice for these dashboard-owned tables.
alter table public.branches disable row level security;
alter table public.products disable row level security;
alter table public.customers disable row level security;
alter table public.transactions disable row level security;
alter table public.inventory disable row level security;
alter table public.sales_targets disable row level security;
