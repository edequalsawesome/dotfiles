# WordPress Development Context

## Local Development (WordPress Studio)
- Site runs at `http://localhost:8881/wp-admin/`
- Use WP-CLI to reset admin password when needed for testing
- MCP tools available: Context7, Playwright, Brave Search
- **Symlinks DON'T work in Studio** — use `rsync -a --exclude='.git' --exclude='node_modules'` to copy plugins
- Plugin constants (API keys, proxy URLs) go in Studio's `wp-config.php` as `define()` calls
- Studio sites live at `~/Studio/<site-name>/`

## Build & Deploy
- Always use `npm run plugin-zip` to build plugin zip files
- Use as many native WP controls and settings as possible — don't recreate functionality

## Code Conventions
- NEVER use emojis in documentation text
- Use native block editor controls over custom implementations
- At end of day, create a markdown file explaining what was done per project; add to `.gitignore`

## Common WP-CLI Commands

```bash
# User management
user create username email@domain.com --role=administrator
user update USERID --user_email=new@email.com --skip-email

# Plugin bulk operations
wpcomsh deactivate-user-plugins
wpcomsh reactivate-user-plugins --interactive

# Search-replace (ALWAYS use --skip-columns=guid)
search-replace OLD_DOMAIN NEW_DOMAIN --skip-columns=guid --dry-run
search-replace OLD_DOMAIN NEW_DOMAIN --skip-columns=guid
cache flush

# Check autoloaded options
wp db query "SELECT option_name, autoload, length(option_value) FROM wp_options WHERE autoload='yes' ORDER BY length(option_value) DESC LIMIT 50;"
```

## WP-Specific Review
- `/review-conner` runs WordPress-specific code review (hooks, nonces, $wpdb, REST API, blocks)
- Auto-included when `/review-yj` detects WordPress code
