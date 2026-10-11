// Bu panel service worker ishlatmaydi. Shu manzilda (localhost:3000) avval
// boshqa ilova ishlagan bo'lsa, uning /sw.js'i brauzerda qolib, bosh sahifani
// o'z keshidan berishda davom etadi. Brauzer yangilanishni tekshirganda shu
// faylni oladi: keshlarni o'chiradi, o'zini ro'yxatdan chiqaradi va ochiq
// oynalarni qayta yuklaydi — shundan keyin panel to'g'ridan-to'g'ri serverdan
// ochiladi.
self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      await self.clients.claim();
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
      await self.registration.unregister();
      const windows = await self.clients.matchAll({ type: "window" });
      for (const client of windows) client.navigate(client.url);
    })(),
  );
});
