-- 딸기 습격: 모두의 기록 (몇 명이 디저트를 몇 조각 부쉈는지)
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여 넣고 Run 하면 됩니다.
-- 표는 직접 못 건드리고, 아래 두 함수로만 더하고 읽을 수 있어요.

create table if not exists public.raid_stats (
  bundle  text primary key,
  players integer not null default 0,
  pieces  bigint  not null default 0,
  plays   integer not null default 0
);
create table if not exists public.raid_clients (
  client_id text not null,
  bundle    text not null,
  first_at  timestamptz not null default now(),
  primary key (client_id, bundle)
);
alter table public.raid_stats   enable row level security;
alter table public.raid_clients enable row level security;
revoke all on public.raid_stats, public.raid_clients from anon, authenticated;

-- 한 판 기록 더하기. 게임 속 묶음 이름만 받고, 한 판에 부술 수 있는 조각 수를 넘으면 잘라냄
create or replace function public.raid_add(p_bundle text, p_client text, p_pieces integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  is_new boolean;
begin
  if p_bundle not in ('party','cakeshop','bakery','brunch','patisserie','cafe','tteok','jiggly','summer','picnic') then
    raise exception 'unknown bundle';
  end if;
  if p_client is null or length(p_client) < 8 or length(p_client) > 64 then
    raise exception 'bad client';
  end if;
  p_pieces := greatest(0, least(coalesce(p_pieces, 0), 1500));

  insert into raid_clients (client_id, bundle) values (p_client, p_bundle)
  on conflict do nothing;
  get diagnostics is_new = row_count;

  insert into raid_stats (bundle, players, pieces, plays)
  values (p_bundle, case when is_new then 1 else 0 end, p_pieces, 1)
  on conflict (bundle) do update
    set players = raid_stats.players + case when is_new then 1 else 0 end,
        pieces  = raid_stats.pieces + excluded.pieces,
        plays   = raid_stats.plays + 1;
end;
$$;

-- 묶음별 기록 + 전체 합계('*' 줄, 사람 수는 겹치지 않게 셈)
create or replace function public.raid_board()
returns table (bundle text, players bigint, pieces bigint, plays bigint)
language sql
stable
security definer
set search_path = public
as $$
  select s.bundle, s.players::bigint, s.pieces, s.plays::bigint from raid_stats s
  union all
  select '*', (select count(distinct client_id) from raid_clients),
         coalesce(sum(pieces), 0)::bigint, coalesce(sum(plays), 0)::bigint from raid_stats;
$$;

revoke all on function public.raid_add(text, text, integer) from public;
revoke all on function public.raid_board() from public;
grant execute on function public.raid_add(text, text, integer) to anon, authenticated;
grant execute on function public.raid_board() to anon, authenticated;
