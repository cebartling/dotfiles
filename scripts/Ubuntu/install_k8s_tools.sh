#!/usr/bin/env bash
# install_k8s_tools.sh — Kubernetes tooling on Ubuntu.
#
# The Linux counterpart to scripts/macOS/install_k8s_tools.zsh. Opt-in and NOT
# wired into bootstrap.sh, exactly like the macOS version — not every machine
# needs k8s.
#
#   ~/.dotfiles/scripts/Ubuntu/install_k8s_tools.sh
#
# Ubuntu packages none of this, and the vendors' install docs all want you to
# add third-party apt repositories (pkgs.k8s.io, baltocdn, …). None of that is
# necessary: every CLI here is a static Go binary published upstream, so they
# go into ~/.local/bin with no root and no extra apt sources. Downloads are
# checksum-verified where upstream publishes one.
#
# k3d is installed here but is NOT in Brewfile.k8s: everything in that manifest
# is a client, and none of them provide a cluster to talk to. k3d runs k3s in
# Docker, which this box already has.
#
# Otherwise a subset of Brewfile.k8s. Not installed here, by choice:
#   k9s        — the only snap is third-party, and not wanted on this box
#   eksctl     — EKS-specific
#   kubeshark  — deploys agents into the cluster; invasive and niche
#   kubectl-ai — still 0.0.x, and upstream moved to GoogleCloudPlatform
#   openlens   — dead upstream, last release 2023-06-30. Use freelens.
# Add any of them here if that changes.

set -euo pipefail

BIN="$HOME/.local/bin"
SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -m)" == "x86_64" ]] || die "these installers assume x86_64; got $(uname -m)"

# verify_sha256 <file> <expected-hex>
verify_sha256() {
  local file="$1" want="$2" got
  got="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$got" == "$want" ]] || die "checksum mismatch for $(basename "$file")
  expected: $want
  got:      $got"
}

install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then say "kubectl already installed ($(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | head -1 | cut -d'"' -f4))"; return 0; fi
  local ver tmp
  ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" || { warn "could not resolve kubectl stable version"; SKIPPED+=(kubectl); return 0; }
  say "Installing kubectl $ver"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/kubectl" "https://dl.k8s.io/release/$ver/bin/linux/amd64/kubectl" \
     && curl -fsSL -o "$tmp/kubectl.sha256" "https://dl.k8s.io/release/$ver/bin/linux/amd64/kubectl.sha256"; then
    verify_sha256 "$tmp/kubectl" "$(cat "$tmp/kubectl.sha256")"
    mkdir -p "$BIN"; install -m 0755 "$tmp/kubectl" "$BIN/kubectl"
  else
    warn "kubectl download failed"; SKIPPED+=(kubectl)
  fi
  rm -rf "$tmp"
}

install_helm() {
  if command -v helm >/dev/null 2>&1; then say "helm already installed ($(helm version --short 2>/dev/null))"; return 0; fi
  local ver tmp
  ver="$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)" || true
  [[ -n "$ver" ]] || { warn "could not resolve helm version"; SKIPPED+=(helm); return 0; }
  say "Installing helm $ver"
  tmp="$(mktemp -d)"
  local tgz="helm-${ver}-linux-amd64.tar.gz"
  if curl -fsSL -o "$tmp/$tgz" "https://get.helm.sh/$tgz" \
     && curl -fsSL -o "$tmp/$tgz.sha256sum" "https://get.helm.sh/$tgz.sha256sum"; then
    verify_sha256 "$tmp/$tgz" "$(awk '{print $1}' "$tmp/$tgz.sha256sum")"
    tar -xzf "$tmp/$tgz" -C "$tmp"
    mkdir -p "$BIN"; install -m 0755 "$tmp/linux-amd64/helm" "$BIN/helm"
  else
    warn "helm download failed"; SKIPPED+=(helm)
  fi
  rm -rf "$tmp"
}

