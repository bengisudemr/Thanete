# Supabase Setup for Thanette

## Table schema
```sql
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  color integer,
  is_pinned boolean default false,
  drawing_data text,
  apple_drawing_data text,
  attachments text,
  created_at timestamptz not null default now()
);
```

## Add missing columns to existing table
If you already have the notes table, run these SQL commands to add the missing columns:
```sql
alter table public.notes add column if not exists color integer;
alter table public.notes add column if not exists is_pinned boolean default false;
alter table public.notes add column if not exists drawing_data text;
alter table public.notes add column if not exists apple_drawing_data text;
alter table public.notes add column if not exists attachments text;
```

## Enable Row Level Security
```sql
alter table public.notes enable row level security;
```

## Policies
Only authenticated users can interact with their own rows.
```sql
create policy "users can select own notes"
  on public.notes for select
  using (auth.uid() = user_id);

create policy "users can insert own notes"
  on public.notes for insert
  with check (auth.uid() = user_id);

create policy "users can update own notes"
  on public.notes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users can delete own notes"
  on public.notes for delete
  using (auth.uid() = user_id);
```

## Realtime
Supabase Realtime will work automatically for the `notes` table when using the client subscription in `SupabaseService.subscribeToNotes`.

## Profiles Table Setup
For user profile features (name editing, profile photo), run the SQL commands in `docs/profile_setup.sql`:
```sql
-- Run profile_setup.sql in Supabase SQL Editor
```

This creates:
- `profiles` table with `name`, `avatar_url`, etc.
- `avatars` storage bucket for profile photos
- Row Level Security policies
- Storage policies for avatar uploads

## Environment
Put these in `.env` (already referenced in `pubspec.yaml`):
```
SUPABASE_URL=https://hlwfutlmvzeelcangmuu.supabase.co
SUPABASE_ANON_KEY=REPLACE_WITH_YOUR_PUBLIC_ANON_KEY
```
