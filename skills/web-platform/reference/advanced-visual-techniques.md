The techniques in this section are what separate hand-crafted visual experiences from generic component-library output. Use them deliberately — each one has a specific use case and a wrong application.

## Contents

- [CSS blend modes and compositing](#css-blend-modes-and-compositing)
- [clip-path](#clip-path)
- [CSS filters](#css-filters)
- [Custom cursor](#custom-cursor)
- [SVG animation and manipulation](#svg-animation-and-manipulation)
- [Canvas 2D](#canvas-2d)

## CSS blend modes and compositing

Blend modes run on the compositor thread. Zero JavaScript.

```css
/* mix-blend-mode: how an element blends with what's behind it */
.text-overlay {
  mix-blend-mode: overlay;       /* contrast boost, good on images */
  mix-blend-mode: multiply;      /* darken, like printing ink */
  mix-blend-mode: screen;        /* lighten, good for glow/light leaks */
  mix-blend-mode: difference;    /* inversion, Y2K / glitch aesthetic */
  mix-blend-mode: hard-light;    /* strong contrast, Neo-Brutalism */
  mix-blend-mode: soft-light;    /* subtle contrast, Neo-Minimalism */
  mix-blend-mode: color-dodge;   /* blown-out highlights, Futuristic */
  mix-blend-mode: luminosity;    /* preserve luminance, discard color */
}

/* isolation: prevent blending from propagating outside a group */
.blend-group {
  isolation: isolate; /* children blend within this context only */
}

/* background-blend-mode: blend an element's own background layers */
.texture-overlay {
  background-image: url('noise.svg'), linear-gradient(135deg, #667eea, #764ba2);
  background-blend-mode: overlay;
}
```

Practical patterns:

```css
/* Glow text effect without box-shadow (Futuristic) */
.glow-text {
  color: #00f5d4;
  mix-blend-mode: screen;
  text-shadow: 0 0 20px currentColor;
}

/* Color-matched grain over gradients (Neo-Minimalism, Texture) */
.grainy-surface {
  background: linear-gradient(135deg, #faf9f7, #f0ede8);
  position: relative;
}
.grainy-surface::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
  opacity: 0.04;
  mix-blend-mode: multiply;
  pointer-events: none;
}
```

## clip-path

Clips elements to arbitrary shapes. Animatable via CSS or GSAP.

```css
.diagonal-cut    { clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%); }
.v-notch         { clip-path: polygon(0 0, 100% 0, 100% 100%, 50% 85%, 0 100%); }
.chevron         { clip-path: polygon(10% 0%, 90% 0%, 100% 50%, 90% 100%, 10% 100%, 0% 50%); }
.angled-card     { clip-path: polygon(0 0, 100% 0, 100% 90%, 95% 100%, 0 100%); }

.circle-reveal   { clip-path: circle(0% at 50% 50%); }
.circle-revealed { clip-path: circle(100% at 50% 50%); }

.inset-clip { clip-path: inset(10px 20px 30px 40px round 16px); }
```

The `shape()` function offers a more readable alternative to `path()` for custom curves in `clip-path`/`offset-path`, using move/line/curve commands with direct CSS units — check current browser support before relying on it as a universal replacement.

Animated reveal with GSAP:

```javascript
gsap.fromTo(element,
  { clipPath: 'polygon(0 0, 0 0, 0 100%, 0 100%)' },
  { clipPath: 'polygon(0 0, 100% 0, 100% 100%, 0 100%)',
    duration: 0.8, ease: 'power3.inOut' }
);

gsap.fromTo(element,
  { clipPath: 'polygon(0 0, 0 0, 0 100%, 0 100%)' },
  { clipPath: 'polygon(0 0, 110% 0, 100% 100%, 0 100%)',
    duration: 0.9, ease: 'expo.inOut' }
);
```

## CSS filters

Hardware-accelerated visual effects. Compositing layer per filtered element.

```css
.frosted    { backdrop-filter: blur(16px) saturate(1.5); }
.desaturate { filter: grayscale(1); }
.warm       { filter: sepia(0.2) saturate(1.1); }
.glow       { filter: drop-shadow(0 0 12px rgba(0, 245, 212, 0.8)); }
.glitch     { filter: hue-rotate(180deg) saturate(3); }

/* Duotone effect */
.duotone { filter: grayscale(1) contrast(1.2); }
.duotone-container {
  background: linear-gradient(to bottom, #ff6b35, #1a1a2e);
  mix-blend-mode: multiply; /* or screen for inverted duotone */
}

/* CRT phosphor glow (Y2K) */
.crt-screen {
  filter: contrast(1.1) brightness(0.95) blur(0.3px);
}
```

## Custom cursor

Signature touch for premium products. Especially effective in Futuristic, Neo-Brutalism, and Kinetic Typography styles.

```javascript
const cursor = document.querySelector('.cursor');
const follower = document.querySelector('.cursor-follower');

document.addEventListener('mousemove', (e) => {
  gsap.set(cursor, { x: e.clientX, y: e.clientY });
  gsap.to(follower, { x: e.clientX, y: e.clientY, duration: 0.15, ease: 'power2.out' });
});

document.querySelectorAll('a, button, [data-cursor-expand]').forEach(el => {
  el.addEventListener('mouseenter', () => {
    gsap.to(follower, { scale: 3, duration: 0.3, ease: 'power2.out' });
  });
  el.addEventListener('mouseleave', () => {
    gsap.to(follower, { scale: 1, duration: 0.3, ease: 'power2.out' });
  });
});
```

```css
body { cursor: none; }

.cursor {
  position: fixed;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent);
  pointer-events: none;
  transform: translate(-50%, -50%);
  z-index: 9999;
  mix-blend-mode: difference; /* inverts against background -- signature look */
}

.cursor-follower {
  position: fixed;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 1px solid var(--accent);
  pointer-events: none;
  transform: translate(-50%, -50%);
  z-index: 9998;
}
```

Always provide a fallback: `@media (pointer: coarse) { body { cursor: auto; } }` on touch devices.

## SVG animation and manipulation

SVGs are DOM elements. They respond to CSS and JavaScript like any other element.

```css
.path-draw {
  stroke-dasharray: 1000;
  stroke-dashoffset: 1000;
  animation: draw 2s ease forwards;
}

@keyframes draw {
  to { stroke-dashoffset: 0; }
}
```

```javascript
const path = document.querySelector('path');
const length = path.getTotalLength();
path.style.strokeDasharray = length;
path.style.strokeDashoffset = length;

// GSAP scroll-driven stroke animation
gsap.to(path, {
  strokeDashoffset: 0,
  ease: 'none',
  scrollTrigger: { trigger: path, start: 'top 80%', end: 'bottom 20%', scrub: true }
});

// Morphing between two SVG paths with GSAP MorphSVG plugin (requires GSAP Club membership)
gsap.to('#path1', { morphSVG: '#path2', duration: 1, ease: 'power2.inOut' });
```

Native CSS scroll-driven animations (see `css.md`) can replace the ScrollTrigger scrub pattern above for simple linear cases without a GSAP dependency.

Inline SVG filters for effects not achievable with CSS alone:

```html
<svg width="0" height="0" style="position:absolute">
  <defs>
    <!-- Blob / gooey merging effect -->
    <filter id="goo">
      <feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur"/>
      <feColorMatrix in="blur" mode="matrix"
        values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 19 -9"
        result="goo"/>
    </filter>

    <!-- Liquid distortion -->
    <filter id="liquid">
      <feTurbulence type="turbulence" baseFrequency="0.015" numOctaves="4"
        seed="2" stitchTiles="stitch" result="turbulence"/>
      <feDisplacementMap in="SourceGraphic" in2="turbulence" scale="30"
        xChannelSelector="R" yChannelSelector="G"/>
    </filter>
  </defs>
</svg>

<style>
  .blob-container { filter: url(#goo); }
  .liquid-image:hover { filter: url(#liquid); transition: filter 0.5s; }
</style>
```

## Canvas 2D

Use for procedural drawing: generative art, custom charts, pixel manipulation, particle systems that don't need WebGL.

```javascript
const canvas = document.querySelector('canvas');
const ctx = canvas.getContext('2d');

// Always set canvas size via JS, not CSS, to match device pixel ratio
function setCanvasSize() {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.scale(dpr, dpr);
}

// Noise-based generative background (Organic/Biomorphic)
function drawNoisyBlob(time) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const cx = canvas.width / 2;
  const cy = canvas.height / 2;
  const points = 8;
  const baseRadius = 120;

  ctx.beginPath();
  for (let i = 0; i <= points; i++) {
    const angle = (i / points) * Math.PI * 2;
    const noise = Math.sin(angle * 3 + time * 0.5) * 20 +
                  Math.cos(angle * 5 + time * 0.3) * 15;
    const r = baseRadius + noise;
    const x = cx + Math.cos(angle) * r;
    const y = cy + Math.sin(angle) * r;
    i === 0 ? ctx.moveTo(x, y) : ctx.bezierCurveTo(/* ... */);
  }
  ctx.closePath();

  const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, baseRadius + 40);
  grad.addColorStop(0, 'rgba(120, 190, 150, 0.8)');
  grad.addColorStop(1, 'rgba(80, 140, 120, 0.2)');
  ctx.fillStyle = grad;
  ctx.fill();
}

let animFrame;
function animate(time) {
  drawNoisyBlob(time * 0.001);
  animFrame = requestAnimationFrame(animate);
}

// Always cancel on cleanup
return () => cancelAnimationFrame(animFrame);
```
