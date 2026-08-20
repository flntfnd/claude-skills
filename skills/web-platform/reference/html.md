## Contents

- [Document structure](#document-structure)
- [Semantic elements](#semantic-elements)
- [Images](#images)
- [Forms](#forms)
- [Dialog and popover](#dialog-and-popover)

## Document structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Page description under 160 chars" />
    <title>Page Title | Site Name</title>
    <link rel="canonical" href="https://example.com/page" />

    <!-- Preconnect for critical third-party origins -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />

    <!-- Preload LCP image -->
    <link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />

    <!-- Critical CSS inlined, deferred CSS loaded async -->
    <style>/* critical styles */</style>
    <link rel="stylesheet" href="/styles.css" />
</head>
<body>
    <header>
        <nav aria-label="Main navigation">
            <a href="/" aria-current="page">Home</a>
        </nav>
    </header>
    <main id="main-content">
        <h1>Page Heading</h1>
    </main>
    <footer>
        <!-- footer content -->
    </footer>
</body>
</html>
```

Never omit `lang` on `<html>`. Never remove the viewport meta tag. Never set `user-scalable=no` or `maximum-scale=1` — this blocks zoom for users with low vision and is a WCAG 1.4.4 violation.

## Semantic elements

Use semantic elements. The browser accessibility tree is built from them.

```html
<!-- Document structure -->
<header>     Site header, navigation
<nav>        Navigation landmarks (multiple allowed with aria-label)
<main>       Primary content (one per page)
<article>    Self-contained content (blog post, product card)
<section>    Thematic grouping with a heading
<aside>      Tangentially related content, sidebars
<footer>     Footer content

<!-- Content -->
<h1>–<h6>   Heading hierarchy (don't skip levels)
<p>          Paragraphs
<ul> <ol>    Lists
<figure> <figcaption>  Media with captions
<time datetime="2026-04-13">April 13, 2026</time>
<address>    Contact info for nearest <article> or <body>
<mark>       Highlighted text
<details> <summary>    Disclosure widget

<!-- Interactive -->
<button>     Clickable actions (not links)
<a href="…"> Navigation and external links
<form>       Form containers
<label>      Form labels (always associated with inputs)
<input> <textarea> <select>  Form controls
<dialog>     Modal dialogs
```

Never use `<div>` or `<span>` for interactive elements. Never use `<div onclick>`. If it needs to be clickable, use `<button>`. If it navigates somewhere, use `<a>`.

The Astro 7 and other Rust-based compilers/parsers in current toolchains reject unclosed non-void tags and don't auto-correct invalid nesting the way older parsers did. Write fully-closed, well-nested markup — don't rely on the browser's error-correction behavior as a spec.

## Images

```html
<!-- Always set width and height to prevent CLS -->
<img
    src="/image.webp"
    alt="Descriptive alternative text"
    width="800"
    height="400"
    loading="lazy"
/>

<!-- LCP image: no lazy loading, high fetch priority -->
<img
    src="/hero.webp"
    alt="Hero description"
    width="1200"
    height="600"
    fetchpriority="high"
/>

<!-- Responsive images -->
<img
    srcset="/image-400.webp 400w, /image-800.webp 800w, /image-1200.webp 1200w"
    sizes="(max-width: 600px) 100vw, (max-width: 900px) 50vw, 800px"
    src="/image-800.webp"
    alt="Description"
    width="800"
    height="400"
    loading="lazy"
/>

<!-- Decorative image (empty alt, no role) -->
<img src="/decoration.svg" alt="" />
```

Use WebP or AVIF. AVIF has better compression but slower encoding. WebP is safe for all browsers. Never serve JPEG/PNG for UI images unless the image is a photo where quality is paramount.

## Forms

```html
<form method="post" action="/submit" novalidate>
    <!-- novalidate when using custom validation -->

    <div class="field">
        <label for="email">
            Email address
            <span aria-hidden="true">*</span>
        </label>
        <input
            type="email"
            id="email"
            name="email"
            autocomplete="email"
            required
            aria-required="true"
            aria-describedby="email-error"
        />
        <span id="email-error" role="alert" aria-live="polite">
            <!-- Error message inserted here by JS -->
        </span>
    </div>

    <button type="submit">Submit</button>
</form>
```

Every input needs a `<label>`. Never use placeholder text as a label substitute — it disappears when the user types and screen readers don't consistently announce it. `autocomplete` attributes speed up mobile form fill significantly. Always validate server-side. Client-side validation is UX, not security.

## Dialog and popover

`<dialog>` and the `popover` attribute cover most overlay UI (modals, tooltips, menus, toasts) without a JS library. Baseline widely available as of 2026.

```html
<!-- Native modal: focus trap, Escape-to-close, backdrop, all built in -->
<dialog id="confirm-dialog">
    <form method="dialog">
        <p>Delete this item?</p>
        <button value="cancel">Cancel</button>
        <button value="confirm">Delete</button>
    </form>
</dialog>
```

```javascript
document.getElementById("confirm-dialog").showModal(); // modal, traps focus
document.getElementById("confirm-dialog").show();      // non-modal
```

```html
<!-- popover: lightweight overlay with light-dismiss, no focus trap -->
<button popovertarget="menu">Open menu</button>
<div id="menu" popover>
    <a href="/settings">Settings</a>
    <a href="/logout">Log out</a>
</div>
```

Combine `popover` with CSS anchor positioning (see `css.md`) to tether the popover to its trigger with zero JavaScript — this is the current recommended pattern for tooltips, dropdowns, and context menus, replacing most JS positioning libraries (Popper/Floating UI) for straightforward cases.
