# brew_trust.sh — trust the third-party taps referenced by a Brewfile.
#
# Meant to be SOURCED (from bash or zsh), not executed. Provides one function:
#
#   brew_trust_taps "$DOTFILES/Brewfile.cloud"
#
# Homebrew 6.0+ requires non-official tap formulae, casks and commands to be
# trusted with `brew trust` before it will load them
# (HOMEBREW_REQUIRE_TAP_TRUST, default true). Trust records live in
# ~/.homebrew/trust.json and are NOT synced across machines, so we re-derive
# and re-establish them from the Brewfile on every install run. Deriving the
# tap list from the Brewfile keeps the Brewfile the single source of truth:
# add a tap there and the next install run trusts it automatically — no
# second list to keep in sync.

# Trust every third-party tap referenced by the given Brewfile.
brew_trust_taps() {
  brewfile="$1"
  [ -f "$brewfile" ] || return 0

  # Pull tap names (owner/repo) from `tap`, fully-qualified `brew`, and `cask`
  # lines. Official single-segment names (e.g. brew "awscli") have no slash and
  # are skipped — those resolve to homebrew/core / homebrew/cask, always trusted.
  grep -E '^[[:space:]]*(tap|brew|cask)[[:space:]]+"' "$brewfile" \
    | sed -E 's/^[[:space:]]*(tap|brew|cask)[[:space:]]+"([^"]+)".*/\2/' \
    | awk -F/ 'NF >= 2 { print $1 "/" $2 }' \
    | sort -u \
    | while IFS= read -r tap; do
        [ -n "$tap" ] && brew trust --tap "$tap"
      done
}
