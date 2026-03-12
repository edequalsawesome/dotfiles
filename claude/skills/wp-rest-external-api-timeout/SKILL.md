---
name: wp-rest-external-api-timeout
description: |
  Fix WordPress REST API endpoints that call external APIs (AI proxies, payment
  gateways, webhooks) dying before the HTTP response arrives. Use when:
  (1) wp_remote_post with long timeout silently fails or returns empty,
  (2) REST endpoint returns 500 but the external API logs show no request received,
  (3) PHP max_execution_time kills the request before wp_remote_post timeout fires.
  Covers set_time_limit guard, N+1 query prevention in list endpoints, and
  friction_point / enum validation patterns for WordPress REST APIs.
author: Claude Code
version: 1.0.0
date: 2026-03-09
---

# WordPress REST API + External API Timeout Race

## Problem

WordPress REST API endpoints that call external APIs (AI services, payment processors, webhooks) can silently die when PHP's `max_execution_time` (default 30s) kills the process before `wp_remote_post`'s timeout fires.

Your endpoint sets `'timeout' => 60` on `wp_remote_post`, but PHP itself dies at 30 seconds. The request never completes, and you get a 500 with no useful error.

## Context / Trigger Conditions

- REST endpoint calls `wp_remote_post()` or `wp_remote_get()` with timeout > 30s
- Endpoint works in local dev (where `max_execution_time` is often 0/unlimited) but fails in production
- External API logs show the request was received but the WordPress side already 500'd
- Intermittent failures that correlate with slow external API responses

## Solution

Add `set_time_limit()` before the external call, with a value higher than your HTTP timeout:

```php
// Extend PHP execution time to accommodate external API response.
if ( function_exists( 'set_time_limit' ) ) {
    set_time_limit( 120 ); // Must be > wp_remote_post timeout.
}

$response = wp_remote_post(
    $api_url,
    array(
        'timeout' => 60,
        'headers' => array( /* ... */ ),
        'body'    => wp_json_encode( $payload ),
    )
);
```

Key points:
- `set_time_limit()` resets the timer from the current moment, it doesn't add to the original limit
- Guard with `function_exists()` because `set_time_limit` is disabled on some hosts and in safe mode
- Set it to at least 2x your HTTP timeout to account for response parsing overhead
- Only extend the limit for the specific endpoint that needs it, not globally

## Related Pattern: N+1 Queries in List Endpoints

When a list endpoint enriches items with related data (e.g., adding scenario titles to sessions), pre-fetch the related data instead of querying inside `array_map`:

```php
// BAD: N+1 -- one query per session.
$result = array_map( function ( $session ) {
    $scenario = $this->scenario_engine->get_scenario( $session->scenario_id );
    return array( 'scenario_title' => $scenario['title'] );
}, $sessions );

// GOOD: Pre-fetch unique IDs, then look up.
$scenario_titles = array();
foreach ( $sessions as $session ) {
    $sid = (int) $session->scenario_id;
    if ( ! isset( $scenario_titles[ $sid ] ) ) {
        $scenario = $this->scenario_engine->get_scenario( $sid );
        $scenario_titles[ $sid ] = $scenario ? $scenario['title'] : '(Deleted)';
    }
}

$result = array_map( function ( $session ) use ( $scenario_titles ) {
    return array(
        'scenario_title' => $scenario_titles[ (int) $session->scenario_id ] ?? '(Deleted)',
    );
}, $sessions );
```

## Related Pattern: Validate Enums Against Constants

When you validate one enum field (e.g., tier), don't forget to validate all of them:

```php
// Easy to forget the second enum when you already validated the first.
if ( ! array_key_exists( $tier, Training_Sim_Evaluator::TIERS ) ) {
    return new WP_Error( 'invalid_tier', '...', array( 'status' => 400 ) );
}

// Don't forget this one too!
if ( ! empty( $friction_point ) && ! in_array( $friction_point, Training_Sim_Evaluator::FRICTION_POINTS, true ) ) {
    return new WP_Error( 'invalid_friction_point', '...', array( 'status' => 400 ) );
}
```

## Verification

- Set `max_execution_time` to 30 in php.ini and test with a slow external API
- Confirm the endpoint completes instead of 500ing
- Check that `set_time_limit` call appears in the endpoint handler, not globally

## Notes

- This is specific to WordPress REST endpoints. WP-CLI commands typically have `max_execution_time = 0` (unlimited).
- WP-Cron callbacks also default to 30s and need the same treatment for long external calls.
- If the external API consistently takes > 30s, consider an async pattern (queue the work, poll for results) instead of extending the timeout.
