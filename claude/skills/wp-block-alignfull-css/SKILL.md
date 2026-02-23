---
name: wp-block-alignfull-css
description: |
  Fix stretched, distorted, or incorrectly sized WordPress blocks when using alignfull
  (full-width) alignment. Use when: (1) a custom block or block extension looks correct
  at normal width but stretches/distorts at alignfull, (2) alignfull blocks don't reach
  the edges of the viewport, (3) full-width blocks look wrong in the block editor but
  fine on frontend or vice versa. Covers classic themes, block themes with global padding,
  constrained layouts, and the block editor iframe.
author: Claude Code
version: 1.0.0
date: 2026-02-20
---

# WordPress Block alignfull CSS Pattern

## Problem

Custom WordPress blocks (or block extensions) that render SVG, canvas, or other
aspect-ratio-sensitive content appear stretched or distorted when set to full-width
(`alignfull`) alignment. The block may also fail to extend to the full viewport width,
or look correct on the frontend but broken in the editor (or vice versa).

## Context / Trigger Conditions

- A custom block looks fine at default/wide width but is stretched/squished at `alignfull`
- The block only adjusts margins for full-width but doesn't recalculate width
- `alignfull` works on some themes but not others
- The block editor preview doesn't match the frontend rendering for full-width blocks
- CSS uses only `margin-left: calc(var(--wp--style--root--padding-left) * -1)` without
  a corresponding width calculation

## Solution

Use a theme-agnostic, multi-fallback CSS approach. You need **four rules** to cover
all WordPress contexts:

### 1. Base rule (classic themes, centered layouts)

```css
.wp-block-separator.your-block-class.alignfull {
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(50% - 50vw);
    margin-right: calc(50% - 50vw);
}
```

### 2. Block themes with global padding (higher specificity)

This is the **critical rule** most implementations miss. You must set `width` to
include the padding, not just offset with negative margins:

```css
.has-global-padding .wp-block-separator.your-block-class.alignfull,
.is-layout-constrained .wp-block-separator.your-block-class.alignfull,
.wp-block-post-content .wp-block-separator.your-block-class.alignfull {
    width: calc(100% + var(--wp--style--root--padding-left, clamp(1rem, 3vw, 2rem)) + var(--wp--style--root--padding-right, clamp(1rem, 3vw, 2rem)));
    max-width: none;
    margin-left: calc(-1 * var(--wp--style--root--padding-left, clamp(1rem, 3vw, 2rem)));
    margin-right: calc(-1 * var(--wp--style--root--padding-right, clamp(1rem, 3vw, 2rem)));
}
```

Key details:
- The `clamp()` fallbacks handle themes that don't define the CSS custom properties
- Three selectors cover different container contexts in block themes
- `max-width: none` overrides the base rule's `100vw` constraint

### 3. Direct child of wp-site-blocks

```css
.wp-site-blocks > .wp-block-separator.your-block-class.alignfull {
    margin-left: calc(50% - 50vw);
    margin-right: calc(50% - 50vw);
}
```

### 4. Block editor (iframe-based)

The editor runs in an iframe with `.editor-styles-wrapper` on the body and a
constrained `.is-root-container`. Viewport units work correctly inside the iframe:

```css
.editor-styles-wrapper .wp-block-separator.your-block-class.alignfull,
.block-editor-block-list__layout .wp-block-separator.your-block-class.alignfull {
    width: 100vw;
    max-width: 100vw;
    margin-left: calc(50% - 50vw);
    margin-right: calc(50% - 50vw);
}
```

## Common Mistake

The most common mistake is only setting negative margins without adjusting width:

```css
/* WRONG - causes stretching */
.has-global-padding > .your-block.alignfull {
    margin-left: calc(var(--wp--style--root--padding-left) * -1);
    margin-right: calc(var(--wp--style--root--padding-right) * -1);
}
```

This shifts the block's position but the content stays at `100%` of the parent width,
causing SVG/canvas content to stretch to fill the wider visual area.

## Verification

1. Check the block at `alignfull` in a block theme (e.g., Twenty Twenty-Four)
2. Check in a classic theme
3. Check the block editor preview matches the frontend
4. Resize the browser window to confirm responsive behavior
5. Use browser DevTools to verify computed width matches viewport width

## Example

Applied in both Awesome Squiggle and Awesome Sparkle WordPress plugins for full-width
SVG-based separator blocks. The fix was first developed for Awesome Squiggle
(2026-01-28) and ported to Awesome Sparkle (2026-02-20).

## Notes

- The block editor uses an iframe architecture since WordPress 6.x — padding-based
  calculations don't work reliably, viewport units do
- If your block also needs PHP-side awareness of alignment (e.g., for SVG viewBox
  sizing), check both `className` and the `align` attribute, as WordPress stores
  alignment separately from CSS classes
- The `> ` direct child combinator in `.has-global-padding >` can be too restrictive
  if the block is nested inside groups — prefer descendant selectors without `>`
