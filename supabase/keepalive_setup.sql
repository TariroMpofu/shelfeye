-- KeepAlive table for the GitHub Action (.github/workflows/keepalive.yml).
-- Free Supabase projects pause after 7 days idle; the Action PATCHes row id=1
-- every 5 days to keep the project awake.

create table if not exists public.keepalive (
  id        integer primary key,
  last_ping timestamptz not null default now()
);

-- Single fixed row the Action updates.
insert into public.keepalive (id, last_ping)
values (1, now())
on conflict (id) do nothing;

-- RLS on, with a narrow policy: anon may only UPDATE the existing row.
-- NOTE: the policy alone is not enough — the anon role also needs the
-- table-level GRANT, or PostgREST updates 0 rows and the Action logs "[]".
alter table public.keepalive enable row level security;

grant update, select on public.keepalive to anon;

drop policy if exists keepalive_anon_update on public.keepalive;
create policy keepalive_anon_update
  on public.keepalive
  for update
  to anon
  using (id = 1)
  with check (id = 1);

drop policy if exists keepalive_anon_select on public.keepalive;
create policy keepalive_anon_select
  on public.keepalive
  for select
  to anon
  using (id = 1);
