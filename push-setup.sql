-- =========================================================
-- 백그라운드 푸시 알림: 기기 등록 정보를 저장하는 표
-- Supabase 대시보드 → SQL Editor → 붙여넣고 Run (여러 번 해도 안전)
-- 전체 설정 순서는 push-setup.md 를 보세요.
-- =========================================================

create table if not exists public.push_subscriptions (
  endpoint   text        primary key,
  user_id    uuid        not null references auth.users(id) on delete cascade,
  p256dh     text        not null,
  auth       text        not null,
  created_at timestamptz not null default now()
);

alter table public.push_subscriptions enable row level security;

-- 학생은 자기 기기 정보만 보고, 등록하고, 지울 수 있습니다.
-- (알림을 보내는 서버 함수는 service role 키를 쓰므로 이 정책의 영향을 받지 않습니다.)
drop policy if exists "push_select_own" on public.push_subscriptions;
drop policy if exists "push_insert_own" on public.push_subscriptions;
drop policy if exists "push_update_own" on public.push_subscriptions;
drop policy if exists "push_delete_own" on public.push_subscriptions;

create policy "push_select_own" on public.push_subscriptions
  for select to authenticated using (user_id = auth.uid());
create policy "push_insert_own" on public.push_subscriptions
  for insert to authenticated with check (user_id = auth.uid());
create policy "push_update_own" on public.push_subscriptions
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "push_delete_own" on public.push_subscriptions
  for delete to authenticated using (user_id = auth.uid());
