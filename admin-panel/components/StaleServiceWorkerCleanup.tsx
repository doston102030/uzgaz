"use client";

import { useEffect } from "react";

/**
 * The panel has no service worker. If another app that once ran on this
 * origin (e.g. localhost:3000) left one behind, it keeps answering the home
 * page from its own cache — so the first time the real panel loads, remove
 * any such worker and its caches.
 */
export function StaleServiceWorkerCleanup() {
  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;
    navigator.serviceWorker
      .getRegistrations()
      .then(async (registrations) => {
        if (registrations.length === 0) return;
        await Promise.all(registrations.map((registration) => registration.unregister()));
        if ("caches" in window) {
          const keys = await caches.keys();
          await Promise.all(keys.map((key) => caches.delete(key)));
        }
      })
      .catch(() => {});
  }, []);

  return null;
}
