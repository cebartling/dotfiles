#!/usr/bin/env bash
# install_cloud_tools.sh — infrastructure-as-code tooling on Ubuntu.
#
# The Linux counterpart to scripts/macOS/install_cloud_tools.zsh. Offered by
# install_all.sh, NOT wired into bootstrap.sh, exactly like the macOS version —
# not every machine manages cloud infra.
#
#   ~/.dotfiles/scripts/Ubuntu/install_cloud_tools.sh
#
# Ubuntu packages neither tool, and both vendors' install docs want a
# third-party apt repository (apt.releases.hashicorp.com, packages.opentofu.org).
# Neither is necessary: each is a single static Go binary published upstream, so
# they go into ~/.local/bin with no root and no extra apt sources. Every
# download is SHA256-verified against the release's own checksum file.
#
#   terraform — releases.hashicorp.com. HashiCorp publish NO binaries as GitHub
#               release assets; the version comes from their releases API.
#   tofu      — opentofu/opentofu GitHub release tarball.
#
# So far only the infrastructure-as-code pair from Brewfile.cloud. The provider
# CLIs and vault are tracked in beads dotfiles-m4i; add them here.

# --- install-all metadata ---
# Read by install_all.sh. Keep this in sync with any new hard
# precondition added below, or install_all will not know about it.
# summary: terraform and opentofu into ~/.local/bin
# group: opt-in
# wants: install_tools.sh link.sh
# sudo: none
# --- end metadata ---

set -euo pipefail

BIN="$HOME/.local/bin"
SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Both vendors name their builds by Debian architecture, so dpkg gives the
# answer directly — no uname -m mapping.
ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64|arm64) ;;
  *) die "terraform and tofu are published for amd64 and arm64; got $ARCH" ;;
esac

# verify_sha256 <file> <expected-hex>
verify_sha256() {
  local file="$1" want="$2" got
  got="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$got" == "$want" ]] || die "checksum mismatch for $(basename "$file")
  expected: $want
  got:      $got"
}

# sum_for <checksums-file> <filename> — the hex digest listed for filename.
sum_for() { awk -v f="$2" '$2 == f {print $1; exit}' "$1"; }

install_terraform() {
  if command -v terraform >/dev/null 2>&1; then say "terraform already installed ($(terraform version 2>/dev/null | head -1))"; return 0; fi
  # The zip is the only format HashiCorp publish, and unzip comes from
  # install_tools.sh's APT_BASE. Skip rather than die: tofu needs no unzip.
  command -v unzip >/dev/null 2>&1 || { warn "terraform needs unzip; run install_tools.sh first"; SKIPPED+=("terraform (no unzip)"); return 0; }
  local ver tmp zip want
  ver="$(curl -fsSL https://api.releases.hashicorp.com/v1/releases/terraform/latest \
        | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)" || true
  [[ -n "$ver" ]] || { warn "could not resolve terraform version"; SKIPPED+=(terraform); return 0; }
  say "Installing terraform $ver"
  tmp="$(mktemp -d)"
  zip="terraform_${ver}_linux_${ARCH}.zip"
  if curl -fsSL -o "$tmp/$zip" "https://releases.hashicorp.com/terraform/$ver/$zip" \
     && curl -fsSL -o "$tmp/SHA256SUMS" "https://releases.hashicorp.com/terraform/$ver/terraform_${ver}_SHA256SUMS"; then
    want="$(sum_for "$tmp/SHA256SUMS" "$zip")"
    [[ -n "$want" ]] || die "no checksum line for $zip"
    verify_sha256 "$tmp/$zip" "$want"
    unzip -qo "$tmp/$zip" terraform -d "$tmp"
    mkdir -p "$BIN"; install -m 0755 "$tmp/terraform" "$BIN/terraform"
  else
    warn "terraform download failed"; SKIPPED+=(terraform)
  fi
  rm -rf "$tmp"
}

install_tofu() {
  if command -v tofu >/dev/null 2>&1; then say "tofu already installed ($(tofu version 2>/dev/null | head -1))"; return 0; fi
  local tag ver tmp tgz base want
  tag="$(curl -fsSL https://api.github.com/repos/opentofu/opentofu/releases/latest \
        | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)" || true
  [[ -n "$tag" ]] || { warn "could not resolve tofu version"; SKIPPED+=(tofu); return 0; }
  # Tags carry a leading v; asset names do not.
  ver="${tag#v}"
  say "Installing tofu $ver"
  tmp="$(mktemp -d)"
  tgz="tofu_${ver}_linux_${ARCH}.tar.gz"
  base="https://github.com/opentofu/opentofu/releases/download/$tag"
  if curl -fsSL -o "$tmp/$tgz" "$base/$tgz" \
     && curl -fsSL -o "$tmp/SHA256SUMS" "$base/tofu_${ver}_SHA256SUMS"; then
    want="$(sum_for "$tmp/SHA256SUMS" "$tgz")"
    [[ -n "$want" ]] || die "no checksum line for $tgz"
    verify_sha256 "$tmp/$tgz" "$want"
    tar -xzf "$tmp/$tgz" -C "$tmp" tofu
    mkdir -p "$BIN"; install -m 0755 "$tmp/tofu" "$BIN/tofu"
  else
    warn "tofu download failed"; SKIPPED+=(tofu)
  fi
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying"
  for t in terraform tofu; do
    if command -v "$t" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$t"
    else printf '  \033[31mmissing\033[0m %s\n' "$t"; fi
  done
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }
  echo
  say "Done. ~/.local/bin is already on \$path via zshrc."
}

main() {
  install_terraform
  install_tofu
  print_summary
}

main "$@"
