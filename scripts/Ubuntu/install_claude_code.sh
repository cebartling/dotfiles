#!/usr/bin/env bash
# install_claude_code.sh — the Claude Code CLI on Ubuntu.
#
#   ~/.dotfiles/scripts/Ubuntu/install_claude_code.sh            # stable
#   ~/.dotfiles/scripts/Ubuntu/install_claude_code.sh latest     # or a version
#   ~/.dotfiles/scripts/Ubuntu/install_claude_code.sh --force    # reinstall
#
# Opt-in and NOT wired into bootstrap.sh, like install_chrome.sh and
# install_tailscale.sh. Unlike those two it needs no sudo at all: everything
# lands under $HOME.
#
# Do not confuse this with ai-tools/claude-code/install.sh. That one symlinks
# the *configuration* (skills, hooks, commands, settings) into ~/.claude. This
# one installs the binary those settings configure. They are independent, and
# this script points at the other one when it finishes.
#
# This wraps Anthropic's own installer rather than reimplementing it. That
# installer resolves the current version, downloads the matching build, and
# verifies it against a SHA256 manifest before running anything — it also
# distinguishes musl from glibc and x64 from arm64, which is exactly the
# platform detection we would otherwise have to duplicate and keep correct.
#
# Two things it does not do for us, which is why there is a wrapper at all:
#
#   1. ~/.zshrc is a symlink into this repo, so an installer that appends a
#      PATH line is editing tracked source. It only has reason to do that when
#      ~/.local/bin is missing from PATH, so we put it there first and then
#      verify the tracked zshrc is byte-identical afterwards. See the
#      "Beware installers that write to shell profiles" note in CLAUDE.md.
#
#   2. The install needs roughly 512MB free. The official script diagnoses
#      that only after the kernel OOM killer has already killed it (exit 137),
#      so we check MemAvailable up front and say so before wasting a download.
#
# It is fetched to a file and checked before it is run, rather than piped
# straight into bash — the same reflex as install_chrome.sh validating that the
# Google signing key really is a PGP block before installing it.

set -euo pipefail

INSTALLER_URL="https://claude.ai/install.sh"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
TRACKED_ZSHRC="$DOTFILES/zshrc"
# The official installer wants ~512MB; warn a little above that so a box that
# only just clears the bar is still flagged before the download.
MIN_AVAIL_MB=600

TARGET=""
FORCE=0
SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
usage: install_claude_code.sh [--force] [stable|latest|VERSION]

  --force        reinstall even if claude is already present
  stable         the default channel if no target is given
  latest         the newest build, including pre-releases
  X.Y.Z          a specific version, e.g. 2.1.263
USAGE
}

while (( $# )); do
  case "$1" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    stable|latest) TARGET="$1" ;;
    [0-9]*.[0-9]*.[0-9]*) TARGET="$1" ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$(uname -s)" == "Linux" ]] || die "this is the Ubuntu installer; on macOS Claude Code comes from the same upstream script, run it directly"

# The installer refuses sudo itself, but it does so after the download. Catch it
# here, where the message can name this script.
if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  die "do not run this under sudo — Claude Code installs into \$HOME, and under sudo that is root's home. Re-run as yourself."
fi

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

# curl or wget: the upstream installer needs one of them and checks for itself,
# but it cannot install one, and a minimal Ubuntu image ships neither.
require_downloader() {
  command -v curl >/dev/null 2>&1 && { DL=curl; return 0; }
  command -v wget >/dev/null 2>&1 && { DL=wget; return 0; }
  die "neither curl nor wget is installed. Install one first: sudo apt-get install -y curl"
}

