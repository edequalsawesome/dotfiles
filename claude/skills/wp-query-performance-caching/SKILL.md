---
name: wp-query-performance-caching
description: |
  Eliminate N+1 meta queries and redundant database calls in WordPress plugins. Use when:
  (1) a plugin calls get_post_meta() in a loop for each post, (2) the same WP_Query runs
  multiple times per page load, (3) snippet/widget/shortcode queries run on every page
  regardless of need. Covers update_meta_cache() for batch meta priming, transient caching
  for persistent query results, and in-memory caching for per-request deduplication.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# WordPress Query Performance: Three-Layer Caching

## Problem

WordPress plugins that use Custom Post Types often create severe N+1 query problems:
- `get_post_meta()` called per-post in a loop (5 meta keys x 20 posts = 100 queries)
- The same query runs multiple times per page load (e.g., "get all active snippets"
  called once per location: header, footer, content, sidebar = 4x)
- Query results aren't cached, so every page load repeats the work

## Context / Trigger Conditions

- Plugin uses `get_posts()` or `WP_Query` then loops with `get_post_meta()` per result
- Same query function called from multiple hooks in a single request
- Query Monitor or debug bar shows dozens of meta queries per page load
- Site performance degrades as CPT count grows

## Solution

Apply three layers of caching, each solving a different problem:

### Layer 1: Batch Meta Priming (`update_meta_cache`)

Eliminates N+1 meta queries by loading all meta for a set of posts in one query.

```php
public function get_snippets() {
    $posts = get_posts( array(
        'post_type'      => 'my_cpt',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
    ) );

    if ( empty( $posts ) ) {
        return array();
    }

    // ONE query primes meta for ALL posts (eliminates N*meta_keys queries)
    $post_ids = wp_list_pluck( $posts, 'ID' );
    update_meta_cache( 'post', $post_ids );

    // Now get_post_meta() hits the object cache, not the database
    $items = array();
    foreach ( $posts as $post ) {
        $items[] = array(
            'id'       => $post->ID,
            'name'     => $post->post_title,
            'code'     => $post->post_content,
            'type'     => get_post_meta( $post->ID, '_my_type', true ),     // cached
            'location' => get_post_meta( $post->ID, '_my_location', true ), // cached
            'priority' => get_post_meta( $post->ID, '_my_priority', true ), // cached
        );
    }

    return $items;
}
```

**Impact:** Reduces `N * meta_keys + 1` queries to just `2` queries (one for posts, one for all meta).

### Layer 2: Transient Caching (Persistent)

Caches the fully-formatted query result across page loads. Must be invalidated on CRUD.

```php
const CACHE_KEY = 'my_plugin_items_all';

public function get_snippets() {
    // Check transient first
    $cached = get_transient( self::CACHE_KEY );
    if ( false !== $cached ) {
        return $cached;
    }

    // ... run query + update_meta_cache + format (as above) ...

    // Cache for 12 hours (or until invalidated)
    set_transient( self::CACHE_KEY, $items, 12 * HOUR_IN_SECONDS );

    return $items;
}

// CRITICAL: Invalidate on any data change
public function clear_cache() {
    delete_transient( self::CACHE_KEY );
}

// Call clear_cache() in: create, update, delete, toggle, bulk operations
public function create_item( $data ) {
    // ... create logic ...
    $this->clear_cache();
}
```

**Impact:** Zero database queries on cache hit. First request after a change rebuilds the cache.

**Important:** `get_transient()` returns `false` on cache miss, so if your cached data
could legitimately be `false`, wrap it in an array or use a sentinel value.

### Layer 3: In-Memory Per-Request Cache

Prevents the same filtered subset from being queried/computed multiple times within a
single page load.

```php
private $filtered_cache = array();

public function get_items_for_location( $location ) {
    if ( isset( $this->filtered_cache[ $location ] ) ) {
        return $this->filtered_cache[ $location ];
    }

    $all = $this->get_snippets(); // hits transient cache
    $filtered = array_filter( $all, function( $item ) use ( $location ) {
        return $item['location'] === $location || $item['location'] === 'everywhere';
    } );

    $this->filtered_cache[ $location ] = $filtered;
    return $filtered;
}
```

**Impact:** If 4 hooks each call `get_items_for_location('everywhere')`, only the first
one does any work.

## Verification

1. Install Query Monitor plugin
2. Before: Note query count on a page load (look for repeated `postmeta` queries)
3. After: Should see 0-2 queries for your CPT on cached page loads
4. Test invalidation: Create/edit/delete an item, confirm next page load rebuilds cache

## Example

Real-world WordPress code snippet plugin:
- **Before:** 6 location queries x (1 post query + N*5 meta queries) = 31+ queries per page
- **After:** 0 queries on cache hit, 2 queries on cache miss, filtered in-memory

## Notes

- `update_meta_cache()` works with WordPress's built-in object cache -- if you have a
  persistent object cache (Redis, Memcached), you get even more benefit
- Transient TTL is a safety net, not the primary invalidation -- always explicitly
  `delete_transient()` on data changes
- For plugins with many CPT items (1000+), consider paginated transients or lazy loading
- The three layers are independent -- you can use any combination, but together they
  cover persistent caching (transient), query optimization (meta priming), and
  per-request deduplication (in-memory)
- See also: `php-elvis-falsy-zero` for a related gotcha when formatting cached meta values
