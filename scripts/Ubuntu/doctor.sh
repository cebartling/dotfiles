#!/usr/bin/env bash
# doctor.sh — diagnose drift between this Linux box and the dotfiles repo.
# Reports (but does not fix):
#   - Symlinks that don't point at $DOTFILES (or are missing)
#   - apt packages from install_tools.sh's manifests that aren't installed
#   - snap packages, and every binary install_tools.sh is supposed to leave behind
#   - ufw state and Docker's ufw-bypass containment (rules need root to read)
#   - What the opt-in installers set up — Tailscale, Obsidian sync, Claude Code,
#     Docker, SSH — each checked only when its tool is installed, so a box
#     that skipped an installer reports it as not checked, not as drift
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

# check_unit <unit> / check_user_unit <unit>: enabled and running. Used only
# for units an installer enabled, so anything else is drift. systemctl prints
# its answer and still exits non-zero for a stopped unit — take the text.
_check_unit() {
  local scope="$1" unit="$2" en act
  en="$(systemctl $scope is-enabled "$unit" 2>/dev/null | head -1)"
  act="$(systemctl $scope is-active "$unit" 2>/dev/null | head -1)"
  if [[ "$en" == enabled && "$act" == active ]]; then
    ok "$unit enabled and running"
  else
    fail "$unit is ${en:-unknown} and ${act:-unknown} (expected enabled and active)"
    drift=$((drift + 1))
  fi
}
check_unit()      { _check_unit ""       "$1"; }
check_user_unit() { _check_unit "--user" "$1"; }

# Mirrors scripts/Ubuntu/link.sh.
check_symlink "$HOME/.zshrc"                "$DOTFILES/zshrc"
check_symlink "$HOME/.config/starship.toml" "$DOTFILES/configurations/starship.toml"
check_symlink "$HOME/.config/git/config"    "$DOTFILES/configurations/git/config"
# The link can be right and commits still fail — e.g. a per-machine
# ~/.gitconfig that blanks the identity. Check what git actually resolves.
if git var GIT_AUTHOR_IDENT >/dev/null 2>&1; then
  ok "git author identity resolves"
else
  fail "git has no author identity — commits will fail"
  drift=$((drift + 1))
fi
check_symlink "$HOME/.local/bin/wlheadless-run" \
              "$DOTFILES/scripts/Ubuntu/wlheadless-run"
for s in docker-user-firewall.sh ufw-docker-test.sh; do
  check_symlink "$HOME/bin/$s" "$DOTFILES/scripts/Ubuntu/bin/$s"
done
# link.sh only links this when ghostty is present, so only check it then.
if command -v ghostty >/dev/null 2>&1; then
  check_symlink "$HOME/.config/ghostty/config" \
                "$DOTFILES/configurations/ghostty/config"
else
  warn "ghostty config not checked (ghostty not installed)"
fi
# The rest mirror link.sh's conditional branches, under the same conditions.
zed_script="$HOME/.local/share/nautilus/scripts/Open with Zed"
zed_src="$DOTFILES/scripts/Ubuntu/nautilus/Open with Zed"
if ! command -v nautilus >/dev/null 2>&1; then
  warn "nautilus script not checked (nautilus not installed)"
elif [[ -x "$HOME/.local/bin/zed" ]]; then
  check_symlink "$zed_script" "$zed_src"
elif [[ -L "$zed_script" && "$(readlink "$zed_script")" == "$zed_src" ]]; then
  # link.sh removes this when zed is absent; still here means it has not run.
  fail "$zed_script is linked but zed is not installed (fix: scripts/Ubuntu/link.sh)"
  drift=$((drift + 1))
else
  warn "nautilus script not checked (zed not installed)"
