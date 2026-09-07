#!/usr/bin/env bash
# install-docker.sh — Docker Engine on Ubuntu, from Docker's own apt repository.
#
#   ~/bin/install-docker.sh            # install
#   ~/bin/install-docker.sh --verify   # install, then run the hello-world image
#
# Run it as yourself; it calls sudo where it needs root. Running the whole thing
# under sudo also works — SUDO_USER is what decides who joins the docker group,
# so the right account is added either way.
#
# Why Docker's repository and not Ubuntu's: `docker.io` in universe is an older
# Engine and ships neither `docker buildx` nor `docker compose` as plugins, and
# the convenience script at get.docker.com pipes a remote shell script into root.
# The apt repository is signed, gives us the compose/buildx plugins, and keeps a
# root-privileged daemon on the unattended-upgrade path.
#
# Docker publishes a suite per Ubuntu codename, so — exactly like Tailscale and
# unlike Chrome's single `stable main` — a brand-new Ubuntu can arrive before
# Docker has packaged it. resolve_codename checks before writing a sources list
# apt would then fail on.
#
# NOTE: installing Docker is the moment its ufw bypass opens up. Docker inserts
# FORWARD rules ahead of ufw's, so any published container port is reachable
# from the LAN whether or not ufw agrees. Run docker-user-firewall.sh afterwards;
# print_summary says so again at the end.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEYRING="/etc/apt/keyrings/docker.asc"
SOURCES="/etc/apt/sources.list.d/docker.sources"
BASE="https://download.docker.com/linux/ubuntu"
# Suite to fall back on when Docker has not packaged this Ubuntu release yet.
FALLBACK_CODENAME="noble"

PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

# usermod -aG needs the human, not root. Under sudo that is SUDO_USER; run
# directly it is USER. Either way it is the account that will type `docker`.
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

VERIFY=0
SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
usage: install-docker.sh [--verify]

  --verify   after installing, run `docker run --rm hello-world` as a smoke
             test. Needs egress to Docker Hub and leaves the image behind, so
             it is off by default.
USAGE
}

