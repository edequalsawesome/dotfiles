#!/bin/bash
#
# Entry point: clones/updates the dotfiles repo, then hands off to the
# matching OS bootstrap script. All args are forwarded (e.g. a Brewfile
# friendly-name override on macOS).

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "Downloading dotfiles from GitHub"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/edequalsawesome/dotfiles.git "$DOTFILES_DIR"
else
    echo "Updating dotfiles repository..."
    git -C "$DOTFILES_DIR" pull
fi

case "$(uname -s)" in
    Darwin)
        exec "$DOTFILES_DIR/macos/setup-macos.sh" "$@"
        ;;
    Linux)
        exec "$DOTFILES_DIR/arch/setup-arch.sh" "$@"
        ;;
    *)
        echo "ERROR: unsupported OS '$(uname -s)' - no bootstrap script for this platform." >&2
        exit 1
        ;;
esac
