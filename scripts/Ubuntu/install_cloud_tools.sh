#!/usr/bin/env bash
# install_cloud_tools.sh — infrastructure-as-code and secrets tooling on Ubuntu.
#
# The Linux counterpart to scripts/macOS/install_cloud_tools.zsh. Offered by
# install_all.sh, NOT wired into bootstrap.sh, exactly like the macOS version —
# not every machine manages cloud infra.
#
#   ~/.dotfiles/scripts/Ubuntu/install_cloud_tools.sh
#
# Ubuntu packages none of these, and the vendors' install docs want a
# third-party apt repository (apt.releases.hashicorp.com, packages.opentofu.org).
# None is necessary: each is a single static Go binary published upstream, so
# they go into ~/.local/bin with no root and no extra apt sources. Every
# download is SHA256-verified against the release's own checksum file.
#
#   terraform — releases.hashicorp.com. HashiCorp publish NO binaries as GitHub
#   vault       release assets; the version comes from their releases API.
#   tofu      — opentofu/opentofu GitHub release tarball.
#
# The AWS CLI is the exception to "static Go binary": v2 is a bundled Python
# app. apt has it (awscli 2.x) but needs sudo and lags upstream, so it comes from
# AWS's own installer zip instead, relocated with --install-dir/--bin-dir so it
# needs no root: the app goes in ~/.local/aws-cli, `aws` is symlinked into
# ~/.local/bin. AWS publish no checksum file; they sign the zip with GPG, so that
# is verified instead, against a pinned fingerprint (see AWSCLI_FPR).
#
# So far the HashiCorp tools, OpenTofu and awscli from Brewfile.cloud. The other
# provider CLIs are tracked in beads dotfiles-m4i; add them here.

# --- install-all metadata ---
# Read by install_all.sh. Keep this in sync with any new hard
# precondition added below, or install_all will not know about it.
# summary: terraform, opentofu, vault and the AWS CLI into ~/.local/bin
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
  *) die "terraform, tofu, vault and aws are published for amd64 and arm64; got $ARCH" ;;
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

# install_hashicorp <product> — terraform and vault ship identically: a zip
# holding one binary named after the product, plus a SHA256SUMS file.
install_hashicorp() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then say "$name already installed ($("$name" version 2>/dev/null | head -1))"; return 0; fi
  # The zip is the only format HashiCorp publish, and unzip comes from
  # install_tools.sh's APT_BASE. Skip rather than die: tofu needs no unzip.
  command -v unzip >/dev/null 2>&1 || { warn "$name needs unzip; run install_tools.sh first"; SKIPPED+=("$name (no unzip)"); return 0; }
  local ver tmp zip want
  ver="$(curl -fsSL "https://api.releases.hashicorp.com/v1/releases/$name/latest" \
        | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)" || true
  [[ -n "$ver" ]] || { warn "could not resolve $name version"; SKIPPED+=("$name"); return 0; }
  say "Installing $name $ver"
  tmp="$(mktemp -d)"
  zip="${name}_${ver}_linux_${ARCH}.zip"
  if curl -fsSL -o "$tmp/$zip" "https://releases.hashicorp.com/$name/$ver/$zip" \
     && curl -fsSL -o "$tmp/SHA256SUMS" "https://releases.hashicorp.com/$name/$ver/${name}_${ver}_SHA256SUMS"; then
    want="$(sum_for "$tmp/SHA256SUMS" "$zip")"
    [[ -n "$want" ]] || die "no checksum line for $zip"
    verify_sha256 "$tmp/$zip" "$want"
    unzip -qo "$tmp/$zip" "$name" -d "$tmp"
    mkdir -p "$BIN"; install -m 0755 "$tmp/$name" "$BIN/$name"
  else
    warn "$name download failed"; SKIPPED+=("$name")
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

