---
name: studio-wp-cli-gotchas
description: |
  Fix WordPress Studio WP-CLI commands that fail silently or with unexpected errors.
  Use when: (1) wp_set_current_user(1) returns false for is_user_logged_in() in Studio,
  (2) wp db query fails with "Undefined constant DB_NAME" error, (3) REST API permission
  callbacks return 401 even after setting current user, (4) need to inspect custom DB
  tables on a Studio site. Covers user ID lookups, wp eval workarounds for database
  queries, and REST endpoint testing via CLI.
author: Claude Code
version: 1.0.0
date: 2026-03-07
---

# WordPress Studio WP-CLI Gotchas

## Problem

Several common WP-CLI patterns don't work as expected in WordPress Studio's local
environment, causing silent failures or misleading errors when testing plugins.

## Context / Trigger Conditions

- Using `studio wp` commands to test a plugin on a local Studio site
- `wp_set_current_user(1)` doesn't authenticate the user
- `wp db query "..."` throws `Undefined constant "DB_NAME"` fatal error
- REST API permission callbacks return 401 despite setting current user
- Need to run SQL queries to inspect custom tables

## Solution

### 1. User IDs are NOT sequential from 1

Studio sites use large user IDs (e.g., 329317) instead of starting from 1.
Always look up the actual user ID first:

```bash
studio wp user list --path=~/Studio/your-site
```

Then use the real ID:

```bash
studio wp eval "wp_set_current_user(329317); echo is_user_logged_in() ? 'yes' : 'no';" --path=~/Studio/your-site
```

### 2. wp db query doesn't work - use wp eval instead

`studio wp db query "..."` fails with `Undefined constant "DB_NAME"`. This is a
Studio-specific limitation. Use `wp eval` with `$wpdb` as a workaround:

```bash
# Instead of: studio wp db query "SHOW TABLES LIKE '%sim%'"
# Use:
studio wp eval "global \$wpdb; \$tables = \$wpdb->get_results(\"SHOW TABLES LIKE '%sim%'\", ARRAY_N); foreach(\$tables as \$t) echo \$t[0] . PHP_EOL;" --path=~/Studio/your-site

# Instead of: studio wp db query "DESCRIBE wp_some_table"
# Use:
studio wp eval "global \$wpdb; \$cols = \$wpdb->get_results('DESCRIBE ' . \$wpdb->prefix . 'some_table', ARRAY_A); foreach(\$cols as \$c) echo \$c['Field'] . ' | ' . \$c['Type'] . PHP_EOL;" --path=~/Studio/your-site
```

### 3. Testing REST endpoints via wp eval

To test REST endpoints with authentication in CLI context:

```bash
studio wp eval "
wp_set_current_user(329317);  // Use actual user ID!
\$request = new WP_REST_Request('GET', '/your-namespace/v1/endpoint');
\$response = rest_do_request(\$request);
echo 'Status: ' . \$response->get_status() . PHP_EOL;
echo 'Body: ' . wp_json_encode(\$response->get_data()) . PHP_EOL;
" --path=~/Studio/your-site
```

For POST endpoints with parameters:

```bash
studio wp eval "
wp_set_current_user(329317);
\$request = new WP_REST_Request('POST', '/your-namespace/v1/endpoint');
\$request->set_param('key', 'value');
\$response = rest_do_request(\$request);
echo \$response->get_status();
" --path=~/Studio/your-site
```

## Verification

- `wp_set_current_user()` with correct ID returns `is_user_logged_in() = true`
- `wp eval` with `$wpdb` successfully queries tables
- REST endpoints return expected status codes (200 for auth, 401 for no auth)

## Example

Full acceptance test for a plugin with CPT, DB tables, and REST endpoints:

```bash
studio wp eval "
wp_set_current_user(329317);

// Verify CPT
echo 'CPT exists: ' . (post_type_exists('my_cpt') ? 'yes' : 'no') . PHP_EOL;

// Verify DB tables
global \$wpdb;
\$tables = \$wpdb->get_results(\"SHOW TABLES LIKE '%my_prefix%'\", ARRAY_N);
foreach(\$tables as \$t) echo \$t[0] . PHP_EOL;

// Test REST endpoint (authenticated)
\$r = new WP_REST_Request('GET', '/my-namespace/v1/items');
echo 'Auth: ' . rest_do_request(\$r)->get_status() . PHP_EOL;

// Test REST endpoint (unauthenticated)
wp_set_current_user(0);
echo 'No auth: ' . rest_do_request(\$r)->get_status() . PHP_EOL;
" --path=~/Studio/your-site
```

## Notes

- These issues are specific to WordPress Studio by WordPress.com. Standard WordPress
  installations with MySQL/MariaDB don't have the `wp db query` limitation.
- Studio uses SQLite under the hood, which is why `DB_NAME` isn't defined in the
  traditional sense.
- The `--path` flag is required for all `studio wp` commands to target the correct site.
- Always run `studio site list` first to find your site's path and verify it's online.
