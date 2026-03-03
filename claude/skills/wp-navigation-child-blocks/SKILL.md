---
name: wp-navigation-child-blocks
description: |
  Add custom child blocks to the WordPress core/navigation block. Use when:
  (1) building blocks that should appear inside the Navigation block inserter,
  (2) custom blocks need to render inside navigation with proper <li> wrapping,
  (3) extending Navigation with dynamic content like category lists or post lists.
  Covers the three-part hook pattern: JS allowedBlocks filter, PHP listable_blocks
  filter, and block.json parent attribute. Based on the Ollie Menu Designer pattern.
author: Claude Code
version: 1.0.0
date: 2026-03-02
---

# WordPress Navigation Block Child Blocks

## Problem
The core Navigation block (`core/navigation`) has a restricted set of allowed child blocks.
Custom blocks won't appear in the Navigation inserter or render correctly inside navigation
without hooking into three specific extension points.

## Context / Trigger Conditions
- Building a custom block that should live inside the Navigation block
- Custom block doesn't appear in the Navigation block's inserter
- Custom block renders but isn't wrapped in `<li>` on the frontend
- Want to add dynamic content (categories, recent posts, custom widgets) to navigation

## Solution

Three things must be done simultaneously:

### 1. JS Filter: Add to allowedBlocks

In your primary block's `index.js`, hook `blocks.registerBlockType` to inject your blocks
into the Navigation block's `allowedBlocks` list:

```js
import { addFilter } from '@wordpress/hooks';

addFilter(
  'blocks.registerBlockType',
  'my-plugin/add-to-navigation',
  ( settings, name ) => {
    if ( name !== 'core/navigation' ) {
      return settings;
    }

    const allowedBlocks = settings.allowedBlocks ?? [];

    return {
      ...settings,
      allowedBlocks: [
        ...allowedBlocks,
        'my-plugin/custom-block-a',
        'my-plugin/custom-block-b',
      ],
    };
  }
);
```

**Important:** Only add this filter in ONE block's index.js (typically the first/primary
one), not in every block — otherwise you'll add duplicate entries.

### 2. PHP Filter: Enable `<li>` wrapping

The Navigation block wraps recognized child blocks in `<li>` elements. Your blocks need
to be added to this list server-side:

```php
add_filter( 'block_core_navigation_listable_blocks', function( $block_names ) {
  $block_names[] = 'my-plugin/custom-block-a';
  $block_names[] = 'my-plugin/custom-block-b';
  return $block_names;
} );
```

Without this, your blocks render but break the `<ul>` > `<li>` semantic structure.

### 3. block.json: Set parent attribute

In each child block's `block.json`, restrict where it can be inserted:

```json
{
  "parent": [ "core/navigation" ]
}
```

If your block can also appear inside a custom section wrapper (that itself is a nav child),
include both:

```json
{
  "parent": [ "core/navigation", "my-plugin/nav-section" ]
}
```

### Complete Pattern

```
┌─────────────────────────────────────────────────┐
│  JS Filter (blocks.registerBlockType)           │
│  → Makes blocks appear in Navigation inserter   │
├─────────────────────────────────────────────────┤
│  PHP Filter (block_core_navigation_listable_)   │
│  → Wraps blocks in <li> on frontend             │
├─────────────────────────────────────────────────┤
│  block.json parent attribute                    │
│  → Restricts blocks to Navigation context       │
└─────────────────────────────────────────────────┘
```

## Verification
1. Open the Site Editor and edit a Navigation block
2. Click the inserter (+) inside the Navigation block
3. Your custom blocks should appear in the block list
4. Insert a block and check the frontend HTML — it should be wrapped in `<li>`

## Example
See `/Users/edequalsawesome/Development/awesome-navigation/` for a complete implementation
with three child blocks (nav-section, category-list, latest-posts-nav).

Key files:
- `src/blocks/nav-section/index.js` — JS filter (lines 12-31)
- `includes/navigation-filters.php` — PHP filter
- `src/blocks/category-list/block.json` — parent attribute

## Notes
- This pattern is used by the Ollie Menu Designer plugin
- The `allowedBlocks` spread (`settings.allowedBlocks ?? []`) is important — don't replace
  the array, extend it, or you'll remove core navigation blocks
- Server-side rendered blocks (with `render.php`) work fine as navigation children
- The Navigation block's built-in overlay/hamburger mobile behavior works automatically
  with custom child blocks — no extra work needed
- For blocks that accept inner blocks (like a section wrapper), set those inner blocks'
  `parent` to include both `core/navigation` AND your wrapper block
