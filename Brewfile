# Brewfile — fresh Mac setup
# Restore: brew bundle --file=~/dotfiles/Brewfile
# Sign into the App Store first, or every `mas` line fails.

tap "hmenzagh/tap"
tap "interactive-buffoonery/tap"
tap "nikitabobko/tap"

# ─── CLI ─────────────────────────────────────────────────────────
brew "aria2"
brew "chafa" # renders Rocket ASCII art via fastfetch
brew "composer"
brew "corepack", link: false
brew "fastfetch"
brew "ffmpeg"
brew "fonttools", link: false
brew "fswatch"
brew "fzf"
brew "gh"
brew "git-filter-repo"
brew "glances"
brew "glow"
brew "go" # required by the `go "…/bootdev"` line below; cleanup autoremoves it otherwise
brew "hugo"
brew "hyperfine"
brew "jq"
brew "lazygit"
brew "mas"
brew "mole"
brew "mosh"
brew "node"
brew "node@22"
brew "opencode"
brew "pandoc"
brew "php"
brew "python@3.12"
brew "ripgrep" # only here as someone's dependency otherwise; autoremove would eat it
brew "starship"
brew "tmux"
brew "uv"
brew "wp-cli"
brew "xcodegen"
brew "yara"
brew "yq"
brew "yt-dlp"
brew "zellij"
brew "zig@0.15", link: true
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "hmenzagh/tap/ccmeter", trusted: true

# ─── Terminals & editors ─────────────────────────────────────────
cask "interactive-buffoonery/tap/awesomux" # our own! 🎉
cask "ghostty"
cask "cmux"
cask "sublime-text"
cask "sublime-merge"
cask "t3-code"

# ─── Browsers (all kept — work testing) ──────────────────────────
cask "firefox"
cask "firefox@developer-edition"
cask "helium-browser"
cask "zen"
cask "choosy" # routes links to the right browser

# ─── AI ──────────────────────────────────────────────────────────
cask "claude"
cask "chatgpt"
cask "openusage"
cask "monologue" # dictation

# ─── Dev / WordPress ─────────────────────────────────────────────
cask "wordpresscom-studio"
cask "local"
cask "orbstack"

# ─── Window management & system ──────────────────────────────────
cask "nikitabobko/tap/aerospace", trusted: true
cask "alfred"
cask "raycast"
cask "hyperkey"
cask "keyboardcleantool"
cask "thaw"
cask "muzzle"
cask "espanso"
cask "hazel"
cask "symboliclinker"
cask "logi-options+"
cask "insta360-link-controller"

# ─── Audio (Rogue Amoeba) ────────────────────────────────────────
cask "audio-hijack"
cask "loopback"
cask "soundsource"
cask "farrago"
cask "fission"

# ─── Media ───────────────────────────────────────────────────────
cask "vlc"
cask "imageoptim"

# ─── Security & sync ─────────────────────────────────────────────
cask "1password"
cask "1password-cli"
cask "secretive"
cask "protonvpn"
cask "proton-drive"
cask "dropbox"
cask "resilio-sync"
cask "rustdesk"
cask "superduper" # keep: cloning tool for the machine migration

# ─── Comms & work ────────────────────────────────────────────────
cask "slack"
cask "zoom"
cask "microsoft-teams"
cask "microsoft-auto-update"
cask "telegram"
cask "todoist-app"
cask "obsidian"
cask "netnewswire"
cask "shottr"

# ─── Fonts ───────────────────────────────────────────────────────
cask "font-bagel-fat-one"
cask "font-domine"
cask "font-hack-nerd-font"
cask "font-inconsolata-for-powerline"
cask "font-monaspace"
cask "font-noto-sans"

# ─── Mac App Store ───────────────────────────────────────────────
mas "1Password for Safari", id: 1569813296
mas "Actions For Obsidian", id: 1659667937
mas "Amphetamine", id: 937984704
mas "CARROTweather", id: 993487541
mas "ColorSlurp", id: 1287239339
mas "Compressor", id: 424390742
mas "Drafts", id: 1435957248
mas "DuckDuckGo Privacy for Safari", id: 1482920575
mas "Endel", id: 1346247457
mas "Fantastical", id: 975937182
mas "Final Cut Pro", id: 424389933
mas "Gifox", id: 1461845568
mas "HomeCam", id: 1292995895
mas "HomePass", id: 1330266650
mas "Infuse", id: 1136220934
mas "Keynote", id: 409183694
mas "Logic Pro", id: 634148309
mas "Mapper", id: 1589391989
mas "Microsoft Excel", id: 462058435
mas "Microsoft PowerPoint", id: 462062816
mas "Microsoft Word", id: 462054704
mas "Motion", id: 434290957
mas "MusicMatch", id: 1596146219
mas "Numbers", id: 409203825
mas "Obsidian Web Clipper", id: 6720708363
mas "Pages", id: 409201541
mas "Parcel 2", id: 375589283
mas "Photomator", id: 1444636541
mas "PiPifier", id: 1160374471
mas "Pixelmator Pro", id: 1289583905
mas "Screens 5", id: 1663047912
mas "StopTheMadness Pro", id: 6471380298
mas "Tampermonkey", id: 6738342400
mas "TestFlight", id: 899247664
mas "TextSniper", id: 1528890965
mas "uBlock Origin Lite", id: 6745342698
mas "Vinegar", id: 1591303229
mas "Xcode", id: 497799835
mas "xSearch", id: 1579902068

# ─── Language runtimes ───────────────────────────────────────────
go "github.com/bootdotdev/bootdev"
uv "claude-code-transcripts"
npm "@doist/todoist-cli"
npm "@mariozechner/pi-coding-agent"
npm "@openai/codex"
npm "defuddle"
npm "mcp-server-apple-events"
npm "obsidian-headless"
npm "pi-claude-bridge"
npm "pi-cmux"
npm "vercel"
npm "wp-studio"

# Not in Homebrew — install by hand on a new machine:
#   Tailscale (App Store or tailscale.com), Backblaze
#   Mirage, Synctrain — mas can't resolve an App Store ID for these (id: 0),
#   so brewfile-sync drops them and `brew bundle` can't install them.
