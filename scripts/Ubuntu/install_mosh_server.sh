#!/usr/bin/env bash
# install_mosh_server.sh — make this box reachable by mosh, over both the LAN
# and the tailnet, and open ufw exactly enough to allow it.
#
# Opt-in and NOT wired into bootstrap.sh, like install_tailscale.sh — this opens
# ports and (on the LAN path) installs a network daemon, which is a per-machine
# decision. Idempotent: safe to re-run, and re-running is how you pick up a new
# subnet after the box moves networks.
#
#   ~/.dotfiles/scripts/Ubuntu/install_mosh_server.sh
#
# WHY THERE IS AN SSH STEP IN A MOSH SCRIPT
#
# mosh is not a replacement for sshd, it is a client of it. `mosh host` shells
# in over SSH, runs `mosh-server new`, reads back the port and key, and only
# then speaks its own UDP protocol. No SSH path, no mosh session — the client
# just hangs at "Connecting...". So the two paths this script sets up each need
# *two* holes: TCP 22 to bootstrap, and the UDP range to carry the session.
#
# The tailnet is the exception that proves it. Tailscale SSH is served by
# tailscaled itself, not by sshd, so a box with no openssh-server at all is
# still mosh-reachable over the tailnet — that is exactly the state
# bartling-replay01 was found in. But Tailscale SSH only intercepts connections
# that arrive *over the tailnet*; nothing on the LAN answers on port 22. Hence
# ENABLE_LAN below, and hence it installs openssh-server when asked to.
#
# WHY THE SUBNET IS DETECTED AND NOT HARDCODED
#
# The README documents 192.168.4.0/22 for bartling-lab01, and that is a trap
# twice over: another box is on another network, and the address alone lies
# about the prefix (this LAN looks like a /24 and is a /22). `ip route ... proto
# kernel scope link` is the kernel's own computed CIDR for each connected
# subnet, so it is right by construction and costs nothing to re-derive.

set -euo pipefail

# UDP window mosh-server picks from. One port per live session; narrow it with
# MOSH_PORTS=60000:60005 and pass a matching `mosh -p` on the client.
MOSH_PORTS="${MOSH_PORTS:-60000:61000}"

# Set ENABLE_LAN=0 for a tailnet-only box. That skips both the LAN ufw rules and
# the openssh-server install, leaving the LAN with no SSH to bootstrap from.
ENABLE_LAN="${ENABLE_LAN:-1}"

# Override subnet detection when the box is on a network the kernel routes
# oddly: MOSH_LAN_CIDRS="192.168.4.0/22 10.0.0.0/24"
MOSH_LAN_CIDRS="${MOSH_LAN_CIDRS:-}"

TS_IF="${TS_IF:-tailscale0}"

# Interfaces that are never "the LAN": loopback, the tailnet (it gets its own
# interface-scoped rules), and every flavour of container/VM bridge.
NOT_LAN_RE='^(lo|'"$TS_IF"'|docker[0-9]*|br-|veth|virbr|cni|flannel|kube|tap|tun)'

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

NOTES=()

[[ "$(uname -s)" == "Linux" ]] || die "this is the Linux half; mosh on the Mac is 'brew \"mosh\"' in the Brewfile"
command -v ufw >/dev/null 2>&1 || die "ufw is not installed (sudo apt-get install -y ufw)"

# Everything below writes firewall rules or installs packages. A sudo password
# prompt that nobody is there to answer just hangs, so fail early and say why.
sudo -n true 2>/dev/null || {
  say "sudo password will be required"
  sudo -v || die "could not obtain sudo; run this from a real terminal"
}

# ---------- 1. the mosh binary ----------

install_mosh() {
  if command -v mosh-server >/dev/null 2>&1; then
    say "mosh-server already installed ($(command -v mosh-server))"
    return 0
  fi
  say "Installing mosh"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mosh
}

