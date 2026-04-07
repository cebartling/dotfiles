# Brewfile — canonical macOS package manifest for cebartling/dotfiles.
# Apply with:  brew bundle --file=$DOTFILES/Brewfile
# Check drift: brew bundle check --file=$DOTFILES/Brewfile
#
# Kubernetes-specific tools live in Brewfile.k8s and are installed
# separately via scripts/macOS/install_k8s_tools.zsh.

# ===== Taps =====
tap "azure/azd"
tap "derailed/k9s"
tap "hashicorp/tap"
tap "heroku/brew"
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
brew "openssl@3"
brew "tmux"

# ===== Modern CLI replacements =====
brew "bat"                  # cat with syntax highlighting
brew "eza"                  # ls replacement
brew "fd"                   # find replacement
brew "ripgrep"              # grep replacement
brew "dust"                 # du replacement
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
brew "beads"                # bd issue tracker
brew "cargo-binstall"
brew "direnv"
brew "gh"                   # GitHub CLI
brew "hyperfine"
brew "jq"
brew "yq"                   # YAML query (jq for YAML)
brew "fx"                   # interactive JSON viewer
brew "just"
brew "lazygit"              # TUI git client
brew "pre-commit"
brew "semgrep"
brew "typescript-language-server"
brew "vale"
brew "watchexec"
brew "xcodegen"

# ===== Runtimes / package managers =====
brew "nvm"                  # lazy-loaded in zshrc
brew "poetry"
brew "uv"

# ===== HTTP / network =====
brew "caddy"
brew "dnsmasq"
brew "dog"                  # DNS client
brew "httpie"
brew "xh"                   # faster httpie
brew "sniffnet"
brew "tailscale"

# ===== Containers =====
brew "colima"
brew "podman"

# ===== Cloud CLIs =====
brew "awscli"
brew "awslogs"
brew "azure-cli"
brew "doctl"
brew "heroku/brew/heroku"

# ===== Hashicorp =====
brew "hashicorp/tap/terraform"
brew "hashicorp/tap/vault"

# ===== Data =====
brew "duckdb"
brew "mongodb-atlas-cli"
brew "playwright-cli"
brew "specify"

# ===== Misc =====
brew "azure/azd/azd"
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

# ===== AI / coding agents =====
cask "claude"
cask "claude-code"
cask "chatgpt"
cask "copilot-cli"

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

# ===== Dev utilities =====
cask "devutils"
cask "gitkraken"
cask "polypane"
cask "postman"
cask "ngrok"
cask "productdevbook/tap/portkiller"
cask "sloth"
cask "wave"

# ===== Networking GUI =====
cask "tailscale-app"

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
