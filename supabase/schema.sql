-- Custom word packs. https://github.com/kotinarupali/mismatch-ios/issues/30
-- The anon key cannot read these tables.
-- Edge Functions use the service role, which bypasses row level security.

create extension if not exists pgcrypto;

create table if not exists public.hosts (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  user_id uuid,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.word_packs (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.hosts (id),
  prompt text not null,
  title text not null,
  request_id text,
  is_archived boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists word_packs_host_request
  on public.word_packs (host_id, request_id)
  where request_id is not null;

create table if not exists public.word_pairs (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.word_packs (id),
  host_id uuid not null references public.hosts (id),
  insider_word text not null,
  mismatch_word text not null,
  insider_canonical text not null,
  mismatch_canonical text not null,
  category text not null,
  played_at timestamptz,
  is_removed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.pending_generations (
  host_id uuid not null references public.hosts (id),
  request_id text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (host_id, request_id)
);

create table if not exists public.generation_events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.hosts (id),
  created_at timestamptz not null default now()
);

alter table public.hosts enable row level security;
alter table public.word_packs enable row level security;
alter table public.word_pairs enable row level security;
alter table public.pending_generations enable row level security;
alter table public.generation_events enable row level security;
