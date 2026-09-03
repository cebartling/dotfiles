#!/usr/bin/env bash
# Does Docker's port publishing bypass ufw? Run with sudo on bartling-lab01.
set -uo pipefail
LANIP=192.168.4.26
# The tailnet is trusted by docker-user-firewall.sh, so it must be tested
# separately: the same port is expected to be BLOCKED over the LAN and OPEN over
# the tailnet. Resolved at run time so this does not rot if the address changes.
TSIP="$(tailscale ip -4 2>/dev/null | head -1)"
PYPID=""

cleanup() {
  echo; echo "==> Cleaning up"
  docker rm -f ufwtest-open ufwtest-loop >/dev/null 2>&1
  [ -n "$PYPID" ] && kill "$PYPID" 2>/dev/null
  echo "    containers removed, control listener stopped"
}
trap cleanup EXIT INT TERM

echo "==> ufw state (none of 18080-18082 should appear)"
ufw status verbose

echo
echo "==> Pulling nginx:alpine"
docker pull -q nginx:alpine

echo "==> 18080  CONTROL  host-native listener, no Docker involved"
python3 -m http.server 18080 --bind 0.0.0.0 >/dev/null 2>&1 &
PYPID=$!

echo "==> 18081  TEST     docker -p 18081:80        (binds 0.0.0.0)"
docker run -d --rm --name ufwtest-open -p 18081:80 nginx:alpine >/dev/null

echo "==> 18082  MITIGATION docker -p 127.0.0.1:18082:80 (loopback only)"
docker run -d --rm --name ufwtest-loop -p 127.0.0.1:18082:80 nginx:alpine >/dev/null

sleep 3
echo
echo "==> Host-side listeners:"
ss -tlnp | grep -E '1808[0-2]' | sed 's/^/    /'

cat <<PROMPT

────────────────────────────────────────────────────────────────
NOW, ON THE MAC, run this over the LAN:

  for p in 18080 18081 18082; do printf "%-6s " \$p; \\
    curl -s -m 3 -o /dev/null -w "%{http_code}\\n" http://$LANIP:\$p/ \\
    || echo "no answer"; done

Expected once docker-user-firewall.sh has been applied:
  18080  000      <- control blocked by ufw
  18081  000      <- container blocked by DOCKER-USER   <<< the fix
  18082  000      <- loopback-only, blocked

Bypass still present if you instead see:
  18081  200      <- DOCKER-USER is not containing the LAN
────────────────────────────────────────────────────────────────
AND over the tailnet, which docker-user-firewall.sh trusts on purpose:

  for p in 18080 18081 18082; do printf "%-6s " \$p; \\
    curl -s -m 3 -o /dev/null -w "%{http_code}\\n" http://$TSIP:\$p/ \\
    || echo "no answer"; done

Expected:
  18080  000      <- unless ufw explicitly allows in on tailscale0. tailscale up
                     adds no ufw rule, so the host-native listener stays behind
                     ufw's default deny on INPUT.
  18081  200      <- container reachable: tailscale0 is in TRUSTED_IFS. Published
                     ports are DNAT'd and FORWARDed, so they never hit INPUT and
                     ufw's policy does not apply — which is the whole bypass,
                     here allowed on purpose for the tailnet only.
  18082  000      <- loopback-only, never reachable from anywhere

18081 answering 000 here means the tailnet is being contained too — check that
tailscale0 is still in TRUSTED_IFS in docker-user-firewall.sh.
────────────────────────────────────────────────────────────────
PROMPT

read -r -p "Press Enter once you've run that on the Mac to tear everything down... "
