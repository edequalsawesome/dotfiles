#!/bin/sh
set -eu

tmp=$(mktemp -d /tmp/aerospace-swipe-test.XXXXXX)
trap 'trash "$tmp"' EXIT
cat > "$tmp/aerospace" <<'EOF'
#!/bin/sh
if [ "$1" = list-monitors ]; then
    printf '%s\n' "$MONITORS"
else
    printf '%s\n' "$*" >> "$CALLS"
fi
EOF
chmod +x "$tmp/aerospace"
export PATH="$tmp:$PATH" CALLS="$tmp/calls"

MONITORS='Built-in Retina Display
Studio Display'; export MONITORS
sh "$(dirname "$0")/swipe.sh" up
[ ! -e "$CALLS" ]

MONITORS='Studio Display'; export MONITORS
sh "$(dirname "$0")/swipe.sh" up
[ ! -e "$CALLS" ]

MONITORS='Built-in Retina Display'; export MONITORS
sh "$(dirname "$0")/swipe.sh" up
[ "$(cat "$CALLS")" = fullscreen ]
