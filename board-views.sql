-- =========================================================
-- 게시판 조회수 설정
-- Supabase 대시보드 → SQL Editor → 이 파일 내용을 붙여넣고 Run (한 번만)
-- 한 사람이 같은 글을 여러 번 열어도 조회수는 1번만 올라갑니다.
-- =========================================================

-- 1) 글마다 조회수 칸 추가
alter table public.opinions
  add column if not exists view_count integer not null default 0;

-- 2) 누가 어떤 글을 읽었는지 기록 (중복 집계 방지용)
create table if not exists public.opinion_views (
  post_id   bigint      not null references public.opinions(id) on delete cascade,
  user_id   uuid        not null references auth.users(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

-- 학생들이 이 표를 직접 읽거나 고치지 못하게 막고, 아래 함수로만 기록합니다.
alter table public.opinion_views enable row level security;

-- 3) 글을 열 때 사이트가 부르는 함수
--    security definer: 다른 사람 글의 조회수도 올릴 수 있도록 함수 안에서만 권한을 빌려 씀
create or replace function public.increment_opinion_view(p_post_id bigint)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  if auth.uid() is null then
    return null;
  end if;

  insert into public.opinion_views (post_id, user_id)
  values (p_post_id, auth.uid())
  on conflict do nothing;

  if found then
    update public.opinions
       set view_count = view_count + 1
     where id = p_post_id
    returning view_count into new_count;
  else
    select view_count into new_count from public.opinions where id = p_post_id;
  end if;

  return new_count;
end;
$$;

revoke all on function public.increment_opinion_view(bigint) from public, anon;
grant execute on function public.increment_opinion_view(bigint) to authenticated;
