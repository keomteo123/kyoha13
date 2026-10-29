# 백그라운드 알림 설정 (사이트를 꺼도 오는 알림)

사이트가 꺼져 있을 때 알림을 보내려면 **서버가 대신 보내야** 해서, 아래 설정이 필요합니다.
설정하지 않으면 예전처럼 "사이트를 열어둔 동안만" 알림이 옵니다. (사이트는 정상 동작)

매일 **아침 7시 30분**에 D-3 이내 수행평가·시험이 있으면 등록한 기기로 알림이 갑니다.

## 0. 먼저 확인할 것

- 사이트가 **https 주소**로 올라가 있어야 합니다. (GitHub Pages, Netlify, Vercel 등) `index.html`을 파일로 직접 열면 안 됩니다.
- 아이폰은 **사파리에서 [공유] → [홈 화면에 추가]** 로 설치한 앱에서만 알림이 옵니다. (iOS 16.4 이상)

## 1. 열쇠 만들기 (VAPID)

```
npx web-push generate-vapid-keys
```

나온 **Public Key**를 [index.html](index.html)의 `VAPID_PUBLIC_KEY=""` 따옴표 안에 넣습니다.
**Private Key**는 어디에도 붙여넣지 말고 아래 5번에서만 쓰세요. (사이트 파일에 넣으면 누구나 알림을 보낼 수 있어요)

## 2. 표 만들기

Supabase 대시보드 → SQL Editor에서 [push-setup.sql](push-setup.sql) 내용을 Run.

## 3. 같이 올라갈 파일

`sw.js`, `manifest.webmanifest`, `logo.svg`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`를 `index.html`과 **같은 폴더**에 올려주세요.

## 4. 함수 올리기

[Supabase CLI](https://supabase.com/docs/guides/cli)를 설치하고 로그인한 뒤, 이 프로젝트 폴더에서:

```
supabase link --project-ref jllqnaoprtrcjfnzywdd
supabase functions deploy send-exam-push --no-verify-jwt
```

## 5. 비밀 값 등록

`CRON_SECRET`은 아무 긴 문자열이면 됩니다. (예약 작업만 아는 암호)

```
supabase secrets set VAPID_PUBLIC_KEY=<1번 Public Key> VAPID_PRIVATE_KEY=<1번 Private Key> VAPID_SUBJECT=mailto:본인이메일@example.com CRON_SECRET=<아무_긴_문자열>
```

## 6. 매일 아침 자동 실행

Supabase 대시보드 → Database → Extensions에서 `pg_cron`과 `pg_net`을 켠 뒤, SQL Editor에서 (`여기에_CRON_SECRET`을 5번과 같은 값으로 바꿔서):

```sql
select cron.schedule(
  'exam-push-daily',
  '30 22 * * *',   -- UTC 22:30 = 한국 시간 07:30
  $$
  select net.http_post(
    url := 'https://jllqnaoprtrcjfnzywdd.supabase.co/functions/v1/send-exam-push',
    headers := jsonb_build_object('Content-Type','application/json','x-cron-secret','여기에_CRON_SECRET'),
    body := '{}'::jsonb
  );
  $$
);
```

## 7. 시험해보기

1. 사이트 → 계정 → **알림 켜기** (허용 누르기)
2. 바로 보내보기 (터미널에서):
   ```
   curl -X POST https://jllqnaoprtrcjfnzywdd.supabase.co/functions/v1/send-exam-push -H "x-cron-secret: <CRON_SECRET>"
   ```
   `{"sent":1,...}` 이 나오고 알림이 뜨면 성공입니다. (D-3 이내 수행평가가 하나도 없으면 `"sent":0`이 나와요)
3. 사이트를 닫은 채로 한 번 더 보내서, 닫혀 있어도 뜨는지 확인하세요.

## 문제가 생기면

- 알림 켜기를 눌러도 "서비스 워커가 준비되지 않았어요" → https 주소가 아니거나 `sw.js`가 `index.html`과 같은 폴더에 없습니다.
- `{"error":"unauthorized"}` → `x-cron-secret` 값이 5번과 다릅니다.
- 시간을 바꾸려면 6번의 `'30 22 * * *'`을 바꾸세요. (분 시 일 월 요일, UTC 기준)
