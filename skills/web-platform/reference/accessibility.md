## Contents

- [WCAG 2.2 Level AA](#wcag-22-level-aa)
- [Color and contrast](#color-and-contrast)
- [Keyboard navigation](#keyboard-navigation)
- [ARIA](#aria)
- [Forms and error handling](#forms-and-error-handling)
- [Screen readers](#screen-readers)
- [Testing tools](#testing-tools)

## WCAG 2.2 Level AA

The legal standard in most jurisdictions (EAA, ADA, Section 508). Build to 2.2 AA — it's backward compatible with 2.1 and 2.0.

The four principles (POUR): **Perceivable**, **Operable**, **Understandable**, **Robust**.

WCAG 2.2-specific criteria worth knowing by number, since they're newer and easy to miss:
- **2.4.11 Focus Not Obscured**: keyboard-focused elements must not be fully hidden behind sticky headers
- **2.4.12 Focus Not Obscured (Enhanced)**: no part of the focused element is hidden (AAA)
- **2.5.3 Target Size (Minimum)**: 24×24px minimum for pointer targets (AA)
- **2.5.8 Target Size**: same idea, with adequate spacing
- **3.2.6 Consistent Help**: if help is present, it appears consistently across pages
- **3.3.7 Redundant Entry**: don't ask for the same information twice in a multi-step process
- **3.3.8 Accessible Authentication**: no cognitive tests (CAPTCHA without an alternative) in login flows

## Color and contrast

```css
/* Minimum contrast ratios */
/* Normal text: 4.5:1 */
/* Large text (18pt+, or 14pt bold+): 3:1 */
/* UI components and graphics: 3:1 */

/* oklch makes contrast analysis predictable: lightness difference drives
   perceptual contrast in a way HSL lightness doesn't. */
:root {
    --color-text-on-dark: oklch(95% 0 0);
    --color-text-on-light: oklch(15% 0 0);
    --color-focus-ring: oklch(60% 0.2 260);  /* must be 3:1 against adjacent colors */
}
```

Never use color as the only means of conveying information. An error state needs more than a red border — an icon, text, or both.

## Keyboard navigation

Every interactive element must be reachable by Tab and operable by Enter or Space. Test the entire application with keyboard only — no mouse.

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content">...</main>
```

```css
:focus-visible {
    outline: 3px solid var(--color-focus-ring);
    outline-offset: 2px;
    border-radius: 2px;
}

/* Hide outline for mouse users, show for keyboard users */
:focus:not(:focus-visible) {
    outline: none;
}
```

Removing an outline with `outline: none` and no replacement fails WCAG 2.4.7. Always provide a visible focus indicator.

## ARIA

Use native HTML first. ARIA is for cases where native semantics aren't sufficient.

```html
<!-- Bad: reinvents a button badly -->
<div role="button" tabindex="0" onclick="submit()">Submit</div>

<!-- Good -->
<button type="submit">Submit</button>

<!-- ARIA is correct when building custom widgets with no native equivalent -->
<div
    role="combobox"
    aria-expanded="false"
    aria-controls="listbox-id"
    aria-haspopup="listbox"
    aria-activedescendant=""
    tabindex="0"
>
    Select an option
</div>

<nav aria-label="Breadcrumb">
<nav aria-label="Pagination">
<nav aria-label="Main navigation">

<!-- Live regions for dynamic updates -->
<div role="status" aria-live="polite">
    <!-- Polite: waits for the user to finish before announcing -->
    Form saved successfully
</div>

<div role="alert" aria-live="assertive">
    <!-- Assertive: interrupts immediately. Errors only. -->
    Session expired. Please log in again.
</div>

<!-- Icon-only buttons always need accessible names -->
<button aria-label="Close dialog">
    <svg aria-hidden="true" focusable="false">...</svg>
</button>
```

## Forms and error handling

```html
<form>
    <div class="field" aria-describedby="email-hint email-error">
        <label for="email">
            Email address
            <span class="required" aria-hidden="true">*</span>
        </label>

        <input
            type="email"
            id="email"
            name="email"
            autocomplete="email"
            required
            aria-required="true"
            aria-invalid="true"
            aria-describedby="email-error"
        />

        <p id="email-hint" class="hint">We'll never share your email</p>
        <p id="email-error" role="alert" class="error">
            <!-- Injected by JS. role=alert auto-announces. -->
            Please enter a valid email address
        </p>
    </div>
</form>
```

## Screen readers

Test with:
- VoiceOver on macOS (Cmd+F5) and iOS (triple-click side button)
- NVDA on Windows with Firefox — the most common screen reader in field use
- TalkBack on Android

Common issues:
- Images without alt text
- Icon-only buttons without `aria-label`
- Tab focus order that doesn't match visual order
- Dynamic content that updates without `aria-live` regions
- Modals that don't trap focus and don't restore focus on close (native `<dialog>` handles this — see `html.md`)
- Tables without `<caption>` and `<th scope="...">`

## Testing tools

Automated tools catch roughly 30-40% of WCAG issues:
- **axe DevTools** (browser extension) — most actionable findings
- **Chrome Lighthouse** — accessibility audit built in
- **WAVE** (WebAIM) — visual overlays showing issues
- **Colour Contrast Analyser** (TPGi) — desktop tool for checking any screen colors

Automated testing is not a substitute for manual keyboard testing and screen reader testing on critical flows.