while (( $# )); do
  case "$1" in
    --verify) VERIFY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
  shift
done

command -v systemctl >/dev/null 2>&1 || die "dockerd needs systemd, and systemctl is not on \$PATH"

# Docker builds for amd64 and arm64 (and more); take the answer from dpkg rather
# than assuming, so this works on an arm64 box unchanged.
ARCH="$(dpkg --print-architecture)"

# Every step below needs root, and a password prompt nobody is there to answer
# just hangs.
require_sudo() {
  sudo -n true 2>/dev/null && return 0
  warn "docker needs sudo (apt repository, package install, systemd units, group membership), and sudo is not available non-interactively here."
  warn "Run this script from a real terminal to include it."
  SKIPPED+=("docker (no sudo)")
  return 1
}

# curl is how resolve_codename probes the repository and how the key is fetched,
# so it has to exist before either. A minimal Ubuntu image ships neither it nor
# the CA bundle.
ensure_prereqs() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  dpkg -s ca-certificates >/dev/null 2>&1 || missing+=(ca-certificates)
  (( ${#missing[@]} )) || return 0
  say "Installing prerequisites: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
}

# Verify this box's codename is one Docker actually publishes before pointing
# apt at it.
resolve_codename() {
  local codename
  codename="$(. /etc/os-release 2>/dev/null && printf '%s' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
  [[ -n "$codename" ]] || codename="$(lsb_release -cs 2>/dev/null || true)"
  [[ -n "$codename" ]] || codename="$FALLBACK_CODENAME"
  # No curl means no probe. Trusting the local codename beats falling back to an
  # older suite just because we could not ask.
  if ! command -v curl >/dev/null 2>&1; then
    warn "curl is missing, so '$codename' goes unverified against Docker's repository."
  elif ! curl -fsI "$BASE/dists/$codename/Release" >/dev/null 2>&1; then
    warn "Docker has no apt suite for '$codename' yet; falling back to '$FALLBACK_CODENAME'."
    codename="$FALLBACK_CODENAME"
  fi
  printf '%s\n' "$codename"
}

add_repo() {
  local codename tmp
  # Match on the URI, not the suite: a box that upgraded Ubuntu underneath us
  # still has a working Docker source, and re-resolving it is not this script's
  # job. Deliberately the same shape as install_tailscale.sh's check.
  if [[ -s "$KEYRING" && -s "$SOURCES" ]] && grep -q "^URIs: $BASE\$" "$SOURCES"; then
    say "Docker apt repository already configured ($(awk '/^Suites:/{print $2; exit}' "$SOURCES"))"
    return 0
  fi

  ensure_prereqs
  codename="$(resolve_codename)"

  say "Adding the Docker apt repository for $codename/$ARCH"

  tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/docker.asc" "$BASE/gpg"; then
    warn "could not download the Docker signing key from $BASE/gpg"
    SKIPPED+=("docker (key download failed)")
    rm -rf "$tmp"
    return 1
  fi
  # apt reads armored keys, but only if they really are keys — a captive portal
  # or an error page would otherwise be installed as trust material.
  grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$tmp/docker.asc" \
    || { rm -rf "$tmp"; die "what came back from $BASE/gpg is not an armored PGP key; refusing to install it"; }

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo install -m 0644 "$tmp/docker.asc" "$KEYRING"
  rm -rf "$tmp"

  sudo tee "$SOURCES" >/dev/null <<SRC
Types: deb
URIs: $BASE
Suites: $codename
Components: stable
Architectures: $ARCH
Signed-By: $KEYRING
SRC

  sudo apt-get update -qq
}

install_docker() {
  local missing=()
  for p in "${PACKAGES[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if (( ${#missing[@]} == 0 )); then
    say "Docker packages already installed ($(docker --version 2>/dev/null))"
    return 0
  fi
  say "Installing ${missing[*]}"
  sudo apt-get install -y "${missing[@]}" \
    || { warn "docker install failed"; SKIPPED+=(docker); return 1; }
}

enable_daemon() {
  command -v dockerd >/dev/null 2>&1 || return 0
  local unit
  for unit in docker.service containerd.service; do
    if [[ "$(systemctl is-enabled "$unit" 2>/dev/null | head -1)" == "enabled" ]] \
       && systemctl is-active --quiet "$unit"; then
      say "$unit already enabled and running"
      continue
    fi
    say "Enabling and starting $unit"
    sudo systemctl enable --now "$unit" \
      || { warn "could not enable $unit"; SKIPPED+=("$unit (systemd)"); }
  done
}

# Membership in `docker` is root-equivalent — the daemon socket will bind any
# host path into a container. That is the accepted trade for not typing sudo in
# front of every command, but it is worth knowing rather than discovering.
join_docker_group() {
  if id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    say "'$TARGET_USER' is already in the docker group"
    return 0
  fi
  say "Adding '$TARGET_USER' to the docker group"
  sudo usermod -aG docker "$TARGET_USER" \
    || { warn "could not add '$TARGET_USER' to the docker group"; SKIPPED+=("docker group"); }
}

# Runs as root deliberately: the group change above does not apply to the shell
# we are already inside, so an unprivileged `docker run` here would fail for a
# reason that has nothing to do with the install.
verify_hello_world() {
  (( VERIFY )) || return 0
  command -v docker >/dev/null 2>&1 || return 0
  say "Running hello-world"
  sudo docker run --rm hello-world \
    || { warn "hello-world failed — the daemon is up but cannot pull or run"; SKIPPED+=("hello-world"); }
}

# A re-run on a finished box should short-circuit before the sudo gate rather
# than warn about a password it does not need.
nothing_to_do() {
  local p
  command -v docker >/dev/null 2>&1 || return 1
  [[ -s "$KEYRING" && -s "$SOURCES" ]] || return 1
  for p in "${PACKAGES[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || return 1; done
  [[ "$(systemctl is-enabled docker.service 2>/dev/null | head -1)" == "enabled" ]] || return 1
  systemctl is-active --quiet docker.service || return 1
  id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker
}

print_summary() {
  echo
  say "Verifying"
  for c in docker dockerd containerd; do
    if command -v "$c" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$c"
    else printf '  \033[31mmissing\033[0m %s\n' "$c"; fi
  done
  for p in docker-buildx-plugin docker-compose-plugin; do
    if dpkg -s "$p" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$p"
    else printf '  \033[31mmissing\033[0m %s\n' "$p"; fi
  done
  # systemctl prints its answer and still exits non-zero for a missing unit, so
  # take the first line and ignore the status.
  for unit in docker.service containerd.service; do
    printf '  unit    %s (%s, %s)\n' "$unit" \
      "$(systemctl is-enabled "$unit" 2>/dev/null | head -1)" \
      "$(systemctl is-active "$unit" 2>/dev/null | head -1)"
  done
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }

  echo
  if id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    # Ask as the human, not as root. Under sudo a bare `docker info` succeeds
    # whatever $TARGET_USER's group membership has actually taken effect, which
    # would report the one thing this check exists to catch as fine.
    local probe=(docker info)
    (( EUID == 0 )) && probe=(sudo -u "$TARGET_USER" docker info)
    if "${probe[@]}" >/dev/null 2>&1; then
      say "'$TARGET_USER' can talk to the daemon."
    else
      say "Next: pick up the new group — log out and back in, or start a subshell"
      echo "    newgrp docker"
    fi
  fi

  echo
  warn "Docker bypasses ufw: published container ports reach the LAN regardless of your firewall rules."
  warn "Contain that now, before you publish anything:"
  echo "    sudo ~/bin/docker-user-firewall.sh"
  echo "    ~/bin/ufw-docker-test.sh          # from an off-box client, proves it"
}

main() {
  if nothing_to_do; then
    say "Docker is already installed and dockerd is running"
    verify_hello_world
    print_summary
    return 0
  fi
  require_sudo   || { print_summary; return 0; }
  add_repo       || { print_summary; return 0; }
  install_docker || { print_summary; return 0; }
  enable_daemon
  join_docker_group
  verify_hello_world
  print_summary
}

main "$@"
