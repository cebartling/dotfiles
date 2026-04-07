# Tracked Homebrew Packages

This file documents every package tracked in [`Brewfile`](Brewfile) and
[`Brewfile.k8s`](Brewfile.k8s). It's hand-maintained — when you add or
remove a package, update the table here too. The single source of truth
for *what gets installed* is still the Brewfile; this document is just a
human-readable reference for *why* each thing is on the list.

To install everything: `brew bundle --file=$DOTFILES/Brewfile`
To check drift:        `brew bundle check --file=$DOTFILES/Brewfile`

---

## Brewfile

### Taps

| Tap | Purpose |
|---|---|
| [`azure/azd`](https://github.com/Azure/azure-dev) | Azure Developer CLI distribution |
| [`derailed/k9s`](https://github.com/derailed/homebrew-k9s) | k9s Kubernetes TUI distribution |
| [`hashicorp/tap`](https://github.com/hashicorp/homebrew-tap) | Hashicorp tools (Terraform, Vault) |
| [`heroku/brew`](https://github.com/heroku/homebrew-brew) | Heroku CLI distribution |
| [`manaflow-ai/cmux`](https://github.com/manaflow-ai/homebrew-cmux) | cmux terminal cask |
| [`oven-sh/bun`](https://github.com/oven-sh/homebrew-bun) | Bun JavaScript runtime |
| [`productdevbook/tap`](https://github.com/productdevbook/homebrew-tap) | portkiller and related tools |
| [`steveyegge/beads`](https://github.com/steveyegge/homebrew-beads) | bd issue tracker |
| [`teamookla/speedtest`](https://www.speedtest.net/apps/cli) | Ookla speedtest CLI |
| [`tednaleid/montty`](https://github.com/tednaleid/montty) | montty terminal cask |

### Core CLI

| Package | Description | Source |
|---|---|---|
| `bash` | GNU Bourne-Again SHell — newer than the macOS-shipped 3.2 | [gnu.org/software/bash](https://www.gnu.org/software/bash/) |
| `curl` | Command-line HTTP/FTP/etc client; brew version is newer than system curl | [github.com/curl/curl](https://github.com/curl/curl) |
| `git` | Distributed version control system | [github.com/git/git](https://github.com/git/git) |
| `openssl@3` | TLS/SSL/crypto toolkit; many other formulas depend on it | [github.com/openssl/openssl](https://github.com/openssl/openssl) |
| `tmux` | Terminal multiplexer (windows, panes, detachable sessions) | [github.com/tmux/tmux](https://github.com/tmux/tmux) |

### Modern CLI replacements

| Package | Description | Source |
|---|---|---|
| `bat` | `cat` clone with syntax highlighting and Git integration | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| `eza` | Modern, maintained `ls` replacement (was `exa`) | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| `fd` | Simple, fast user-friendly alternative to `find` | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| `ripgrep` | Recursive grep that respects `.gitignore`; very fast | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| `dust` | More intuitive `du` written in Rust | [github.com/bootandy/dust](https://github.com/bootandy/dust) |
| `procs` | Modern replacement for `ps` written in Rust | [github.com/dalance/procs](https://github.com/dalance/procs) |
| `fzf` | Command-line fuzzy finder; powers `Ctrl-R` history search | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| `tree` | Recursive directory listing as a tree diagram | [oldmanprogrammer.net](https://oldmanprogrammer.net/source.php?dir=projects/tree) |
| `zoxide` | Smarter `cd` that learns from frecency; jump with `z <name>` | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| `git-delta` | Syntax-highlighting pager for `git` and `diff` output | [github.com/dandavison/delta](https://github.com/dandavison/delta) |
| `difftastic` | AST-aware structural diff that ignores formatting noise | [github.com/Wilfred/difftastic](https://github.com/Wilfred/difftastic) |
| `starship` | Minimal, blazing-fast cross-shell prompt | [github.com/starship/starship](https://github.com/starship/starship) |
| `zsh-autosuggestions` | Fish-like history-based autosuggestions for zsh | [github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) |
| `zsh-syntax-highlighting` | Live syntax highlighting for zsh commands as you type | [github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |

### Dev tooling

| Package | Description | Source |
|---|---|---|
| `ast-grep` | Structural code search/replace using AST patterns; CLI is `sg` | [github.com/ast-grep/ast-grep](https://github.com/ast-grep/ast-grep) |
| `atuin` | Magical shell history with full-text search and optional sync | [github.com/atuinsh/atuin](https://github.com/atuinsh/atuin) |
| `beads` | `bd` — issue tracker with first-class dependency support | [github.com/steveyegge/beads](https://github.com/steveyegge/beads) |
| `cargo-binstall` | Install Rust binaries from prebuilt artifacts (no compile) | [github.com/cargo-bins/cargo-binstall](https://github.com/cargo-bins/cargo-binstall) |
| `direnv` | Per-directory environment variables via `.envrc` files | [github.com/direnv/direnv](https://github.com/direnv/direnv) |
| `gh` | Official GitHub CLI (PRs, issues, releases, gists) | [github.com/cli/cli](https://github.com/cli/cli) |
| `gitleaks` | Specialized scanner for accidentally-committed secrets | [github.com/gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) |
| `glow` | Terminal Markdown renderer with style themes | [github.com/charmbracelet/glow](https://github.com/charmbracelet/glow) |
| `hyperfine` | Statistical command-line benchmarking tool | [github.com/sharkdp/hyperfine](https://github.com/sharkdp/hyperfine) |
| `jq` | Lightweight and flexible JSON processor | [github.com/jqlang/jq](https://github.com/jqlang/jq) |
| `yq` | YAML processor with `jq`-like syntax (Mike Farah's Go version) | [github.com/mikefarah/yq](https://github.com/mikefarah/yq) |
| `fx` | Interactive JSON viewer/explorer for the terminal | [github.com/antonmedv/fx](https://github.com/antonmedv/fx) |
| `just` | Handy command runner; modern Make alternative | [github.com/casey/just](https://github.com/casey/just) |
| `lazygit` | TUI for git: stage hunks, amend, rebase, view diffs | [github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| `miller` | `mlr` — like awk/sed/cut/jq for CSV, TSV, JSON tabular data | [github.com/johnkerl/miller](https://github.com/johnkerl/miller) |
| `pre-commit` | Framework for managing multi-language pre-commit git hooks | [github.com/pre-commit/pre-commit](https://github.com/pre-commit/pre-commit) |
| `semgrep` | Lightweight static analysis for many languages | [github.com/semgrep/semgrep](https://github.com/semgrep/semgrep) |
| `tokei` | Fast, accurate code statistics (lines, files, languages) | [github.com/XAMPPRocky/tokei](https://github.com/XAMPPRocky/tokei) |
| `typescript-language-server` | LSP server for TypeScript wrapping `tsserver` | [github.com/typescript-language-server/typescript-language-server](https://github.com/typescript-language-server/typescript-language-server) |
| `vale` | Syntax-aware linter for prose (markdown, asciidoc, etc.) | [github.com/errata-ai/vale](https://github.com/errata-ai/vale) |
| `watchexec` | Execute commands when watched files change | [github.com/watchexec/watchexec](https://github.com/watchexec/watchexec) |
| `xcodegen` | Generate Xcode projects from a YAML spec and folder structure | [github.com/yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen) |

### Runtimes / package managers

| Package | Description | Source |
|---|---|---|
| `nvm` | Node version manager (lazy-loaded by `zshrc`) | [github.com/nvm-sh/nvm](https://github.com/nvm-sh/nvm) |
| `poetry` | Python dependency management and packaging | [github.com/python-poetry/poetry](https://github.com/python-poetry/poetry) |
| `uv` | Extremely fast Python installer/resolver written in Rust | [github.com/astral-sh/uv](https://github.com/astral-sh/uv) |

### HTTP / network

| Package | Description | Source |
|---|---|---|
| `caddy` | Powerful, enterprise-ready web server with automatic HTTPS | [github.com/caddyserver/caddy](https://github.com/caddyserver/caddy) |
| `dnsmasq` | Lightweight DNS forwarder and DHCP server | [thekelleys.org.uk/dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html) |
| `dog` | Modern, colorful command-line DNS client | [github.com/ogham/dog](https://github.com/ogham/dog) |
| `grpcurl` | Like `curl` but for gRPC services | [github.com/fullstorydev/grpcurl](https://github.com/fullstorydev/grpcurl) |
| `httpie` | User-friendly HTTP client (`http`, `https` commands) | [github.com/httpie/cli](https://github.com/httpie/cli) |
| `xh` | Friendly and fast HTTP client; faster httpie clone in Rust | [github.com/ducaale/xh](https://github.com/ducaale/xh) |
| `sniffnet` | Cross-platform application to monitor network traffic | [github.com/GyulyVGC/sniffnet](https://github.com/GyulyVGC/sniffnet) |
| `tailscale` | Tailscale CLI (the daemon side; GUI is the cask) | [github.com/tailscale/tailscale](https://github.com/tailscale/tailscale) |

### Containers

| Package | Description | Source |
|---|---|---|
| `colima` | Container runtimes on macOS with minimal setup (Docker, Containerd) | [github.com/abiosoft/colima](https://github.com/abiosoft/colima) |
| `podman` | Daemonless container engine compatible with Docker | [github.com/containers/podman](https://github.com/containers/podman) |

### Cloud CLIs

| Package | Description | Source |
|---|---|---|
| `awscli` | Official Amazon AWS command-line interface | [github.com/aws/aws-cli](https://github.com/aws/aws-cli) |
| `awslogs` | Simple tool to read AWS CloudWatch logs from the terminal | [github.com/jorgebastida/awslogs](https://github.com/jorgebastida/awslogs) |
| `azure-cli` | Microsoft Azure CLI | [github.com/Azure/azure-cli](https://github.com/Azure/azure-cli) |
| `doctl` | DigitalOcean command-line tool | [github.com/digitalocean/doctl](https://github.com/digitalocean/doctl) |
| `heroku/brew/heroku` | Heroku CLI | [github.com/heroku/cli](https://github.com/heroku/cli) |

### Hashicorp

| Package | Description | Source |
|---|---|---|
| `hashicorp/tap/terraform` | Infrastructure as code | [github.com/hashicorp/terraform](https://github.com/hashicorp/terraform) |
| `hashicorp/tap/vault` | Secrets management and encryption | [github.com/hashicorp/vault](https://github.com/hashicorp/vault) |

### Document / image processing

| Package | Description | Source |
|---|---|---|
| `poppler` | PDF rendering library; provides `pdftotext`, `pdftoppm`, `pdfinfo` | [poppler.freedesktop.org](https://gitlab.freedesktop.org/poppler/poppler) |
| `imagemagick` | Image creation, conversion, and manipulation toolkit | [github.com/ImageMagick/ImageMagick](https://github.com/ImageMagick/ImageMagick) |

### Data

| Package | Description | Source |
|---|---|---|
| `duckdb` | Embeddable in-process SQL OLAP database | [github.com/duckdb/duckdb](https://github.com/duckdb/duckdb) |
| `mongodb-atlas-cli` | CLI to manage MongoDB Atlas clusters | [github.com/mongodb/mongodb-atlas-cli](https://github.com/mongodb/mongodb-atlas-cli) |
| `pgcli` | Postgres CLI with autocompletion and syntax highlighting | [github.com/dbcli/pgcli](https://github.com/dbcli/pgcli) |
| `playwright-cli` | Playwright record/codegen, selector inspection, screenshots | [github.com/microsoft/playwright](https://github.com/microsoft/playwright) |
| `specify` | GitHub's toolkit for Spec-Driven Development | [github.com/github/spec-kit](https://github.com/github/spec-kit) |

### Local LLM

| Package | Description | Source |
|---|---|---|
| `ollama` | Run large language models locally; exposes localhost API on port 11434 | [github.com/ollama/ollama](https://github.com/ollama/ollama) |

### Misc

| Package | Description | Source |
|---|---|---|
| `azure/azd/azd` | Azure Developer CLI; opinionated app templates and deploy workflows | [github.com/Azure/azure-dev](https://github.com/Azure/azure-dev) |
| `cheat` | Create and view interactive cheat sheets for *nix commands | [github.com/cheat/cheat](https://github.com/cheat/cheat) |
| `cliclick` | Emulate mouse and keyboard events from the command line | [github.com/BlueM/cliclick](https://github.com/BlueM/cliclick) |
| `fastfetch` | System info / neofetch successor written in C | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| `figlet` | Print ASCII-art banners from text | [figlet.org](http://www.figlet.org/) |
| `lolcat` | Pipe text through this for rainbows and unicorns | [github.com/busyloop/lolcat](https://github.com/busyloop/lolcat) |
| `oven-sh/bun/bun` | Incredibly fast JavaScript runtime, bundler, transpiler, package manager | [github.com/oven-sh/bun](https://github.com/oven-sh/bun) |
| `pandoc` | Universal document converter (Markdown ↔ LaTeX ↔ Word ↔ HTML ↔ …) | [github.com/jgm/pandoc](https://github.com/jgm/pandoc) |
| `teamookla/speedtest/speedtest` | Ookla Speedtest CLI for measuring internet bandwidth | [speedtest.net/apps/cli](https://www.speedtest.net/apps/cli) |
| `whisperkit-cli` | On-device speech recognition with Whisper, optimized for Apple Silicon | [github.com/argmaxinc/WhisperKit](https://github.com/argmaxinc/WhisperKit) |

---

### Casks

#### Fonts (nerd fonts for terminals/editors)

All four nerd fonts are patched versions distributed by the
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) project. `monaspace`
is GitHub's superfamily, separately maintained.

| Cask | Description | Source |
|---|---|---|
| `font-3270-nerd-font` | Patched IBM 3270 mainframe font with Nerd Font glyphs | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| `font-hack-nerd-font` | Patched Hack monospace font with Nerd Font glyphs | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| `font-jetbrains-mono-nerd-font` | Patched JetBrains Mono with Nerd Font glyphs | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| `font-liberation-nerd-font` | Patched Liberation Mono with Nerd Font glyphs | [github.com/ryanoasis/nerd-fonts](https://github.com/ryanoasis/nerd-fonts) |
| `font-monaspace` | GitHub's Monaspace coding font superfamily | [github.com/githubnext/monaspace](https://github.com/githubnext/monaspace) |

#### Terminals / shells

| Cask | Description | Source |
|---|---|---|
| `ghostty` | Terminal emulator using platform-native UI and GPU acceleration | [github.com/ghostty-org/ghostty](https://github.com/ghostty-org/ghostty) |
| `warp` | Rust-based terminal with AI command suggestions | [warp.dev](https://www.warp.dev/) (proprietary) |
| `tednaleid/montty/montty` | macOS terminal app with vertical tabs, splits, session persistence | [github.com/tednaleid/montty](https://github.com/tednaleid/montty) |
| `manaflow-ai/cmux/cmux` | Ghostty-based terminal with vertical tabs and notifications for AI agents | [github.com/manaflow-ai/cmux](https://github.com/manaflow-ai/cmux) |

#### Cloud CLIs (cask form)

| Cask | Description | Source |
|---|---|---|
| `1password-cli` | Command-line interface for 1Password (signed installer) | [1password.com/downloads/command-line](https://1password.com/downloads/command-line) (proprietary) |

#### AI / coding agents

| Cask | Description | Source |
|---|---|---|
| `claude` | Anthropic's Claude desktop app | [claude.com](https://claude.com/) (proprietary) |
| `claude-code` | Anthropic's Claude Code agentic CLI/IDE integrations | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| `chatgpt` | OpenAI ChatGPT desktop app | [openai.com/chatgpt/desktop](https://openai.com/chatgpt/desktop/) (proprietary) |
| `copilot-cli` | Brings GitHub Copilot coding agent to the terminal | [github.com/github/copilot-cli](https://github.com/github/copilot-cli) |

#### Editors / IDEs

| Cask | Description | Source |
|---|---|---|
| `zed` | High-performance multiplayer code editor written in Rust | [github.com/zed-industries/zed](https://github.com/zed-industries/zed) |

#### Productivity / window management

| Cask | Description | Source |
|---|---|---|
| `raycast` | Launcher and keyboard-driven productivity tool | [raycast.com](https://www.raycast.com/) (proprietary) |
| `keepingyouawake` | Menu bar tool that prevents the system from going to sleep | [github.com/newmarcel/KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) |
| `moom` | Window mover/zoomer with custom layouts | [manytricks.com/moom](https://manytricks.com/moom/) (proprietary) |
| `witch` | Window-level switcher (cycle windows of any app) | [manytricks.com/witch](https://manytricks.com/witch/) (proprietary) |
| `flashspace` | Native macOS workspaces / virtual desktops manager | [github.com/wojciech-kulik/FlashSpace](https://github.com/wojciech-kulik/FlashSpace) |
| `maccy` | Lightweight clipboard history manager | [github.com/p0deje/Maccy](https://github.com/p0deje/Maccy) |
| `lookaway` | Eye break / 20-20-20 reminder app | [lookaway.info](https://lookaway.info/) (proprietary) |

#### Dev utilities

| Cask | Description | Source |
|---|---|---|
| `devutils` | All-in-one developer toolbox (JSON formatters, regex tester, etc.) | [devutils.com](https://devutils.com/) (proprietary) |
| `gitkraken` | Cross-platform Git GUI client | [gitkraken.com](https://www.gitkraken.com/) (proprietary) |
| `polypane` | Browser for developers — multiple synchronized viewports | [polypane.app](https://polypane.app/) (proprietary) |
| `postman` | API client for HTTP, GraphQL, gRPC, WebSocket | [postman.com](https://www.postman.com/) (proprietary) |
| `ngrok` | Reverse proxy for exposing localhost over secure tunnels | [ngrok.com](https://ngrok.com/) (proprietary) |
| `productdevbook/tap/portkiller` | Menu bar app to find and kill processes on open ports | [github.com/productdevbook/portkiller](https://github.com/productdevbook/portkiller) |
| `sloth` | GUI for `lsof`; shows open files and sockets per process | [sveinbjorn.org/sloth](https://sveinbjorn.org/sloth) |
| `wave` | Open-source terminal with graphical widgets and AI features | [github.com/wavetermdev/waveterm](https://github.com/wavetermdev/waveterm) |

#### Networking GUI

| Cask | Description | Source |
|---|---|---|
| `tailscale-app` | Tailscale GUI app (mesh VPN over WireGuard) | [github.com/tailscale/tailscale](https://github.com/tailscale/tailscale) |

#### Notes / 3D

| Cask | Description | Source |
|---|---|---|
| `obsidian` | Markdown-based knowledge base / note-taking app | [obsidian.md](https://obsidian.md/) (proprietary) |
| `blender` | Free and open-source 3D creation suite | [github.com/blender/blender](https://github.com/blender/blender) |

#### Data GUIs

| Cask | Description | Source |
|---|---|---|
| `mongodb-compass` | Official GUI for analyzing and querying MongoDB data | [github.com/mongodb-js/compass](https://github.com/mongodb-js/compass) |

---

## Brewfile.k8s

Optional Kubernetes toolchain. Installed separately via
`scripts/macOS/install_k8s_tools.zsh` because not every Mac needs k8s.

### Taps

| Tap | Purpose |
|---|---|
| [`sozercan/kubectl-ai`](https://github.com/sozercan/kubectl-ai) | AI-powered kubectl assistant |
| [`weaveworks/tap`](https://github.com/weaveworks/homebrew-tap) | eksctl and related Weaveworks tools |

### Formulas

| Package | Description | Source |
|---|---|---|
| `helm` | Kubernetes package manager (charts and releases) | [github.com/helm/helm](https://github.com/helm/helm) |
| `kubectl-ai` | Use natural language to interact with Kubernetes via kubectl | [github.com/sozercan/kubectl-ai](https://github.com/sozercan/kubectl-ai) |
| `kubernetes-cli` | `kubectl` — the official Kubernetes command-line client | [github.com/kubernetes/kubernetes](https://github.com/kubernetes/kubernetes) |
| `kubeshark` | API traffic analyzer for Kubernetes; "Wireshark for k8s" | [github.com/kubeshark/kubeshark](https://github.com/kubeshark/kubeshark) |
| `stern` | Multi-pod and container log tailing for Kubernetes | [github.com/stern/stern](https://github.com/stern/stern) |
| `weaveworks/tap/eksctl` | Official CLI for Amazon EKS clusters | [github.com/eksctl-io/eksctl](https://github.com/eksctl-io/eksctl) |

### Casks

| Cask | Description | Source |
|---|---|---|
| `freelens` | Free, community-maintained fork of OpenLens | [github.com/freelensapp/freelens](https://github.com/freelensapp/freelens) |
| `openlens` | Open-source build of the Lens Kubernetes IDE | [github.com/MuhammedKalkan/OpenLens](https://github.com/MuhammedKalkan/OpenLens) |

---

## Other tracked items

The Brewfile also tracks two non-Homebrew toolchains via `brew bundle`:

- **VS Code extensions** (~70 entries under `vscode "..."` lines).
  Installed by `brew bundle` using the `code` CLI. See the Brewfile for
  the canonical list — they're not individually documented here because
  the names are self-descriptive (e.g. `dbaeumer.vscode-eslint`,
  `ms-python.python`).
- **Cargo binaries** (`cargo-leptos`, `cargo-make`, `leptosfmt`,
  `linear-cli`, `sqlx-cli`, `trunk`). Installed via `cargo install`
  triggered by `brew bundle`. The Rust toolchain itself must be present
  separately (e.g., via `rustup`).
