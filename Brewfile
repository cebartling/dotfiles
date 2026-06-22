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
tap "manaflow-ai/cmux"
tap "oven-sh/bun"
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
brew "acli"                 # Atlassian CLI (Jira, Confluence, Bitbucket)
brew "gh"                   # GitHub CLI
brew "gitleaks"             # secret scanner
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
brew "xh"                   # faster httpie
brew "sniffnet"
brew "tailscale"

# ===== Containers =====
brew "colima"
brew "podman"
brew "podman-compose"

# ===== Document / image processing =====
# poppler omitted: source build fails on this Homebrew prefix
# (/Users/e9004590/homebrew) because the p11-kit dep times out in
# meson tests. Install ad-hoc when pdftotext/pdftoppm/pdfinfo are needed.
brew "imagemagick"          # convert/resize images (token cost reduction)

# ===== Data =====
brew "duckdb"
brew "mongodb-atlas-cli"
brew "pgcli"                # Postgres CLI with autocomplete
brew "playwright-cli"
brew "specify"

# ===== Local LLM =====
brew "ollama"               # local LLM runner; pair with Claude for proprietary work

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
cask "visual-studio-code"   # required by `vscode "..."` extension lines below
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

# ===== Dev utilities =====
cask "devutils"
cask "gitkraken"
cask "detachhead/tap/rebased"  # git client built on the IntelliJ platform
cask "polypane"
cask "postman"
cask "ngrok"
cask "productdevbook/tap/portkiller"
cask "sloth"
cask "wave"

# tailscale-app cask is opt-in via Brewfile.tailscale (cask installer
# needs sudo and can't run unattended from bootstrap.sh).

# ===== Notes / 3D =====
cask "obsidian"
cask "blender"

# ===== Data GUIs =====
cask "mongodb-compass"

# ===== VS Code extensions =====
vscode "andys8.jest-snippets"
vscode "bierner.color-info"
vscode "bierner.emojisense"
vscode "bradlc.vscode-tailwindcss"
vscode "christian-kohler.path-intellisense"
vscode "davidanson.vscode-markdownlint"
vscode "dbaeumer.vscode-eslint"
vscode "docker.docker"
vscode "donjayamanne.githistory"
vscode "eamodio.gitlens"
vscode "editorconfig.editorconfig"
vscode "eliostruyf.vscode-typescript-exportallmodules"
vscode "esbenp.prettier-vscode"
vscode "figma.figma-vscode-extension"
vscode "firsttris.vscode-jest-runner"
vscode "foxundermoon.shell-format"
vscode "github.copilot-chat"
vscode "github.vscode-github-actions"
vscode "github.vscode-pull-request-github"
vscode "google.geminicodeassist"
vscode "googlecloudtools.cloudcode"
vscode "hbenl.vscode-test-explorer"
vscode "henrynguyen5-vsc.vsc-nvm"
vscode "heybourn.headwind"
vscode "isudox.vscode-jetbrains-keybindings"
vscode "kaleidoscope-app.vscode-ksdiff"
vscode "lucono.karma-test-explorer"
vscode "mdickin.markdown-shortcuts"
vscode "mechatroner.rainbow-csv"
vscode "mindaro-dev.file-downloader"
vscode "mindaro.mindaro"
vscode "ms-azure-devops.azure-pipelines"
vscode "ms-azuretools.vscode-azureresourcegroups"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-playwright.playwright"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode.azure-account"
vscode "ms-vscode.live-server"
vscode "ms-vscode.test-adapter-converter"
vscode "ms-vsliveshare.vsliveshare"
vscode "nrwl.angular-console"
vscode "orta.vscode-jest"
vscode "rapidapi.vscode-rapidapi-client"
vscode "rapidapi.vscode-services"
vscode "redhat.java"
vscode "redhat.vscode-commons"
vscode "redhat.vscode-xml"
vscode "redhat.vscode-yaml"
vscode "tamasfe.even-better-toml"
vscode "visualstudioexptteam.intellicode-api-usage-examples"
vscode "visualstudioexptteam.vscodeintellicode"
vscode "vmware.vscode-boot-dev-pack"
vscode "vmware.vscode-spring-boot"
vscode "vscjava.vscode-gradle"
vscode "vscjava.vscode-java-debug"
vscode "vscjava.vscode-java-dependency"
vscode "vscjava.vscode-java-pack"
vscode "vscjava.vscode-java-test"
vscode "vscjava.vscode-maven"
vscode "vscjava.vscode-spring-boot-dashboard"
vscode "vscjava.vscode-spring-initializr"
vscode "vue.volar"
vscode "webben.browserslist"

# ===== Cargo (rust binaries) =====
cargo "cargo-leptos"
cargo "cargo-make"
cargo "leptosfmt"
cargo "linear-cli"
cargo "sqlx-cli"
cargo "trunk"
