// 서비스 워커: 사이트가 꺼져 있어도 서버가 보낸 푸시를 받아 알림으로 보여줍니다.

self.addEventListener("install",()=>self.skipWaiting());
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));

self.addEventListener("push",event=>{
  let data={};
  try{ data=event.data ? event.data.json() : {}; }
  catch(e){ data={body:event.data ? event.data.text() : ""}; }

  event.waitUntil(self.registration.showNotification(data.title || "3반 알림",{
    body:data.body || "",
    icon:"icon-192.png",
    badge:"icon-192.png",
    tag:data.tag,
    data:{url:data.url || "./"}
  }));
});

// 알림을 누르면 열려 있는 탭으로 가고, 없으면 새로 엽니다
self.addEventListener("notificationclick",event=>{
  event.notification.close();
  const target=new URL(event.notification.data?.url || "./",self.registration.scope).href;

  event.waitUntil(
    self.clients.matchAll({type:"window",includeUncontrolled:true}).then(windows=>{
      for(const client of windows){
        if("focus" in client) return client.focus();
      }
      return self.clients.openWindow(target);
    })
  );
});
