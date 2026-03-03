---
name: wp-scripts-block-build-gotchas
description: |
  Fix @wordpress/scripts build issues with custom blocks. Use when:
  (1) block styles don't load because block.json references style.css/edit.css but wp-scripts
  generates style-index.css/index.css, (2) webpack config fails when spreading defaultConfig.entry
  because it's a function not an object, (3) PHP files in src/ are missing from plugin-zip output
  because only directories listed in package.json "files" are included. Covers wp-scripts build,
  block.json style references, webpack.config.js customization, and plugin-zip packaging.
author: Claude Code
version: 1.0.0
date: 2026-03-02
---

# @wordpress/scripts Block Build Gotchas

## Problem
When building custom WordPress blocks with `@wordpress/scripts`, several non-obvious
mismatches between what you'd expect and what the tooling actually does can cause blocks
to silently fail to load styles or break the build entirely.

## Context / Trigger Conditions
- Block styles (frontend or editor) don't load despite SCSS files existing and compiling
- Webpack build fails with "defaultConfig.entry is not iterable" or similar
- `npm run plugin-zip` produces a zip missing PHP files that live in `src/`
- Using `@wordpress/scripts` v28+ with custom `webpack.config.js`

## Solution

### 1. CSS file naming mismatch in block.json

`wp-scripts` does NOT output `style.css` and `edit.css`. It generates:

| Source import | Build output | block.json reference |
|---|---|---|
| `import './style.scss'` | `style-index.css` | `"style": "file:./style-index.css"` |
| `import './edit.scss'` | `index.css` | `"editorStyle": "file:./index.css"` |

**Wrong:**
```json
{
  "editorStyle": "file:./edit.css",
  "style": "file:./style.css"
}
```

**Correct:**
```json
{
  "editorStyle": "file:./index.css",
  "style": "file:./style-index.css"
}
```

You must also import the SCSS files in your block's `index.js`:
```js
import './style.scss';
import './edit.scss';
```

### 2. Webpack entry is a function, not an object

When extending the default webpack config to add extra entry points (e.g., for extensions
that aren't blocks), `defaultConfig.entry` is a **function** that auto-discovers `block.json`
files. You must call it:

**Wrong:**
```js
module.exports = {
  ...defaultConfig,
  entry: {
    ...defaultConfig.entry,  // This spreads a function, not entries
    'extensions/my-extension': './src/extensions/my-extension.js',
  },
};
```

**Correct:**
```js
module.exports = {
  ...defaultConfig,
  entry: {
    ...defaultConfig.entry(),  // Call it!
    'extensions/my-extension': path.resolve(__dirname, 'src/extensions/my-extension.js'),
  },
};
```

### 3. Plugin-zip excludes src/ by default

`wp-scripts plugin-zip` uses the `"files"` field in `package.json` to determine what goes
in the zip. PHP files in `src/` (like pattern registrations) won't be included unless `src/`
is in the files array.

**Better approach:** Keep PHP files that don't need building in `includes/` (which should
already be in your files list), not in `src/`:

```json
{
  "files": [
    "awesome-plugin.php",
    "build/",
    "includes/",
    "templates/",
    "parts/",
    "readme.txt"
  ]
}
```

## Verification
- Run `npm run build` and check `build/blocks/*/block.json` — the style references should
  match actual filenames in the same directory
- Run `ls build/blocks/your-block/` to see actual CSS filenames generated
- Run `npm run plugin-zip` and inspect the output to verify all PHP files are included

## Example
See `/Users/edequalsawesome/Development/awesome-navigation/` for a complete working example
with three custom blocks, a webpack extension entry, and correct packaging.

## Notes
- The CSS naming convention (`style-index.css`, `index.css`) comes from how wp-scripts splits
  "style" imports (shared frontend+editor) vs "editor-only" imports in the webpack config
- RTL stylesheets are auto-generated as `style-index-rtl.css` and `index-rtl.css`
- `block.json` `render` field (`"render": "file:./render.php"`) works correctly — wp-scripts
  copies PHP files to build output as-is
