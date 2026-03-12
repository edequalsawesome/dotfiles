---
name: php-elvis-falsy-zero
description: |
  Fix PHP elvis operator (?:) silently discarding valid zero/empty-string values.
  Use when: (1) a numeric field like priority, quantity, or position defaults to a
  fallback value when the user explicitly sets it to 0, (2) a ternary or ?:
  expression swallows '0', 0, or '' because PHP treats them as falsy,
  (3) form input values of "0" are replaced by defaults unexpectedly.
  Covers ?:, empty(), and loose boolean coercion pitfalls in PHP.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# PHP Elvis Operator Falsy Zero

## Problem

PHP's `?:` (elvis) operator and `empty()` treat `0`, `'0'`, `0.0`, and `''` as
falsy. When used with form inputs or user-supplied numeric values, this silently
discards valid zero values and replaces them with defaults.

## Context / Trigger Conditions

- A numeric field (priority, sort order, quantity, position) accepts 0 as a valid value
- User submits a form with "0" but the saved value is the default (e.g., 10)
- Code uses `$value ?: $default` or `empty($value)` to check for missing input
- POST/GET values are strings, so `'0'` is falsy in PHP boolean context

## Solution

**Instead of:**
```php
// BAD: '0' and 0 are falsy, so priority 0 silently becomes 10
$priority = $priority_raw ?: 10;
```

**Use explicit checks:**
```php
// GOOD: Only default when truly empty (not provided)
$priority = '' !== $priority_raw ? (int) $priority_raw : 10;

// Also GOOD: null coalescing for null-only checks
$priority = $priority_raw ?? 10;  // Only defaults on null, not '0'

// Also GOOD: strlen check
$priority = strlen($priority_raw) ? (int) $priority_raw : 10;
```

**Similarly, avoid `empty()` for zero-valid fields:**
```php
// BAD: empty('0') === true
if ( ! empty( $value ) ) { ... }

// GOOD: Check for actual absence
if ( null !== $value && '' !== $value ) { ... }

// GOOD: isset + string check
if ( isset( $value ) && '' !== $value ) { ... }
```

## PHP Falsy Values Reference

These all evaluate to `false` in boolean context:

| Value     | `?:` skips it | `empty()` | `??` skips it |
|-----------|---------------|-----------|---------------|
| `null`    | Yes           | Yes       | Yes           |
| `false`   | Yes           | Yes       | No            |
| `0`       | Yes           | Yes       | No            |
| `0.0`     | Yes           | Yes       | No            |
| `'0'`     | Yes           | Yes       | No            |
| `''`      | Yes           | Yes       | No            |
| `[]`      | Yes           | Yes       | No            |

Key insight: `??` (null coalescing) only triggers on `null`, making it safer for
numeric values. But it won't catch empty strings from form inputs where the field
was present but blank.

## Verification

Test with these inputs and confirm correct behavior:
- Submit form with value "0" -- should save 0, not the default
- Submit form with empty field -- should save the default
- Submit form with valid number -- should save that number

## Example

Real-world bug from a WordPress plugin where snippet priority 0 silently became 10:

```php
// BEFORE (buggy): priority 0 becomes 10 because '0' ?: 10 === 10
$priority = $priority_raw ?: 10;

// AFTER (fixed): explicit empty-string check preserves zero
$priority = '' !== $priority_raw ? max(1, min(999, (int) $priority_raw)) : 10;
```

## Notes

- This is one of PHP's most common silent bugs -- no error, no warning, just wrong data
- Form inputs are always strings, so `'0'` (string zero) is the typical culprit
- When adding server-side clamping (e.g., `max(1, min(999, $val))`), the zero check
  must happen BEFORE the clamp, otherwise you're clamping the default value
- HTML `min`/`max` attributes on `<input type="number">` are client-side only --
  always validate/clamp server-side too
