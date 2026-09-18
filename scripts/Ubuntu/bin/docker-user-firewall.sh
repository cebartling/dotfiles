#!/usr/bin/env bash
# Contain Docker's ufw bypass. Run with sudo. install_docker.sh runs it for you.
#
#   sudo docker-user-firewall.sh           # apply now, and persist via ufw
#   sudo docker-user-firewall.sh --check   # exit 0 only if applied and current
#
# Docker inserts its own FORWARD rules ahead of ufw's, so a published port is
# reachable from the LAN whether or not ufw says otherwise. DOCKER-USER is the
# one chain Docker leaves alone, so containment goes here.
#
# Policy: default-deny. Forwarded traffic to containers is DROPped unless it
# arrives on a trusted interface. Per-port exceptions are opt-in, above the drop.
#
# This script used to enumerate the interfaces to DROP (enp87s0, wlp86s0), which
# is the wrong way round: tailscale0 came up in 2026-09 and silently bypassed
# the containment, because an interface nobody had listed was an interface
# nobody had denied. The list is now the allow-list, so any interface added
# later — another NIC, a VPN tun, a second mesh — is contained by default and
# has to be trusted deliberately.
#
# Idempotent: a run that would write the same block changes no file, makes no
# backup and does not reload ufw — install_docker.sh calls this on every run.
set -euo pipefail

# Interfaces whose forwarded traffic is allowed to reach containers.
#
#   lo, docker0, br-+  Docker's own bridges: container egress and
#                      container-to-container. Dropping these breaks container
#                      networking outright. br-+ is an iptables wildcard and
#                      covers the per-network bridges, k3d's included.
#   tailscale0         The tailnet is trusted; access control is the tailnet
#                      ACLs, not this chain. Delete it from the list to contain
#                      the tailnet the same way the LAN is contained.
#
# Add docker_gwbridge if this box ever runs swarm overlay networks — it does not
# match br-+.
TRUSTED_IFS=(lo docker0 br-+ tailscale0)

# ufw loads after.rules into iptables and after6.rules into ip6tables at boot.
# Both get the block: the live chain is rebuilt for both families, and a v6
# chain that only lived until the next reboot was containment in name only.
RULE_FILES=(/etc/ufw/after.rules /etc/ufw/after6.rules)
BEGIN='# BEGIN DOCKER-USER (managed: docker ufw bypass containment)'
END='# END DOCKER-USER'

MODE=apply
case "${1:-}" in
  "")      ;;
  --check) MODE=check ;;
  *)       echo "usage: docker-user-firewall.sh [--check]"; exit 2 ;;
esac

command -v docker >/dev/null || { echo "docker not found"; exit 1; }
command -v ufw >/dev/null || { echo "ufw not found — containment is persisted through ufw's after.rules"; exit 1; }
[[ $EUID -eq 0 ]] || { echo "run me with sudo — iptables and /etc/ufw are root-only"; exit 1; }

# A trusted list without a Docker bridge in it would cut every container off
# from the network. Fail before touching the firewall, not after.
printf '%s\n' "${TRUSTED_IFS[@]}" | grep -qE '^(docker0|br-\+)$' \
  || { echo "refusing to apply: TRUSTED_IFS has no Docker bridge, containers would lose all networking"; exit 1; }

# The exact block written to each rule file, BEGIN through END.
managed_block() {
  echo "$BEGIN"
  echo "*filter"
  echo ":DOCKER-USER - [0:0]"
  echo "-A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN"
  for i in "${TRUSTED_IFS[@]}"; do echo "-A DOCKER-USER -i $i -j RETURN"; done
  echo "-A DOCKER-USER -j DROP"
  echo "COMMIT"
  echo "$END"
}

current_block() {
  sed -n "/^# BEGIN DOCKER-USER/,/^# END DOCKER-USER/p" "$1"
}

# ---------- --check ----------
if [[ $MODE == check ]]; then
  want="$(managed_block)"
  for f in "${RULE_FILES[@]}"; do
    [[ "$(current_block "$f")" == "$want" ]] \
      || { echo "not contained: $f is missing the current DOCKER-USER block"; exit 1; }
  done
  # after.rules only takes effect at boot if ufw does.
  ufw status | grep -q '^Status: active' \
    || { echo "not contained: ufw is inactive, so after.rules is never loaded"; exit 1; }
  for ipt in iptables ip6tables; do
    [[ "$($ipt -S DOCKER-USER 2>/dev/null | tail -1)" == "-A DOCKER-USER -j DROP" ]] \
      || { echo "not contained: live $ipt DOCKER-USER chain does not end in DROP"; exit 1; }
  done
  echo "contained: DOCKER-USER current in ${RULE_FILES[*]} and live for iptables and ip6tables"
  exit 0
fi

# ---------- 1. apply now ----------
apply_now() {
  local ipt=$1
  $ipt -L DOCKER-USER -n >/dev/null 2>&1 || { echo "  ($ipt) no DOCKER-USER chain, skipping"; return; }
  $ipt -F DOCKER-USER
  $ipt -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN
  # --- per-port exceptions belong HERE, above the trusted list and the drop ---
  for i in "${TRUSTED_IFS[@]}"; do $ipt -A DOCKER-USER -i "$i" -j RETURN; done
  $ipt -A DOCKER-USER -j DROP
  echo "  ($ipt) DOCKER-USER rebuilt — trusted: ${TRUSTED_IFS[*]}"
}
echo "==> Applying to the running firewall"
apply_now iptables
apply_now ip6tables

# ---------- 2. persist across reboot via ufw ----------
changed=0
persist() {
  local f=$1
  if [[ "$(current_block "$f")" == "$(managed_block)" ]]; then
    echo "  $f unchanged"
    return
  fi
  cp -a "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"
  # Replace any block we wrote before rather than skipping it, so edits to
  # TRUSTED_IFS actually survive a reboot. Skipping was how the old interface
  # list outlived the script that produced it.
  sed -i "/^# BEGIN DOCKER-USER/,/^# END DOCKER-USER/d" "$f"
  # One blank line before the block, not one more per rewrite.
  { [[ -z "$(tail -n 1 "$f")" ]] || echo ""; managed_block; } >> "$f"
  echo "  $f updated (backup alongside)"
  changed=1
}
echo "==> Persisting in ufw's rule files"
for f in "${RULE_FILES[@]}"; do persist "$f"; done

if (( changed )); then
  echo "==> Reloading ufw"
  ufw reload
fi

echo
echo "==> Resulting chain:"
iptables -L DOCKER-USER -n -v --line-numbers
echo
echo "==> This chain only sees FORWARDed traffic, so it cannot be tested from"
echo "    this host — a published port reached from here goes OUTPUT -> DNAT ->"
echo "    INPUT and never traverses FORWARD. Use ~/bin/ufw-docker-test.sh and an"
echo "    off-box client."
