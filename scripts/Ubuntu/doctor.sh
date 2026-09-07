#!/usr/bin/env bash
# doctor.sh — diagnose drift between this Linux box and the dotfiles repo.
# Reports (but does not fix):
#   - Symlinks that don't point at $DOTFILES (or are missing)
#   - apt packages from install_tools.sh's manifests that aren't installed
#   - snap packages, and every binary install_tools.sh is supposed to leave behind
#   - Shell startup time
#
# Run after `git pull` on a secondary machine to confirm everything is in sync.
# The Linux counterpart to scripts/macOS/doctor.zsh. There is no `brew bundle
# check` here, so the package manifests are read straight out of
# install_tools.sh rather than being restated — that file stays the one place
# a new package gets added.
#
#   ~/.dotfiles/scripts/Ubuntu/doctor.sh

set -uo pipefail   # deliberately no -e: a failing check must be reported, not fatal

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
C_CYN=$'\033[36m'; C_RST=$'\033[0m'

drift=0

# Pull in APT_* and VERIFY_TOOLS. install_tools.sh guards its main() behind a
# BASH_SOURCE check, so this is inert. It also sets -e, which would abort this
# script on the first failed check, hence the reset immediately after.
if [[ -r "$DOTFILES/scripts/Ubuntu/install_tools.sh" ]]; then
  # shellcheck source=/dev/null
  source "$DOTFILES/scripts/Ubuntu/install_tools.sh"
  set +e
  set +o pipefail
else
  # fail() isn't defined yet — see below.
  printf '%scannot read %s/scripts/Ubuntu/install_tools.sh — is $DOTFILES right?%s\n' \
    "$C_RED" "$DOTFILES" "$C_RST" >&2
  exit 1
fi