install_stern() {
  if command -v stern >/dev/null 2>&1; then say "stern already installed ($(stern --version 2>/dev/null | head -1))"; return 0; fi
  local url tmp
  url="$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest \
        | grep -o 'https://[^"]*stern_[0-9.]*_linux_amd64\.tar\.gz' | head -1)" || true
  [[ -n "$url" ]] || { warn "could not resolve a stern download URL"; SKIPPED+=(stern); return 0; }
  say "Installing stern"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/stern.tgz" "$url" && tar -xzf "$tmp/stern.tgz" -C "$tmp"; then
    mkdir -p "$BIN"; install -m 0755 "$(find "$tmp" -type f -name stern | head -1)" "$BIN/stern"
  else
    warn "stern download failed"; SKIPPED+=(stern)
  fi
  rm -rf "$tmp"
}

install_k3d() {
  if command -v k3d >/dev/null 2>&1; then say "k3d already installed ($(k3d version 2>/dev/null | head -1))"; return 0; fi
  # k3d runs k3s inside Docker, so it is the cluster the other tools here talk
  # to — kubectl/helm/stern are clients and provide no cluster of their own.
  # Single static binary; upstream ships a combined checksums.txt.
  local base url tmp want
  base="$(curl -fsSL https://api.github.com/repos/k3d-io/k3d/releases/latest \
        | grep -o 'https://[^"]*/download/[^"/]*' | head -1)" || true
  [[ -n "$base" ]] || { warn "could not resolve the k3d release URL"; SKIPPED+=(k3d); return 0; }
  say "Installing k3d"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/k3d" "$base/k3d-linux-amd64" \
     && curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"; then
    want="$(awk '/k3d-linux-amd64$/{print $1; exit}' "$tmp/checksums.txt")"
    if [[ -n "$want" ]]; then verify_sha256 "$tmp/k3d" "$want"
    else warn "no checksum line for k3d-linux-amd64; installing unverified"; fi
    mkdir -p "$BIN"; install -m 0755 "$tmp/k3d" "$BIN/k3d"
  else
    warn "k3d download failed"; SKIPPED+=(k3d)
  fi
  rm -rf "$tmp"

  if ! docker info >/dev/null 2>&1; then
    warn "k3d needs a working Docker daemon — 'docker info' failed. Cluster creation will not work until that does."
  fi
}

install_radar() {
  if command -v kubectl-radar >/dev/null 2>&1; then say "radar already installed ($(kubectl-radar --version 2>/dev/null | head -1))"; return 0; fi
  # skyhook-io/radar — a Kubernetes UI plus MCP server in one static binary.
  # The tarball ships it as `kubectl-radar` so `kubectl radar` picks it up as a
  # plugin; the `radar` symlink mirrors what the Homebrew formula does.
  local base ver tgz tmp want
  base="$(curl -fsSL https://api.github.com/repos/skyhook-io/radar/releases/latest \
        | grep -o 'https://[^"]*/download/[^"/]*' | head -1)" || true
  [[ -n "$base" ]] || { warn "could not resolve the radar release URL"; SKIPPED+=(radar); return 0; }
  ver="${base##*/}"
  say "Installing radar $ver"
  tmp="$(mktemp -d)"
  tgz="radar_${ver}_linux_amd64.tar.gz"
  if curl -fsSL -o "$tmp/$tgz" "$base/$tgz" \
     && curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"; then
    want="$(awk -v f="$tgz" '$2 == f {print $1; exit}' "$tmp/checksums.txt")"
    if [[ -n "$want" ]]; then verify_sha256 "$tmp/$tgz" "$want"
    else warn "no checksum line for $tgz; installing unverified"; fi
    tar -xzf "$tmp/$tgz" -C "$tmp"
    mkdir -p "$BIN"
    install -m 0755 "$tmp/kubectl-radar" "$BIN/kubectl-radar"
    ln -sf kubectl-radar "$BIN/radar"
  else
    warn "radar download failed"; SKIPPED+=(radar)
  fi
  rm -rf "$tmp"
}