# jq and zstd are both optional upstream — without them the installer falls back
# to a bash JSON parser and an uncompressed download. Worth saying, not worth
# demanding sudo for.
note_optional_tools() {
  local missing=()
  command -v jq   >/dev/null 2>&1 || missing+=(jq)
  command -v zstd >/dev/null 2>&1 || missing+=(zstd)
  (( ${#missing[@]} )) || return 0
  say "Optional tools absent: ${missing[*]} — the download will be larger and slower, but correct."
  say "  sudo apt-get install -y ${missing[*]}"
}

# The kernel OOM killer takes the install out at exit 137 on a small box. Cheaper
# to say so now than after the download.
check_memory() {
  local avail_kb avail_mb
  avail_kb="$(awk '/^MemAvailable:/{print $2; exit}' /proc/meminfo 2>/dev/null || true)"
  [[ -n "$avail_kb" ]] || return 0
  avail_mb=$(( avail_kb / 1024 ))
  if (( avail_mb < MIN_AVAIL_MB )); then
    warn "only ${avail_mb}MB of memory is available; the install needs roughly 512MB and the kernel will kill it (exit 137) if it runs short."
    warn "Free some memory, or accept that this may fail."
    SKIPPED+=("low memory (${avail_mb}MB)")
  fi
}

# ---------------------------------------------------------------------------
# The tracked-zshrc guard
# ---------------------------------------------------------------------------
#
# `claude install` sets up a launcher and "shell integration". On this repo's
# machines ~/.local/bin is already on PATH from zshrc, so it has nothing to add
# and touches no profile — but that is an observation, not a guarantee, and the
# cost of being wrong is a silent edit to tracked source.

zshrc_hash() {
  [[ -f "$TRACKED_ZSHRC" ]] || { printf 'absent\n'; return 0; }
  sha256sum "$TRACKED_ZSHRC" | cut -d' ' -f1
}

# Give the installer no reason to edit anything: if ~/.local/bin is missing from
# PATH for this process, add it before invoking.
ensure_local_bin_on_path() {
  mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) return 0 ;;
  esac
  say "Adding ~/.local/bin to PATH for this run (zshrc already does it for real shells)"
  export PATH="$HOME/.local/bin:$PATH"
}

report_zshrc_change() {
  local before="$1" after
  after="$(zshrc_hash)"
  [[ "$before" == "$after" ]] && return 0

  warn "The installer modified $TRACKED_ZSHRC — that file is tracked in this repo and symlinked to ~/.zshrc."
  if command -v git >/dev/null 2>&1 && git -C "$DOTFILES" rev-parse >/dev/null 2>&1; then
    echo
    git -C "$DOTFILES" --no-pager diff -- zshrc || true
    echo
    warn "Review the diff above. To discard it:  git -C $DOTFILES checkout -- zshrc"
  fi
  SKIPPED+=("zshrc was modified")
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

already_installed() {
  command -v claude >/dev/null 2>&1
}

run_installer() {
  local tmp script
  tmp="$(mktemp -d)"
  script="$tmp/install.sh"

  say "Fetching the installer from $INSTALLER_URL"
  if [[ "$DL" == curl ]]; then
    curl -fsSL -o "$script" "$INSTALLER_URL" || { rm -rf "$tmp"; die "could not download the installer from $INSTALLER_URL"; }
  else
    wget -q -O "$script" "$INSTALLER_URL" || { rm -rf "$tmp"; die "could not download the installer from $INSTALLER_URL"; }
  fi

  # Fetched to a file and checked before running, rather than piped into bash:
  # a captive portal or an error page would otherwise be executed.
  head -1 "$script" | grep -q '^#!/bin/bash' \
    || { rm -rf "$tmp"; die "what came back from $INSTALLER_URL is not a bash script; refusing to run it"; }

  say "Installing Claude Code${TARGET:+ ($TARGET)}"
  # The installer verifies its own download against a SHA256 manifest.
  bash "$script" ${TARGET:+"$TARGET"} || { rm -rf "$tmp"; die "the upstream installer failed; nothing was changed by this script"; }
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying"
  if command -v claude >/dev/null 2>&1; then
    printf '  \033[32mok\033[0m      claude -> %s\n' "$(command -v claude)"
    printf '  \033[32mok\033[0m      version %s\n' "$(claude --version 2>/dev/null | head -1)"
  else
    printf '  \033[31mmissing\033[0m claude is not on $PATH\n'
    warn "The binary installs to ~/.local/bin. zshrc puts that on PATH, so a new shell should find it."
  fi

  (( ${#SKIPPED[@]} )) && { echo; warn "attention: ${SKIPPED[*]}"; }

  echo
  say "Next: link the Claude Code configuration (skills, hooks, commands, settings)"
  echo "    bash $DOTFILES/ai-tools/claude-code/install.sh"
  echo
  say "Updates are handled by Claude Code itself, not apt:"
  echo "    claude update"
}

main() {
  require_downloader

  if already_installed && (( ! FORCE )); then
    say "Claude Code already installed: $(claude --version 2>/dev/null | head -1) at $(command -v claude)"
    say "Use 'claude update' to upgrade, or re-run with --force to reinstall."
    print_summary
    return 0
  fi

  note_optional_tools
  check_memory
  ensure_local_bin_on_path

  local before
  before="$(zshrc_hash)"
  run_installer
  report_zshrc_change "$before"

  print_summary
}

main "$@"
