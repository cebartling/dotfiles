# Brewfile — canonical macOS package manifest for cebartling/dotfiles.
# Apply with:  brew bundle --file=$DOTFILES/Brewfile
# Check drift: brew bundle check --file=$DOTFILES/Brewfile
#
# Kubernetes-specific tools live in Brewfile.k8s and are installed
# separately via scripts/macOS/install_k8s_tools.zsh.
#
# Apple-platform (iOS/iPadOS/macOS) dev tools live in Brewfile.apple
# and are installed separately via scripts/macOS/install_apple_tools.zsh.
#
# The Tailscale GUI cask lives in Brewfile.tailscale and is installed
# separately via scripts/macOS/install_tailscale_app.zsh (its installer
# requires sudo, so it can't run unattended from bootstrap.sh).
#
# The NetBird GUI cask lives in Brewfile.netbird and is installed
# separately via scripts/macOS/install_netbird_app.zsh (same sudo
# constraint as Tailscale). The netbird CLI formula stays here.
#
# Cloud management tooling (provider CLIs + Hashicorp IaC) lives in
# Brewfile.cloud and is installed separately via
# scripts/macOS/install_cloud_tools.zsh.

# ===== Taps =====
# Homebrew 6.0+ no longer trusts third-party taps by default; formulae from
# untrusted taps are skipped during `brew bundle`. After adding/restoring these
# taps, trust their formulae once per machine, e.g.:
#   brew trust --formula atlassian-labs/acli/acli weaveworks/tap/eksctl \
#     confluentinc/tap/cli oven-sh/bun/bun \
#     teamookla/speedtest/speedtest detachhead/tap/rebased
# See https://docs.brew.sh/Tap-Trust
tap "atlassian-labs/acli"
tap "derailed/k9s"
tap "detachhead/tap"
tap "entireio/tap"
tap "jithin-sabu/tap"
tap "manaflow-ai/cmux"
tap "netbirdio/tap"
tap "oven-sh/bun"
tap "paninihouse/brewer-cmd"  # Brewer X GUI app's companion command (brewer-tap-content-info)
tap "productdevbook/tap"
tap "steveyegge/beads"
tap "teamookla/speedtest"
tap "tednaleid/montty"

# ===== Core CLI =====
brew "bash"
brew "curl"
brew "git"
brew "git-lfs"              # large-file storage for git
brew "openssl@3"
brew "tmux"

# ===== Modern CLI replacements =====
brew "bat"                  # cat with syntax highlighting
brew "eza"                  # ls replacement
brew "fd"                   # find replacement
brew "ripgrep"              # grep replacement
brew "dust"                 # du replacement
brew "mole"                 # disk cleanup / optimization (mole.fit)
brew "procs"                # ps replacement
brew "fzf"                  # fuzzy finder
brew "tree"                 # directory layout
brew "zoxide"               # frecency-based cd (z <name>)
brew "git-delta"            # better git diff pager
brew "difftastic"           # AST-aware structural diff
brew "starship"             # cross-shell prompt
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# ===== Dev tooling =====
brew "ast-grep"             # structural code search
brew "atuin"                # better shell history (opt-in init in zshrc.local)
brew "beads"                # bd issue tracker
brew "cargo-binstall"
brew "direnv"
brew "atlassian-labs/acli/acli" # Atlassian CLI (Jira, Confluence, Bitbucket)
brew "gh"                   # GitHub CLI
brew "gitleaks"             # secret scanner
brew "nmap"                 # network scanner
brew "trivy"                # vulnerability scanner (containers, IaC, filesystems)
brew "glow"                 # terminal markdown renderer
brew "hyperfine"
brew "jq"
brew "yq"                   # YAML query (jq for YAML)
brew "fx"                   # interactive JSON viewer
brew "just"
brew "lazygit"              # TUI git client
brew "miller"               # mlr — jq for CSV/TSV/JSON tabular data
brew "pre-commit"
brew "semgrep"
brew "tokei"                # fast cloc replacement
brew "typescript-language-server"
brew "vale"
brew "watchexec"

# ===== Runtimes / package managers =====
brew "nvm"                  # lazy-loaded in zshrc
brew "poetry"
brew "uv"

# ===== HTTP / network =====
brew "caddy"
brew "dnsmasq"
brew "doggo"                # DNS client (replaces deprecated `dog`; run: brew uninstall dog)
brew "grpcurl"              # curl for gRPC
brew "httpie"
brew "mosh"                 # roaming SSH: survives sleep and network changes
brew "xh"                   # faster httpie
brew "sniffnet"
brew "tailscale"
brew "netbirdio/tap/netbird"  # WireGuard-based mesh VPN (netbird-ui cask = GUI)

# ===== Containers =====
brew "colima"
brew "podman"
brew "podman-compose"

# ===== Document / image processing =====
# poppler omitted: source build fails on this Homebrew prefix
# (/Users/e9004590/homebrew) because the p11-kit dep times out in
# meson tests. Install ad-hoc when pdftotext/pdftoppm/pdfinfo are needed.
brew "imagemagick"          # convert/resize images (token cost reduction)
brew "ffmpeg-full"          # audio/video conversion & processing; the full
                            # build (extra codecs/filters + ffplay). keg-only,
                            # so zshrc prepends its bin to $path.

# ===== Data =====
brew "duckdb"
brew "mongodb-atlas-cli"
brew "pgcli"                # Postgres CLI with autocomplete
brew "playwright-cli"
brew "specify"

# ===== Local LLM =====
brew "ollama"               # local LLM runner; pair with Claude for proprietary work
brew "hf"                   # Hugging Face CLI (formerly huggingface-cli)

# ===== Misc =====
brew "cheat"
brew "cliclick"
brew "fastfetch"
brew "figlet"
brew "lolcat"
brew "oven-sh/bun/bun"
brew "pandoc"
brew "teamookla/speedtest/speedtest"
brew "whisperkit-cli"

# ===== Fonts (nerd fonts for terminals/editors) =====
cask "font-3270-nerd-font"
cask "font-hack-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-liberation-nerd-font"
cask "font-monaspace"

# ===== Terminals / shells =====
cask "ghostty"
cask "warp"
cask "tednaleid/montty/montty"
cask "manaflow-ai/cmux/cmux"

# ===== Cloud CLIs (cask form) =====
cask "1password-cli"

# ===== Editors / IDEs =====
cask "zed"

# ===== Productivity / window mgmt =====
cask "raycast"
cask "keepingyouawake"
cask "moom"
cask "witch"
cask "flashspace"
cask "maccy"
cask "lookaway"
cask "finetune"
cask "handy"  # open-source push-to-talk dictation

# ===== Dev utilities =====
cask "devutils"
cask "entireio/tap/entire"
cask "gitkraken"
cask "detachhead/tap/rebased"  # git client built on the IntelliJ platform
cask "polypane"
cask "postman"
cask "ngrok"
cask "productdevbook/tap/portkiller"
cask "jithin-sabu/tap/purge"  # open-source cache/junk cleaner, trash-by-default (purgemac.com)
cask "sloth"
cask "wave"

# tailscale-app cask is opt-in via Brewfile.tailscale (cask installer
# needs sudo and can't run unattended from bootstrap.sh).

# ===== Notes / 3D =====
cask "obsidian"
cask "blender"

# ===== Data GUIs =====
cask "mongodb-compass"

# ===== Cargo (rust binaries) =====
cargo "cargo-leptos"
cargo "cargo-make"
cargo "leptosfmt"
cargo "linear-cli"
cargo "sqlx-cli"
cargo "trunk"
