-- =========================================================
-- 프로필 메시지 삭제 권한
-- Supabase 대시보드 → SQL Editor → 붙여넣고 Run (여러 번 해도 안전)
-- 삭제 가능: 메시지를 쓴 본인 / 관리자(admin)
-- =========================================================

drop policy if exists "profile_messages_delete" on public.profile_messages;

create policy "profile_messages_delete" on public.profile_messages
  for delete to authenticated
  using (
    author_id = auth.uid()
    or exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
