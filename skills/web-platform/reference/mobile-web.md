## Contents

- [Mobile-first CSS](#mobile-first-css)
- [Touch targets](#touch-targets)
- [Viewport and zoom](#viewport-and-zoom)
- [Touch interactions](#touch-interactions)
- [Base font size](#base-font-size)
- [Progressive Web Apps](#progressive-web-apps)

## Mobile-first CSS

Write styles for the smallest screen first, then add complexity for larger screens:

```css
.container {
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

@media (width >= 768px) {
    .container { padding: 2rem; flex-direction: row; }
}

@media (width >= 1200px) {
    .container { max-width: 1200px; margin-inline: auto; padding: 2.5rem; }
}
```

Google indexes the mobile version of a site first (mobile-first indexing). The mobile experience is the SEO experience.

## Touch targets

Minimum 44×44px (Apple HIG) or 48×48px (Material Design). WCAG 2.2 sets 24×24px as the legal minimum, but that's too small in practice. Use padding to extend the clickable area without affecting visual size:

```css
.icon-button {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 44px;
    min-height: 44px;
    padding: 12px;
}

.nav-list {
    display: flex;
    gap: 4px;   /* 4px minimum between 44px targets = 48px center-to-center */
}
```

## Viewport and zoom

```html
<!-- Correct: allows user zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<!-- Wrong: WCAG 1.4.4 violation -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1" />
```

## Touch interactions

```css
button, .interactive {
    -webkit-user-select: none;
    user-select: none;
}

p, h1, h2, article {
    user-select: text;
}

/* Eliminates the ~300ms tap delay on iOS */
button, a {
    touch-action: manipulation;
}

.scroll-container {
    overflow-y: auto;
    overscroll-behavior: contain;   /* prevents scroll chaining */
    -webkit-overflow-scrolling: touch;
}
```

```javascript
// Pointer Events API unifies mouse, touch, and stylus
element.addEventListener("pointerdown", handleStart);
element.addEventListener("pointermove", handleMove);
element.addEventListener("pointerup", handleEnd);
element.addEventListener("pointercancel", handleCancel);
```

## Base font size

Never set `html { font-size: < 16px }`. 16px is the browser default; going smaller ignores user preferences and causes WCAG 1.4.4 failures. Use `rem` for everything.

```css
/* Correct */
html { font-size: 100%; }    /* 16px, respects user browser settings */
body { font-size: 1rem; }

/* Wrong */
html { font-size: 14px; }
html { font-size: 62.5%; }   /* the "1rem = 10px" hack -- overrides user preference */
```

## Progressive Web Apps

PWA adds app-like behaviors without an app store:

```json
// manifest.webmanifest
{
    "name": "App Name",
    "short_name": "App",
    "description": "Short description",
    "start_url": "/",
    "display": "standalone",
    "background_color": "#1a1a1a",
    "theme_color": "#1a1a1a",
    "orientation": "portrait-primary",
    "icons": [
        { "src": "/icons/192.png", "sizes": "192x192", "type": "image/png" },
        { "src": "/icons/512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
    ],
    "shortcuts": [
        { "name": "New Post", "url": "/new", "icons": [{ "src": "/icons/add.png", "sizes": "96x96" }] }
    ]
}
```

```javascript
// Service Worker: cache-first for assets, network-first for API
self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open("app-v1").then(cache =>
            cache.addAll(["/", "/styles.css", "/app.js", "/offline.html"])
        )
    );
});

self.addEventListener("fetch", (event) => {
    if (event.request.mode === "navigate") {
        event.respondWith(
            fetch(event.request).catch(() => caches.match("/offline.html"))
        );
        return;
    }
    event.respondWith(
        caches.match(event.request).then(cached => cached ?? fetch(event.request))
    );
});
```
