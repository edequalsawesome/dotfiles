---
name: php-heredoc-null-coalescing
description: |
  Fix PHP parse errors when using null coalescing operator (??) inside heredoc or
  double-quoted string interpolation. Use when: (1) "Parse error: syntax error,
  unexpected token '??'" in a PHP file, (2) using {$array['key'] ?? 'default'}
  inside a heredoc/nowdoc, (3) building multi-line strings with fallback values.
  PHP does not support ?? inside string interpolation — extract to variables first.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# PHP Heredoc Null Coalescing Parse Error

## Problem
PHP throws a parse error when you use the null coalescing operator (`??`) inside
heredoc or double-quoted string interpolation like `{$array['key'] ?? 'default'}`.

## Context / Trigger Conditions
- Error message: `Parse error: syntax error, unexpected token "??", expecting "->" or "?->" or "{" or "["`
- Using `??` inside `<<<HEREDOC` blocks or double-quoted strings
- Common when adding defensive defaults to template/prompt strings
- Affects all PHP versions (this is a language limitation, not a version bug)

## Solution
Extract the values with null coalescing into local variables **before** the heredoc,
then interpolate the simple variables.

**Wrong:**
```php
return <<<PROMPT
- Title: {$scenario['title'] ?? 'Unknown'}
- Category: {$scenario['category'] ?? 'General'}
PROMPT;
```

**Right:**
```php
$title    = $scenario['title'] ?? 'Unknown';
$category = $scenario['category'] ?? 'General';

return <<<PROMPT
- Title: {$title}
- Category: {$category}
PROMPT;
```

## Verification
Run `php -l filename.php` — should report "No syntax errors detected."

## Notes
- This also applies to double-quoted strings: `"Hello {$name ?? 'World'}"` will fail
- The ternary operator (`?:`) has the same limitation inside string interpolation
- `sprintf()` is another alternative: `sprintf("Title: %s", $scenario['title'] ?? 'Unknown')`
- Nowdoc (`<<<'HEREDOC'`) doesn't do variable interpolation at all, so it's a non-issue there