# mosh refuses to start under a non-UTF-8 locale, with an error that sends
# people to the firewall instead. Check it here, where the answer is obvious.
check_locale() {
  if locale -a 2>/dev/null | grep -qiE '\.utf-?8$'; then
    return 0
  fi
  warn "no UTF-8 locale is generated; mosh-server will refuse to start."
  warn "  sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8"
  NOTES+=("no UTF-8 locale — mosh will fail until locale-gen is run")
}

# ---------- 2. the SSH bootstrap path ----------

# Reports, rather than changes, how sshd authenticates. Installing openssh-server
# on a LAN is a real widening of this box's attack surface, and the default
# permits passwords; say so instead of silently deciding for the operator.
report_sshd_auth() {
  local eff
  eff="$(sudo sshd -T 2>/dev/null | awk '/^passwordauthentication /{print $2}')" || true
  case "$eff" in
    yes)
      warn "sshd accepts password authentication. On a LAN-exposed box, keys only is better."
      # Order matters, and getting it wrong locks you out of the LAN. Tailscale
      # SSH authenticates against tailnet ACLs and never reads authorized_keys,
      # so the tailnet keeps working and hides the mistake until the day the
      # tailnet is the thing that is down.
      if [[ -s "$HOME/.ssh/authorized_keys" ]]; then
        warn "  echo 'PasswordAuthentication no' | sudo tee /etc/ssh/sshd_config.d/50-no-passwords.conf"
        warn "  sudo systemctl restart ssh"
        NOTES+=("sshd still accepts passwords")
      else
        warn "  ...but ~/.ssh/authorized_keys is empty, so disabling passwords now would leave"
        warn "  the LAN path with no way in at all. Install a key FIRST, from the client:"
        warn "      ssh-copy-id -i ~/.ssh/id_ed25519.pub $USER@$(hostname).local"
        warn "  verify 'ssh -o PasswordAuthentication=no $USER@$(hostname).local true' succeeds,"
        warn "  and only then disable password auth."
        NOTES+=("sshd accepts passwords AND authorized_keys is empty — install a key before hardening")
      fi
      ;;
    no)  say "sshd is key-only (PasswordAuthentication no)" ;;
    *)   warn "could not read sshd's effective PasswordAuthentication setting" ;;
  esac
}

ensure_sshd() {
  if ! dpkg -s openssh-server >/dev/null 2>&1; then
    say "Installing openssh-server — the LAN has no SSH for mosh to bootstrap over"
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
  else
    say "openssh-server already installed"
  fi

  # Ubuntu ships both a service and a socket unit; only one may be active, and
  # enabling the wrong one leaves nothing listening. Prefer whichever is already
  # enabled, else the plain service.
  if systemctl is-enabled ssh.socket >/dev/null 2>&1; then
    sudo systemctl enable --now ssh.socket
  else
    sudo systemctl enable --now ssh
  fi

  # Match on ss's Local Address:Port column rather than the whole line. The
  # first version of this pattern tried to spell out the address characters as
  # [0-9.:*\[\]] and reported a healthy sshd as down: inside a POSIX bracket
  # expression a backslash is a literal, not an escape, so that class ends at
  # the first ']' and leaves a stray ']' in the pattern — which then demanded a
  # ']' immediately before ':22'. Never escape brackets inside a bracket class.
  if ss -tln 2>/dev/null | awk '{print $4}' | grep -qE ':22$'; then
    say "sshd is listening on port 22"
  else
    warn "nothing is listening on port 22 after enabling ssh; the LAN mosh path will not bootstrap"
    NOTES+=("sshd not listening on :22")
  fi
}

# ---------- 3. subnet detection ----------

detect_lan_cidrs() {
  if [[ -n "$MOSH_LAN_CIDRS" ]]; then
    printf '%s\n' $MOSH_LAN_CIDRS
    return 0
  fi
  # $1 = CIDR, $3 = interface, for `proto kernel scope link` routes — the
  # kernel's own view of each directly-connected subnet.
  ip -4 route show proto kernel scope link 2>/dev/null \
    | awk '{print $1, $3}' \
    | while read -r cidr iface; do
        [[ -n "$cidr" && -n "$iface" ]] || continue
        [[ "$iface" =~ $NOT_LAN_RE ]] && continue
        printf '%s\n' "$cidr"
      done | sort -u
}

