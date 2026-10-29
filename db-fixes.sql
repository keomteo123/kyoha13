-- =========================================================
-- DB 수정 (마지막 접속일 + 수정 기능)
-- Supabase 대시보드 → SQL Editor → 이 파일 내용을 붙여넣고 Run (한 번만, 여러 번 해도 안전)
-- =========================================================

-- 1) 마지막 접속일 ---------------------------------------------------
-- profiles에는 접속 시각을 저장할 칸이 없어서 기록이 계속 실패했고,
-- 화면에는 대신 계정 생성일이 나오고 있었습니다.
alter table public.profiles
  add column if not exists last_login_at timestamptz;

-- 로그인할 때 사이트가 부르는 함수. 기기 시계가 아니라 서버 시계(now())로 기록합니다.
create or replace function public.touch_last_login()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set last_login_at = now() where id = auth.uid();
$$;

revoke all on function public.touch_last_login() from public, anon;
grant execute on function public.touch_last_login() to authenticated;

-- 2) 수정 기능 -------------------------------------------------------
-- 공지·일정·수행평가·분실물에는 updated_at 칸이 없어서, 수정할 때 오류가 났습니다.
-- 기존 글이 전부 "(수정됨)"으로 보이지 않도록, 먼저 칸을 만들고 작성 시각으로 채운 뒤 기본값을 겁니다.
do $$
declare
  t text;
begin
  foreach t in array array['notices','schedules','assignments','lost_items'] loop
    execute format('alter table public.%I add column if not exists updated_at timestamptz', t);
    execute format('update public.%I set updated_at = created_at where updated_at is null', t);
    execute format('alter table public.%I alter column updated_at set default now()', t);
  end loop;
end $$;
