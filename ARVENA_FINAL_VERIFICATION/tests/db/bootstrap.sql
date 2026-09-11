\set ON_ERROR_STOP on
-- Supabase compatibility shims for a disposable PostgreSQL database.
create schema if not exists auth;
create table if not exists auth.users(
  id uuid primary key,
  email text unique,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid
$$;
