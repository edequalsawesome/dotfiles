---
name: css-color-scheme-dark-mode-toggle
description: |
  Fix native browser controls (scrollbars, select dropdowns, checkboxes, date inputs)
  staying light when a manual dark mode toggle class is applied. Use when:
  (1) custom-styled elements go dark but native browser chrome stays light,
  (2) building a JS-driven dark mode toggle with CSS classes instead of relying
  solely on prefers-color-scheme, (3) scrollbars or form controls look wrong
  after toggling dark mode via a body class. The fix is adding `color-scheme: dark`
  to the dark override class so the browser knows to render native UI in dark mode.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# CSS color-scheme Property for Manual Dark Mode Toggles

## Problem

When implementing a dark mode toggle that applies a CSS class (e.g., `.dark-mode`,
`.sim-dark`) to override `@media (prefers-color-scheme: dark)`, native browser
controls render in light mode even though custom-styled elements are dark. This
creates a jarring visual mismatch — dark backgrounds with bright white scrollbars,
light select dropdowns, light checkboxes, etc.

## Context / Trigger Conditions

- You have a three-state theme toggle: auto (OS preference) / dark (forced) / light (forced)
- Dark mode works via `@media (prefers-color-scheme: dark)` for auto, plus a CSS class for forced dark
- Custom-styled elements look correct in forced dark mode
- **But**: scrollbars, `<select>`, `<input type="date">`, checkboxes, radio buttons, and other native controls remain light
- The user's OS is set to light mode, but they clicked the dark mode toggle

## Solution

Add `color-scheme: dark` to your forced-dark class. This tells the browser to render
all native UI controls in dark mode, independent of the OS preference.

```css
/* Auto mode — let the browser decide based on OS preference */
:root {
  color-scheme: light dark;
}

/* Forced dark — override native controls too */
.sim-dark {
  color-scheme: dark;
}

/* Forced light — override native controls back to light */
.sim-light {
  color-scheme: light;
}
```

### Why This Is Needed

`@media (prefers-color-scheme: dark)` only fires based on OS settings. When you
force dark mode via a CSS class on a light-OS system, the media query doesn't fire.
Your custom properties and overrides handle styled elements, but the browser still
thinks it's in light mode for native controls. `color-scheme: dark` on the override
class explicitly tells the browser: "render native UI dark regardless of OS setting."

### Three-State Toggle Pattern

For a full auto/dark/light toggle:

1. **Auto** (`color-scheme: light dark` on `:root`): Browser follows OS preference for native controls; your `@media (prefers-color-scheme: dark)` rules handle custom styles.
2. **Dark** (`color-scheme: dark` on `.dark-class`): Forces native controls dark; your dark class overrides handle custom styles.
3. **Light** (`color-scheme: light` on `.light-class`): Forces native controls light; your light class overrides handle custom styles — needed when OS is dark but user wants light.

### Modern Alternative: light-dark()

The `light-dark()` CSS function (baseline since May 2024) automatically resolves
values based on the computed `color-scheme`:

```css
:root {
  color-scheme: light dark;
  --bg: light-dark(#ffffff, #1a1a2e);
  --text: light-dark(#333333, #e0e0e0);
}
```

When you set `color-scheme: dark` on a forced-dark class, `light-dark()` values
automatically resolve to their dark variants without needing separate override rules.

## Verification

1. Set OS to light mode
2. Click the dark mode toggle to force dark
3. Check: scrollbars should be dark, `<select>` dropdowns should have dark backgrounds,
   checkboxes/radio buttons should use dark styling
4. Reverse: set OS to dark mode, force light via toggle — native controls should be light

## Example

Before fix (broken — native controls stay light on forced dark):
```css
.sim-dark {
  --sim-bg-primary: #1a1a2e;
  --sim-text-primary: #e0e0e0;
  /* Missing: color-scheme: dark; */
}
```

After fix:
```css
.sim-dark {
  color-scheme: dark;
  --sim-bg-primary: #1a1a2e;
  --sim-text-primary: #e0e0e0;
}
```

## Notes

- `color-scheme` is inherited, so setting it on a class applied to `<body>` or `:root` covers the whole page
- Browser support: all modern browsers (Chrome 81+, Firefox 96+, Safari 13+)
- This also affects the default background color of the page — `color-scheme: dark` makes the browser's default white background dark, which prevents white flash on page load
- The `meta` tag `<meta name="color-scheme" content="light dark">` serves a similar purpose for the initial page load before CSS is parsed

## References

- [MDN: color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme)
- [CSS-Tricks: A Complete Guide to Dark Mode on the Web](https://css-tricks.com/a-complete-guide-to-dark-mode-on-the-web/)
- [Embracing Native Dark Mode with the CSS color-scheme Property](https://rebeccamdeprey.com/blog/embracing-native-dark-mode-with-the-css-color-scheme-property)
- [CSS-Tricks: Come to the light-dark() Side](https://css-tricks.com/come-to-the-light-dark-side/)
