#!/bin/sh
# Gesture dispatcher for aerospace-swipe daemon
A=$(command -v aerospace || true)
[ -x "$A" ] || A=/opt/homebrew/bin/aerospace
[ -x "$A" ] || A=/usr/local/bin/aerospace

# Only handle gestures when the built-in display is the sole active monitor.
monitors=$($A list-monitors --format '%{monitor-name}') || exit 0
printf '%s\n' "$monitors" | grep -Eq '^Built-in' || exit 0
printf '%s\n' "$monitors" | grep -Eqv '^Built-in' && exit 0

dir="$1"
case "$dir" in
  up)   exec $A fullscreen ;;
  down) exec $A layout tiles accordion ;;
esac

# next/prev cycle non-empty workspaces (plus current); carry-* moves the window too
cur=$($A list-workspaces --focused)
list=$(printf '%s\n%s' "$($A list-workspaces --monitor focused --empty no)" "$cur" | sort -u)
n=$(echo "$list" | wc -l | tr -d ' ')
[ "$n" -lt 2 ] && exit 0
idx=$(echo "$list" | grep -n "^$cur$" | cut -d: -f1)
case "$dir" in
  next|carry-next) idx=$((idx % n + 1)) ;;
  prev|carry-prev) idx=$(( (idx - 2 + n) % n + 1 )) ;;
  *) exit 0 ;;
esac
target=$(echo "$list" | sed -n "${idx}p")
case "$dir" in
  carry-*) $A move-node-to-workspace "$target" ;;
esac
exec $A workspace "$target"
