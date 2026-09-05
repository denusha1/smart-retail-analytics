-- Smart Retail Analytics | Supabase PostgreSQL schema
-- Run this entire file in: Supabase Dashboard > SQL Editor

create extension if not exists pgcrypto;

-- Automatically maintain updated_at timestamps.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.branches (
  branch_id text primary key,
  branch_name text not null,
  region text not null,
  city text not null,
  manager_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.products (
  product_id uuid primary key default gen_random_uuid(),
  sku text unique,
  product_name text not null unique,
  category text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  profit_margin_percent numeric(5,2) not null default 30 check (profit_margin_percent between 0 and 100),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.customers (
  customer_id uuid primary key default gen_random_uuid(),
  customer_code text unique,
  customer_type text not null check (customer_type in ('Online', 'Offline')),
  customer_segment text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.transactions (
  transaction_id bigint generated always as identity primary key,
  transaction_date date not null,
  branch_id text not null references public.branches(branch_id),
  product_id uuid references public.products(product_id),
  customer_id uuid references public.customers(customer_id),
  product_name text not null,
  category text not null,
  customer_type text not null check (customer_type in ('Online', 'Offline')),
  customer_segment text,
  quantity_sold integer not null check (quantity_sold > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  total_sales numeric(14,2) not null check (total_sales >= 0),
  discount_percent numeric(5,2) not null default 0 check (discount_percent between 0 and 100),
  revenue numeric(14,2) not null check (revenue >= 0),
  profit_margin_percent numeric(5,2) not null default 30 check (profit_margin_percent between 0 and 100),
  estimated_profit numeric(14,2) not null,
  profit_margin numeric(5,2),
  sales_performance text default 'Standard',
  year integer not null,
  month integer not null,
  day_of_week text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.inventory (
  inventory_id uuid primary key default gen_random_uuid(),
  branch_id text not null references public.branches(branch_id),
  product_id uuid references public.products(product_id),
  product_name text not null,
  category text not null,
  units_on_hand integer not null default 0 check (units_on_hand >= 0),
  reorder_point integer not null default 10 check (reorder_point >= 0),
  reorder_quantity integer not null default 20 check (reorder_quantity > 0),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (branch_id, product_name)
);

create table if not exists public.sales_targets (
  target_id uuid primary key default gen_random_uuid(),
  branch_id text not null references public.branches(branch_id),
  target_period date not null,
  target_revenue numeric(14,2) not null check (target_revenue >= 0),
  target_profit numeric(14,2),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (branch_id, target_period)
);

-- Query-performance indexes for dashboard filters and real-time analytics.
create index if not exists idx_transactions_date on public.transactions(transaction_date desc);
create index if not exists idx_transactions_branch_date on public.transactions(branch_id, transaction_date desc);
create index if not exists idx_transactions_category on public.transactions(category);
create index if not exists idx_transactions_customer_type on public.transactions(customer_type);
create index if not exists idx_inventory_low_stock on public.inventory(branch_id, units_on_hand, reorder_point);
create index if not exists idx_sales_targets_period on public.sales_targets(target_period, branch_id);

-- `to_char` is not immutable in PostgreSQL, so temporal dimensions are populated by a trigger.
create or replace function public.set_transaction_dimensions()
returns trigger language plpgsql as $$
begin
  new.year = extract(year from new.transaction_date)::integer;
  new.month = extract(month from new.transaction_date)::integer;
  new.day_of_week = trim(to_char(new.transaction_date, 'Day'));
  return new;
end;
$$;

drop trigger if exists branches_updated_at on public.branches;
create trigger branches_updated_at before update on public.branches for each row execute function public.set_updated_at();
drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at before update on public.products for each row execute function public.set_updated_at();
drop trigger if exists customers_updated_at on public.customers;
create trigger customers_updated_at before update on public.customers for each row execute function public.set_updated_at();
drop trigger if exists inventory_updated_at on public.inventory;
create trigger inventory_updated_at before update on public.inventory for each row execute function public.set_updated_at();
drop trigger if exists sales_targets_updated_at on public.sales_targets;
create trigger sales_targets_updated_at before update on public.sales_targets for each row execute function public.set_updated_at();
drop trigger if exists transactions_dimensions on public.transactions;
create trigger transactions_dimensions before insert or update of transaction_date on public.transactions for each row execute function public.set_transaction_dimensions();

-- Sri Lankan retail branch seed data.
insert into public.branches (branch_id, branch_name, region, city) values
  ('S001', 'RetailPulse Colombo', 'Western', 'Colombo'),
  ('S002', 'RetailPulse Kandy', 'Central', 'Kandy'),
  ('S003', 'RetailPulse Galle', 'Southern', 'Galle'),
  ('S004', 'RetailPulse Jaffna', 'Northern', 'Jaffna')
on conflict (branch_id) do update set
  branch_name = excluded.branch_name,
  region = excluded.region,
  city = excluded.city;

-- Optional RLS starter: enable this only after configuring Supabase Auth policies.
-- alter table public.branches enable row level security;
-- alter table public.products enable row level security;
-- alter table public.customers enable row level security;
-- alter table public.transactions enable row level security;
-- alter table public.inventory enable row level security;
-- alter table public.sales_targets enable row level security;

-- For dashboard REST API grants in this demo, also run:
-- sql/02_supabase_api_access.sql