install_radar_desktop() {
  if command -v radar-desktop >/dev/null 2>&1 || dpkg -s radar-desktop >/dev/null 2>&1; then
    say "radar-desktop already installed"; return 0
  fi
  # The GUI half of Radar, and like freelens a .deb rather than a tarball so it
  # gets a desktop entry and icon. Its binary is `radar-desktop`, so it does not
  # collide with the `radar` CLI installed above.
  local base ver tmp deb want
  base="$(curl -fsSL https://api.github.com/repos/skyhook-io/radar/releases/latest \
        | grep -o 'https://[^"]*/download/[^"/]*' | head -1)" || true
  [[ -n "$base" ]] || { warn "could not resolve the radar-desktop release URL"; SKIPPED+=(radar-desktop); return 0; }
  ver="${base##*/}"
  deb="radar-desktop_${ver}_linux_amd64.deb"
  # Check for usable sudo first — no point pulling 44MB to fail at the last step.
  if ! sudo -n true 2>/dev/null; then
    warn "radar-desktop needs sudo to install its .deb, and sudo is not available non-interactively here."
    warn "Run this script from a real terminal to include it."
    SKIPPED+=("radar-desktop (no sudo)")
    return 0
  fi
  say "Installing radar-desktop $ver (~44MB .deb; needs sudo)"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/$deb" "$base/$deb" \
     && curl -fsSL -o "$tmp/checksums-desktop.txt" "$base/checksums-desktop.txt"; then
    want="$(awk -v f="$deb" '{ sub(/^\*/, "", $2); if ($2 == f) { print $1; exit } }' "$tmp/checksums-desktop.txt")"
    if [[ -n "$want" ]]; then verify_sha256 "$tmp/$deb" "$want"
    else warn "no checksum line for $deb; installing unverified"; fi
    sudo apt-get install -y "$tmp/$deb" || { warn "radar-desktop install failed"; SKIPPED+=(radar-desktop); }
  else
    warn "radar-desktop download failed"; SKIPPED+=(radar-desktop)
  fi
  rm -rf "$tmp"
}

install_freelens() {
  if command -v freelens >/dev/null 2>&1 || dpkg -s freelens >/dev/null 2>&1; then
    say "freelens already installed"; return 0
  fi
  # A .deb rather than an AppImage in ~/.local/bin, for the desktop entry and
  # icon. freelens is the maintained successor to openlens (dead since
  # 2023-06-30).
  local url tmp
  url="$(curl -fsSL https://api.github.com/repos/freelensapp/freelens/releases/latest \
        | grep -o 'https://[^"]*Freelens-[0-9.]*-linux-amd64\.deb' | head -1)" || true
  [[ -n "$url" ]] || { warn "could not resolve a freelens download URL"; SKIPPED+=(freelens); return 0; }
  # Check for usable sudo first — no point pulling 146MB to fail at the last step.
  if ! sudo -n true 2>/dev/null; then
    warn "freelens needs sudo to install its .deb, and sudo is not available non-interactively here."
    warn "Run this script from a real terminal to include it."
    SKIPPED+=("freelens (no sudo)")
    return 0
  fi
  say "Installing freelens (~146MB .deb; needs sudo)"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/freelens.deb" "$url" \
     && curl -fsSL -o "$tmp/freelens.deb.sha256" "$url.sha256"; then
    verify_sha256 "$tmp/freelens.deb" "$(awk '{print $1}' "$tmp/freelens.deb.sha256")"
    sudo apt-get install -y "$tmp/freelens.deb" || { warn "freelens install failed"; SKIPPED+=(freelens); }
  else
    warn "freelens download failed"; SKIPPED+=(freelens)
  fi
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying"
  for t in kubectl helm stern k3d radar radar-desktop freelens; do
    if command -v "$t" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$t"
    else printf '  \033[31mmissing\033[0m %s\n' "$t"; fi
  done
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }
  echo
  say "Done. ~/.local/bin is already on \$path via zshrc."
}

main() {
  install_kubectl
  install_helm
  install_stern
  install_k3d
  install_radar
  install_radar_desktop
  install_freelens
  print_summary
}

main "$@"