# Defined AFTER the source deliberately: install_tools.sh declares its own
# say() and warn(), and sourcing it overwrites any warn() defined earlier —
# which sent half this script's output to stderr in the installer's format
# rather than to stdout in the doctor's.
ok()   { printf '%s✓%s %s\n' "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s⚠%s %s\n' "$C_YEL" "$C_RST" "$*"; }
fail() { printf '%s✗%s %s\n' "$C_RED" "$C_RST" "$*"; }
hdr()  { printf '\n%s==> %s%s\n' "$C_CYN" "$*" "$C_RST"; }

# ---------- symlinks ----------
hdr "Symlinks"

check_symlink() {
  local target="$1" expected="$2"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    fail "$target is missing (expected → $expected)"
    drift=$((drift + 1))
  elif [[ ! -L "$target" ]]; then
    fail "$target exists but is NOT a symlink"
    drift=$((drift + 1))
  elif [[ "$(readlink "$target")" != "$expected" ]]; then
    fail "$target → $(readlink "$target")  (expected → $expected)"
    drift=$((drift + 1))
  else
    ok "$target → $expected"
  fi
}

# Mirrors scripts/Ubuntu/link.sh.
check_symlink "$HOME/.zshrc"                "$DOTFILES/zshrc"
check_symlink "$HOME/.config/starship.toml" "$DOTFILES/configurations/starship.toml"
check_symlink "$HOME/.local/bin/wlheadless-run" \
              "$DOTFILES/scripts/Ubuntu/wlheadless-run"
for s in docker-user-firewall.sh install-docker.sh ufw-docker-test.sh; do
  check_symlink "$HOME/bin/$s" "$DOTFILES/scripts/Ubuntu/bin/$s"
done
# link.sh only links this when ghostty is present, so only check it then.
if command -v ghostty >/dev/null 2>&1; then
  check_symlink "$HOME/.config/ghostty/config" \
                "$DOTFILES/configurations/ghostty/config"
else
  warn "ghostty config not checked (ghostty not installed)"
fi

# ---------- apt ----------
hdr "apt packages"

# The Playwright and pyenv-build lists are build/runtime dependencies rather
# than tools, but a missing one breaks the thing it supports in a way that is
# hard to trace later, so they are checked too.
# `dpkg -s` alone is wrong here: some names in these lists are *virtual*,
# satisfied by a real package that Provides them rather than by a package of
# that name. On 26.04 libncursesw5-dev is exactly this — apt installs it
# happily (libncurses-dev provides it) while `dpkg -s libncursesw5-dev` fails,
# which reported a correctly provisioned box as drifted.
#
# So build the satisfied set once: every installed package name, plus every
# virtual name those packages Provide.
installed_pkgs="$(dpkg-query -W -f='${Status}|${Package}|${Provides}\n' 2>/dev/null \
  | grep '^install ok installed|' | cut -d'|' -f2,3 \
  | tr '|,' '\n\n' | sed 's/ *(.*//' | tr -d ' ' | grep -v '^$' | sort -u)"

apt_missing=()
for pkg in "${APT_BASE[@]}" "${APT_MODERN[@]}" "${APT_DEV[@]}" \
           "${APT_PLAYWRIGHT[@]}" "${APT_WAYLAND[@]}" "${APT_PYENV_BUILD[@]}"; do
  if ! printf '%s\n' "$installed_pkgs" | grep -qx "$pkg"; then
    apt_missing+=("$pkg")
  fi
done
if (( ${#apt_missing[@]} == 0 )); then
  ok "all apt packages installed"
else
  warn "missing apt packages (fix: scripts/Ubuntu/install_tools.sh):"
  printf '    %s\n' "${apt_missing[@]}"
  drift=$((drift + 1))
fi

# ---------- snap ----------
hdr "snap packages"
if ! command -v snap >/dev/null 2>&1; then
  warn "snap not available — vale and difftastic not checked"
else
  snap_missing=()
  for pkg in vale difftastic; do
    snap list "$pkg" >/dev/null 2>&1 || snap_missing+=("$pkg")
  done
  if (( ${#snap_missing[@]} == 0 )); then
    ok "vale, difftastic installed"
  else
    warn "missing snaps: ${snap_missing[*]}"
    drift=$((drift + 1))
  fi
fi

# ---------- binaries ----------
hdr "Tools on \$PATH"

# Same widening print_summary uses: a tool in ~/.local/bin or ~/.cargo/bin is
# installed and works in an interactive shell even when this non-login bash
# inherited a PATH from before it was put there. pyenv is never on $path —
# zshrc exposes it as a lazy function — so resolve it at its install root.
PATH="$HOME/.local/bin:$HOME/.cargo/bin:${PYENV_ROOT:-$HOME/.pyenv}/bin:$PATH"
bin_missing=()
for t in "${VERIFY_TOOLS[@]}"; do
  command -v "$t" >/dev/null 2>&1 || bin_missing+=("$t")
done
if (( ${#bin_missing[@]} == 0 )); then
  ok "all ${#VERIFY_TOOLS[@]} expected binaries present"
else
  fail "missing binaries: ${bin_missing[*]}"
  drift=$((drift + 1))
fi

# ---------- firewall ----------
hdr "Firewall (ufw)"

# The rules this setup expects, as "<To>|<From>" pairs matching ufw's own two
# columns. Taken from bartling-lab01, which is the reference the other boxes
# are kept level with. Add a line here when a rule is added deliberately —
# an unexplained rule on a box is drift, and so is a missing one.
UFW_EXPECTED=(
  "22/tcp|192.168.4.0/22"
  "53/udp|192.168.4.0/22"
  "53/tcp|192.168.4.0/22"
  "3389|192.168.4.0/22"
  "60000:61000/udp|192.168.4.0/22"
  "60000:61000/udp on tailscale0|Anywhere"
)

if ! command -v ufw >/dev/null 2>&1; then
  fail "ufw is not installed"
  drift=$((drift + 1))
elif [[ "$(systemctl is-active ufw 2>/dev/null)" != "active" ]]; then
  fail "ufw is installed but not active"
  drift=$((drift + 1))
else
  ok "ufw active"
  # Reading the ruleset needs root. -n so this never prompts: a doctor that
  # blocks on a password prompt is a doctor nobody runs. Not being able to
  # look is a warning, not drift — it says nothing about the box's state.
  if ufw_status="$(sudo -n ufw status 2>/dev/null)" && [[ -n "$ufw_status" ]]; then
    # Collapse ufw's column padding so the fields can be matched literally.
    ufw_norm="$(printf '%s\n' "$ufw_status" | tr -s ' ')"
    ufw_missing=()
    for rule in "${UFW_EXPECTED[@]}"; do
      rule_to="${rule%%|*}"
      rule_from="${rule##*|}"
      printf '%s\n' "$ufw_norm" | grep -qF "$rule_to ALLOW IN $rule_from" \
        || ufw_missing+=("$rule_to from $rule_from")
    done
    if (( ${#ufw_missing[@]} == 0 )); then
      ok "all ${#UFW_EXPECTED[@]} expected rules present"
    else
      fail "missing ufw rules:"
      printf '    %s\n' "${ufw_missing[@]}"
      drift=$((drift + 1))
    fi
  else
    warn "ufw rules not checked (needs root: sudo ufw status numbered)"
  fi
fi

# ---------- shell startup ----------
hdr "Shell startup"

# env -u CLAUDECODE: with it set, zshrc takes its eager-nvm branch and reports
# roughly double the real interactive cost. Budget is ~150ms (see CLAUDE.md).
avg_ms=""
if command -v hyperfine >/dev/null 2>&1; then
  # -i: an interactive zsh can exit nonzero while still starting correctly,
  # and without this hyperfine refuses to benchmark it at all — which would
  # leave the mean empty and report a bogus 0ms as a pass.
  hf_json="$(mktemp)"
  if hyperfine --warmup 3 -i --style none --export-json "$hf_json" \
       'env -u CLAUDECODE zsh -i -c exit' >/dev/null 2>&1; then
    # hyperfine writes `"mean": 0.119...` — the space matters.
    mean_s="$(grep -o '"mean"[[:space:]]*:[[:space:]]*[0-9.eE+-]*' "$hf_json" \
              | head -1 | sed 's/.*:[[:space:]]*//')"
    [[ -n "$mean_s" ]] && avg_ms="$(awk -v s="$mean_s" 'BEGIN { printf "%d", s * 1000 }')"
  fi
  rm -f "$hf_json"
  [[ -z "$avg_ms" ]] && warn "hyperfine ran but produced no timing — reporting as unknown"
else
  # hyperfine is in APT_DEV, so this is the degraded path; 5 runs of `time`
  # is noisier but still catches a startup that has regressed badly.
  total=0
  for _ in 1 2 3 4 5; do
    start=$(date +%s%N)
    env -u CLAUDECODE zsh -i -c exit >/dev/null 2>&1
    end=$(date +%s%N)
    total=$(( total + (end - start) / 1000000 ))
  done
  avg_ms=$(( total / 5 ))
  warn "hyperfine not installed — falling back to a coarser timing"
fi

if [[ -z "$avg_ms" ]]; then
  fail "could not measure shell startup"
  drift=$((drift + 1))
elif (( avg_ms < 150 )); then
  ok "average startup: ${avg_ms}ms"
elif (( avg_ms < 250 )); then
  warn "average startup: ${avg_ms}ms (budget is ~150ms)"
else
  fail "average startup: ${avg_ms}ms (budget is ~150ms)"
  drift=$((drift + 1))
fi

# A login shell must start silently — any stderr is a bug.
startup_err="$(env -u CLAUDECODE zsh -i -c exit 2>&1 >/dev/null)"
if [[ -z "$startup_err" ]]; then
  ok "interactive shell starts silently"
else
  fail "interactive shell writes to stderr:"
  printf '    %s\n' "$startup_err"
  drift=$((drift + 1))
fi

# ---------- summary ----------
echo
if (( drift == 0 )); then
  ok "No drift detected. This machine is in sync with the repo."
  exit 0
else
  fail "$drift drift item(s) found. See above for details."
  echo "  Fix with:  $DOTFILES/scripts/Ubuntu/bootstrap.sh"
  exit 1
fi
