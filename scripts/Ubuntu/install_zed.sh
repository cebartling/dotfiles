#!/usr/bin/env bash
# install_zed.sh — the Zed editor, via Zed's own installer, into ~/.local.
#
#   scripts/Ubuntu/install_zed.sh
#
# No root, and not via apt: Zed publishes no apt repository. Its official
# installer (https://zed.dev/install.sh) unpacks a tarball to ~/.local/zed.app,
# links ~/.local/bin/zed and copies a .desktop file into
# ~/.local/share/applications. Zed then updates itself in place, so a re-run of
# this script on a box that has it does nothing.
#
# The upstream installer was read before adopting it: it does not append to
# shell profiles — it only prints PATH advice when ~/.local/bin is missing, and
# zshrc already puts ~/.local/bin on $path. Upstream can change, so the tracked
# zshrc is hashed before and after regardless (~/.zshrc is a symlink into this
# repo; see "Beware installers that write to shell profiles" in CLAUDE.md).
#
# link.sh only links the Files right-click "Open with Zed" script once
# ~/.local/bin/zed exists, and bootstrap runs link.sh before any opt-in tool is
# installed — so this re-runs link.sh at the end, the same way
# install_tailscale.sh does for its units.
#
# Installing Zed does not make it $EDITOR over SSH or mosh: zshrc only accepts
# GUI editors on Linux when there is a local display.

# --- install-all metadata ---
# Read by install_all.sh. Keep this in sync with any new hard
# precondition added below, or install_all will not know about it.
# summary: Zed editor via Zed's installer into ~/.local (no root)
# group: opt-in
# wants: link.sh
# sudo: none
# --- end metadata ---

set -euo pipefail

INSTALLER_URL="https://zed.dev/install.sh"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
TRACKED_ZSHRC="$DOTFILES/zshrc"
ZED="$HOME/.local/bin/zed"

SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Everything lands in $HOME. Under sudo that is /root, where nobody would look,
# and nothing here needs privilege.
if (( EUID == 0 )); then
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
    die "do not run this with sudo; it installs into \$HOME. Re-run as $SUDO_USER: $0"
  fi
  die "do not run this as root; it installs into \$HOME. Re-run as your own user."
fi

command -v curl >/dev/null 2>&1 || die "curl is required to fetch $INSTALLER_URL (install_tools.sh installs it)"

zshrc_hash() {
  [[ -f "$TRACKED_ZSHRC" ]] || { printf 'absent\n'; return 0; }
  sha256sum "$TRACKED_ZSHRC" | cut -d' ' -f1
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

run_installer() {
  local tmp script
  tmp="$(mktemp -d)"
  script="$tmp/install.sh"

  say "Fetching the installer from $INSTALLER_URL"
  curl -fsSL -o "$script" "$INSTALLER_URL" \
    || { rm -rf "$tmp"; die "could not download the installer from $INSTALLER_URL"; }

  # Fetched to a file and checked before running, rather than piped into sh:
  # a captive portal or an error page would otherwise be executed.
  head -1 "$script" | grep -q '^#!/usr/bin/env sh' \
    || { rm -rf "$tmp"; die "what came back from $INSTALLER_URL is not a sh script; refusing to run it"; }

  say "Installing Zed into ~/.local"
  sh "$script" || { rm -rf "$tmp"; die "the upstream installer failed"; }
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying"
  if [[ -x "$ZED" ]]; then
    printf '  \033[32mok\033[0m      zed -> %s\n' "$ZED"
    printf '  \033[32mok\033[0m      version %s\n' "$("$ZED" --version 2>/dev/null | head -1)"
  else
    printf '  \033[31mmissing\033[0m %s\n' "$ZED"
  fi
  (( ${#SKIPPED[@]} )) && { echo; warn "attention: ${SKIPPED[*]}"; }
  echo
  say "Updates are handled by Zed itself."
}

main() {
  if [[ -x "$ZED" ]]; then
    say "Zed already installed: $("$ZED" --version 2>/dev/null | head -1). Zed updates itself."
  else
    local before
    before="$(zshrc_hash)"
    run_installer
    report_zshrc_change "$before"
  fi

  # Idempotent; links the Files "Open with Zed" script now that zed exists.
  say "Linking the Files right-click entry"
  "$DOTFILES/scripts/Ubuntu/link.sh" >/dev/null \
    || { warn "link.sh failed; the 'Open with Zed' entry may be missing"; SKIPPED+=("link.sh"); }

  print_summary
}

main "$@"