fi
if command -v tailscale >/dev/null 2>&1; then
  for d in "$HOME/.config/autostart" "$HOME/.local/share/applications"; do
    check_symlink "$d/tailscale-systray.desktop" \
                  "$DOTFILES/scripts/Ubuntu/desktop/tailscale-systray.desktop"
  done
  check_symlink "$HOME/.local/bin/tailscale-cert-renew" \
                "$DOTFILES/scripts/Ubuntu/tailscale-cert-renew"
  for u in tailscale-cert-renew.service tailscale-cert-renew.timer; do
    check_symlink "$HOME/.config/systemd/user/$u" "$DOTFILES/scripts/Ubuntu/systemd/$u"
  done
else
  warn "tailscale links not checked (tailscale not installed)"
fi
if command -v systemctl >/dev/null 2>&1; then
  check_symlink "$HOME/.config/systemd/user/obsidian-sync@.service" \
                "$DOTFILES/scripts/Ubuntu/systemd/obsidian-sync@.service"
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

# ---------- docker containment ----------
# Docker's published ports bypass ufw; docker-user-firewall.sh contains that
# and its --check says whether it is applied and current. Root-only, so like
# the ufw rules above: not being able to look is a warning, not drift.
if command -v docker >/dev/null 2>&1; then
  hdr "Docker"
  check_unit docker.service
  # install_docker.sh adds the human to the group; without it every docker
  # command needs sudo. Given a name, `id -nG` reads the group database, not
  # this shell's credentials — so a membership that only takes effect at the
  # next login still counts, which is right: that is not drift.
  if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    ok "$USER is in the docker group"
  else
    fail "$USER is not in the docker group (fix: scripts/Ubuntu/install_docker.sh)"
    drift=$((drift + 1))
  fi
  fw="$DOTFILES/scripts/Ubuntu/bin/docker-user-firewall.sh"
  if ! sudo -n true 2>/dev/null; then
    warn "not checked (needs root: sudo $fw --check)"
  elif verdict="$(sudo -n "$fw" --check 2>&1)"; then
    ok "$verdict"
  else
    fail "$verdict (fix: sudo $fw)"
    drift=$((drift + 1))
  fi
else
  warn "docker not checked (docker not installed)"
fi

# ---------- tailscale ----------
if command -v tailscale >/dev/null 2>&1; then
  hdr "Tailscale"
  check_unit tailscaled.service
  check_user_unit tailscale-cert-renew.timer
  # Same test as install_tailscale.sh:operator_is_me. The tray client drives
  # tailscaled without root only when this user is its operator.
  if tailscale debug prefs 2>/dev/null | grep -q "\"OperatorUser\": \"$USER\""; then
    ok "tailscaled operator is $USER"
  else
    fail "tailscaled operator is not $USER (fix: scripts/Ubuntu/install_tailscale.sh)"
    drift=$((drift + 1))
  fi
else
  warn "tailscale not checked (tailscale not installed)"
fi