# The AWS CLI Team's release-signing key, copied from
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# It EXPIRES 2027-07-01. An expired key does not break verification (gpg reports
# EXPKEYSIG but still emits VALIDSIG), so expiry itself is silent. What breaks it
# is rotation: once AWS sign releases with a new key, the fingerprint check below
# fails with a clear message — re-copy the block from that page and update
# AWSCLI_FPR. Importing the key proves nothing by itself; the pinned fingerprint
# is what ties the zip to AWS.
AWSCLI_FPR="FB5DB77FD5C118B80511ADA8A6310ACC4672475C"
awscli_pubkey() {
  cat <<'KEY'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF2Cr7UBEADJZHcgusOJl7ENSyumXh85z0TRV0xJorM2B/JL0kHOyigQluUG
ZMLhENaG0bYatdrKP+3H91lvK050pXwnO/R7fB/FSTouki4ciIx5OuLlnJZIxSzx
PqGl0mkxImLNbGWoi6Lto0LYxqHN2iQtzlwTVmq9733zd3XfcXrZ3+LblHAgEt5G
TfNxEKJ8soPLyWmwDH6HWCnjZ/aIQRBTIQ05uVeEoYxSh6wOai7ss/KveoSNBbYz
gbdzoqI2Y8cgH2nbfgp3DSasaLZEdCSsIsK1u05CinE7k2qZ7KgKAUIcT/cR/grk
C6VwsnDU0OUCideXcQ8WeHutqvgZH1JgKDbznoIzeQHJD238GEu+eKhRHcz8/jeG
94zkcgJOz3KbZGYMiTh277Fvj9zzvZsbMBCedV1BTg3TqgvdX4bdkhf5cH+7NtWO
lrFj6UwAsGukBTAOxC0l/dnSmZhJ7Z1KmEWilro/gOrjtOxqRQutlIqG22TaqoPG
fYVN+en3Zwbt97kcgZDwqbuykNt64oZWc4XKCa3mprEGC3IbJTBFqglXmZ7l9ywG
EEUJYOlb2XrSuPWml39beWdKM8kzr1OjnlOm6+lpTRCBfo0wa9F8YZRhHPAkwKkX
XDeOGpWRj4ohOx0d2GWkyV5xyN14p2tQOCdOODmz80yUTgRpPVQUtOEhXQARAQAB
tCFBV1MgQ0xJIFRlYW0gPGF3cy1jbGlAYW1hem9uLmNvbT6JAlQEEwEIAD4CGwMF
CwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQT7Xbd/1cEYuAURraimMQrMRnJHXAUC
akV0ygUJDqP4lQAKCRCmMQrMRnJHXFHjD/9eyZLYcKuQOlLvtqSDtUBiEZf6ZZjM
i3ygYH8rJNtuToUH+HvSpe819urJCquXhDrlK6N+aqW0hCLtNABJG/vsafIgvIYJ
hSGgpgtNnQyMV1jViRWqPjbouw8OkYKBThUfT1i2Y+wn58ifs6ODBCmTexWtXspA
Si+Gt49xDOW0APmbOPnI+a4HJW6tVEo6MWS0WjzpiBayR3d1A4pt4YrPfSdDgpLo
h2SLQqlRqvvVZJaWBjhkErNFpfsBA06sDcPEOb0G8LBUbR4WOcdvhe5LubJbZuxC
AG9kNPCVeQP1ixwjgjXKysaxeQ6rv0VzIQgRp6tLVLWhy6AKDNvLjFSsmXZ1Wl08
Y/RlOHXlzLuQMRE6sR1wOdRxc9TsrNWTGiBK65cvSWOy03JeBkQQ8pesqltiyxI9
U21kkgiXtTSKNGfKK8pO27D81YANhRqPK7iTp6kuFiY2WtOg90KTMNlIT+Ff85Y2
b1rHj6Z0SrCkJujhWk3IBPic/wJgz01LEc/OAdUPlby90RJZcIBhSlWhT7mXnXIO
c0HWlNQrns2s3CTyYwZSiSlYe9ApeLwhjDo8NhbFuCAy61l6O5UsR4AfZxx/rGKv
2wFb1/RN/P4gNe6vmxZAPjR0AQcwD3tc2McimOLr/22kmPz8IH3I0X7WoSFr0Biz
E91G7bb0hOb/cA==
=knv7
-----END PGP PUBLIC KEY BLOCK-----
KEY
}

install_awscli() {
  if command -v aws >/dev/null 2>&1; then say "aws already installed ($(aws --version 2>&1 | head -1))"; return 0; fi
  # Same posture as the HashiCorp zips: unzip and gpg come from install_tools.sh,
  # so skip rather than die when they are missing.
  command -v unzip >/dev/null 2>&1 || { warn "aws needs unzip; run install_tools.sh first"; SKIPPED+=("aws (no unzip)"); return 0; }
  command -v gpg   >/dev/null 2>&1 || { warn "aws needs gpg to verify the download"; SKIPPED+=("aws (no gpg)"); return 0; }
  local arch tmp gh zip base
  # AWS name builds by the kernel's spelling, not Debian's.
  case "$ARCH" in amd64) arch=x86_64 ;; arm64) arch=aarch64 ;; esac
  zip="awscli-exe-linux-${arch}.zip"
  base="https://awscli.amazonaws.com"
  say "Installing aws (AWS CLI v2)"
  tmp="$(mktemp -d)"
  # A throwaway keyring, so the user's own ~/.gnupg is never touched.
  gh="$tmp/gnupg"; mkdir -m 0700 "$gh"
  if curl -fsSL -o "$tmp/$zip" "$base/$zip" && curl -fsSL -o "$tmp/$zip.sig" "$base/$zip.sig"; then
    awscli_pubkey | gpg --homedir "$gh" --batch --quiet --import 2>/dev/null \
      || die "could not import the AWS CLI signing key"
    # Parse the machine-readable status, not the prose. Require a VALIDSIG for
    # exactly the pinned fingerprint: a good signature from any other key is a
    # failure, and so is an expired one (EXPKEYSIG, no VALIDSIG).
    gpg --homedir "$gh" --batch --status-fd 1 --verify "$tmp/$zip.sig" "$tmp/$zip" 2>/dev/null \
      | grep -q "^\[GNUPG:\] VALIDSIG .* $AWSCLI_FPR\$" \
      || die "GPG verification failed for $zip (expected a signature from $AWSCLI_FPR)"
    unzip -q "$tmp/$zip" -d "$tmp"
    mkdir -p "$BIN"
    "$tmp/aws/install" --install-dir "$HOME/.local/aws-cli" --bin-dir "$BIN" >/dev/null
  else
    warn "aws download failed"; SKIPPED+=(aws)
  fi
  gpgconf --homedir "$gh" --kill all 2>/dev/null || true
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying"
  for t in terraform tofu vault aws; do
    if command -v "$t" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$t"
    else printf '  \033[31mmissing\033[0m %s\n' "$t"; fi
  done
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }
  echo
  say "Done. ~/.local/bin is already on \$path via zshrc."
}

main() {
  install_hashicorp terraform
  install_tofu
  install_hashicorp vault
  install_awscli
  print_summary
}

main "$@"