# ---------- 4. ufw ----------

# `ufw allow` is itself idempotent — it prints "Skipping adding existing rule"
# rather than duplicating — so this just narrates what happened.
add_rule() {
  local desc=$1; shift
  local out
  if out="$(sudo ufw "$@" 2>&1)"; then
    case "$out" in
      *"Skipping adding existing rule"*) printf '  \033[36malready\033[0m %s\n' "$desc" ;;
      *)                                 printf '  \033[32madded\033[0m   %s\n' "$desc" ;;
    esac
  else
    warn "failed to add $desc: $out"
    NOTES+=("ufw rule failed: $desc")
  fi
}

configure_ufw() {
  local -a cidrs=()
  if [[ "$ENABLE_LAN" == "1" ]]; then
    mapfile -t cidrs < <(detect_lan_cidrs)
    if (( ${#cidrs[@]} == 0 )); then
      warn "no connected non-tailnet subnet found; skipping the LAN rules"
      NOTES+=("no LAN subnet detected")
    fi
  fi

  # ORDER MATTERS. If ufw is inactive, `ufw enable` drops every existing
  # connection that no rule permits — including the SSH session this is probably
  # running in. Every allow goes in first, and only then is the firewall turned
  # on, so enabling it can never be the thing that locks you out.
  say "Adding ufw rules (SSH bootstrap + mosh UDP $MOSH_PORTS)"

  for cidr in "${cidrs[@]:-}"; do
    [[ -n "$cidr" ]] || continue
    add_rule "ssh  from $cidr"  allow from "$cidr" to any port 22 proto tcp comment 'ssh (LAN)'
    add_rule "mosh from $cidr"  allow from "$cidr" to any port "$MOSH_PORTS" proto udp comment 'mosh (LAN)'
  done

  if ip link show "$TS_IF" >/dev/null 2>&1; then
    # Interface-scoped, not address-scoped: the tailnet is 100.64/10 but the
    # rule that matters is "arrived on the tailnet device".
    #
    # tailscale0 being in TRUSTED_IFS in docker-user-firewall.sh does NOT cover
    # this. That list is the DOCKER-USER/FORWARD chain, about published
    # container ports. Host INPUT still filters tailscale0.
    add_rule "ssh  in on $TS_IF"  allow in on "$TS_IF" to any port 22 proto tcp comment 'ssh (tailnet)'
    add_rule "mosh in on $TS_IF"  allow in on "$TS_IF" to any port "$MOSH_PORTS" proto udp comment 'mosh (tailnet)'
  else
    warn "$TS_IF does not exist; skipping the tailnet rules (run install_tailscale.sh first)"
    NOTES+=("no $TS_IF interface — tailnet rules skipped")
  fi

  if sudo ufw status 2>/dev/null | head -1 | grep -qi inactive; then
    say "Enabling ufw (allows are already in place, so this cannot lock you out)"
    sudo ufw --force enable
  else
    say "ufw already active"
  fi
}

# ---------- run ----------

install_mosh
check_locale
if [[ "$ENABLE_LAN" == "1" ]]; then
  ensure_sshd
  report_sshd_auth
else
  say "ENABLE_LAN=0 — skipping openssh-server and the LAN rules (tailnet only)"
fi
configure_ufw

# ---------- report ----------

echo
say "mosh rules now in place:"
sudo ufw status | grep -iE '60000|mosh|22.*(tcp|ssh)' || echo "  (none matched — check 'sudo ufw status verbose')"

echo
say "Verify from the client (not from this box — a local test proves nothing):"
echo "    mosh chris@$(hostname) -- true          # tailnet, via MagicDNS"
echo "    mosh chris@$(hostname).local -- true    # LAN, via mDNS"

if (( ${#NOTES[@]} )); then
  echo
  warn "follow-ups: ${NOTES[*]}"
fi