# ---------- obsidian sync ----------
if command -v ob >/dev/null 2>&1; then
  hdr "Obsidian sync"
  # Enabled instances of the template — the template itself lists as `linked`.
  vault_units=()
  while read -r unit state _; do
    [[ "$state" == enabled && "$unit" != "obsidian-sync@.service" ]] && vault_units+=("$unit")
  done < <(systemctl --user list-unit-files 'obsidian-sync@*' --no-legend 2>/dev/null)
  if (( ${#vault_units[@]} == 0 )); then
    warn "no vault sync units enabled (set one up with ob, then re-run install_obsidian_headless.sh)"
  else
    for u in "${vault_units[@]}"; do check_user_unit "$u"; done
    # Same test as install_obsidian_headless.sh:linger_on. Without linger the
    # sync stops when the last session closes.
    if [[ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" == yes ]]; then
      ok "linger enabled for $USER"
    else
      fail "linger is off — sync stops at logout (fix: sudo loginctl enable-linger $USER)"
      drift=$((drift + 1))
    fi
  fi
else
  warn "obsidian sync not checked (ob not installed)"
fi

# ---------- claude code ----------
# Mirrors ai-tools/claude-code/install.sh, globbing its source directories the
# same way so a new command, hook or skill is checked without editing this.
if command -v claude >/dev/null 2>&1; then
  hdr "Claude Code"
  cc_src="$DOTFILES/ai-tools/claude-code"
  for f in CLAUDE.md RTK.md settings.json; do
    check_symlink "$HOME/.claude/$f" "$cc_src/$f"
  done
  for sub in commands hooks skills; do
    for src in "$cc_src/$sub/"*; do
      [[ -e "$src" ]] || continue
      check_symlink "$HOME/.claude/$sub/$(basename "$src")" "$src"
    done
  done
else
  warn "claude code not checked (claude not installed)"
fi

# ---------- ssh ----------
# install_mosh_server.sh enables ssh.socket where the box uses socket
# activation and ssh.service otherwise, so either one running is correct.
if command -v mosh-server >/dev/null 2>&1; then
  hdr "SSH"
  if systemctl is-active --quiet ssh.socket || systemctl is-active --quiet ssh.service; then
    ok "sshd reachable ($(systemctl is-active --quiet ssh.socket && echo ssh.socket || echo ssh.service) active)"
  else
    fail "neither ssh.socket nor ssh.service is active (fix: scripts/Ubuntu/install_mosh_server.sh)"
    drift=$((drift + 1))
  fi
else
  warn "ssh not checked (mosh-server not installed)"
fi

# ---------- java ----------
# bootstrap.sh installs sdkman's default JDK (ensure_java), and zshrc puts
# candidates/*/current/bin on $path, so `current` is what a shell runs.
if [[ -d "${SDKMAN_DIR:-$HOME/.sdkman}" ]]; then
  hdr "Java"
  jbin="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/current/bin/java"
  if jver="$("$jbin" -version 2>&1 | head -1)" && [[ -n "$jver" ]]; then
    ok "sdkman java: $jver"
  else
    fail "no sdkman default JDK at $jbin (fix: sdk install java, or scripts/Ubuntu/bootstrap.sh)"
    drift=$((drift + 1))
  fi
else
  warn "java not checked (sdkman not installed)"
fi

# ---------- github cli ----------
# A login is not something this repo provisions, and the check goes to the
# network — an offline box is not a drifted one. So: a warning, never drift.
# Ask the API rather than `gh auth status`: Ubuntu's gh 2.46 exits 0 from that
# even when it is reporting the stored token as invalid.
if command -v gh >/dev/null 2>&1; then
  hdr "GitHub CLI"
  if gh_login="$(timeout 10 gh api user --jq .login 2>/dev/null)" && [[ -n "$gh_login" ]]; then
    ok "gh authenticated as $gh_login"
  else
    warn "gh is not authenticated, or GitHub is unreachable (fix: gh auth login -h github.com -p ssh -w)"
  fi
else
  warn "gh not checked (gh not installed)"
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
  # Accumulate nanoseconds and convert once. Dividing inside the loop
  # truncated each run to a whole millisecond before summing, biasing the
  # average low by up to 1ms. Small, but the ok/warn line sits at exactly
  # 150ms, so it is the boundary case that the rounding lands on.
  #
  # `date +%s%N` forks twice per run where bash 5's $EPOCHREALTIME would not,
  # but EPOCHREALTIME renders with the locale's decimal separator (verified:
  # LC_ALL=de_DE gives `1789044876,115902`), which silently breaks the
  # arithmetic below. Two forks are the cheaper problem.
  total_ns=0
  for _ in 1 2 3 4 5; do
    start=$(date +%s%N)
    env -u CLAUDECODE zsh -i -c exit >/dev/null 2>&1
    end=$(date +%s%N)
    total_ns=$(( total_ns + (end - start) ))
  done
  avg_ms=$(( total_ns / 5 / 1000000 ))
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
