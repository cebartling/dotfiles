#!/usr/bin/env bash
# install_all.sh — run the Ubuntu installers in dependency order.
#
# The install_*.sh scripts in this directory depend on each other, and until
# this script existed those dependencies lived only in prose headers and in the
# call order of bootstrap.sh:main(). Nothing enforced them, and nothing told you
# the right order. Each script now carries an `install-all metadata` block; this
# script parses those blocks, proves the execution order satisfies them, and
# runs what you pick.
#
# Safe by default and safe to re-run:
#   - with no terminal it prints an advisory and changes NOTHING (exit 0), so a
#     piped or SSH bootstrap stays exactly as unattended as it was before
#   - every installer it calls is itself idempotent
#   - `group: dangerous` scripts are never included by --all
#
#   install_all.sh                 # prompt for each optional installer
#   install_all.sh --list          # show the catalog, change nothing
#   install_all.sh --dry-run --all # show what would run, in order
#   install_all.sh --only=tailscale,claude_code
#   install_all.sh --check         # validate metadata vs ORDER (a parse gate)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- helpers ----------
say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Execution order. Hand-maintained, and deliberately so: ten nodes and one real
# hard edge do not justify a topological sort nobody will read again.
# validate_order() proves this list satisfies every declared requires/wants
# edge, so it cannot silently drift from the metadata — and an order that no
# list can satisfy (a cycle) fails that check by construction.
ORDER=(
  install_tools.sh
  install_nodejs.sh
  install_fonts.sh
  link.sh
  install_chrome.sh
  install_tailscale.sh
  install_docker.sh
  install_k8s_tools.sh
  install_claude_code.sh
  install_zed.sh
  install_obsidian_headless.sh
  install_mosh_server.sh
)

declare -A M_SUMMARY M_GROUP M_REQUIRES M_WANTS M_CMD M_ARCH M_SUDO

MODE=prompt          # prompt | all | none | only | advise | list | check
ONLY=""
ASSUME_YES=0
DRY_RUN=0
FAIL_FAST=0
SUDO_MODE=none       # none | passwordless | interactive
SELECTED=()
DONE=(); FAILED=(); SKIPPED=(); BLOCKED=()

# ---------- metadata ----------

# One awk pass over the whole directory — not a subshell per file. The block is
# delimited rather than key-anchored because these headers are long English
# prose and an unanchored `^# requires:` would eventually match a sentence.
load_metadata() {
  local file key val
  while IFS=$'\t' read -r file key val; do
    case "$key" in
      summary)    M_SUMMARY["$file"]="$val" ;;
      group)      M_GROUP["$file"]="$val" ;;
      requires)   M_REQUIRES["$file"]="$val" ;;
      wants)      M_WANTS["$file"]="$val" ;;
      needs-cmd)  M_CMD["$file"]="$val" ;;
      needs-arch) M_ARCH["$file"]="$val" ;;
      sudo)       M_SUDO["$file"]="$val" ;;
      *)          warn "$file: unknown metadata key '$key'" ;;
    esac
  done < <(awk '
    FNR == 1 { name = FILENAME; sub(/.*\//, "", name); inblk = 0 }
    /^# --- install-all metadata ---$/ { inblk = 1; next }
    /^# --- end metadata ---$/         { inblk = 0; next }
    inblk && /^#[ \t]+[a-z-]+:/ {
      line = $0
      sub(/^#[ \t]+/, "", line)
      key = line; sub(/:.*$/, "", key)
      val = line; sub(/^[a-z-]+:[ \t]*/, "", val)
      sub(/[ \t]+$/, "", val)
      printf "%s\t%s\t%s\n", name, key, val
    }
  ' "$HERE"/install_*.sh "$HERE"/link.sh)
}

# Proves ORDER satisfies the declared graph. Runs on every invocation (~1ms) and
# is the whole of --check, which joins `bash -n` as a pre-commit gate.
validate_order() {
  local -A rank=()
  local i s dep bad=0
  for i in "${!ORDER[@]}"; do rank["${ORDER[$i]}"]=$i; done

  for s in "${!M_GROUP[@]}"; do
    [[ -n "${rank[$s]:-}" ]] || { warn "$s declares metadata but is not in ORDER"; bad=1; }
  done

  for s in "${ORDER[@]}"; do
    [[ -x "$HERE/$s" ]] || { warn "ORDER lists $s, which is not an executable file"; bad=1; }
    [[ -n "${M_GROUP[$s]:-}" ]] || { warn "$s is in ORDER but declares no metadata block"; bad=1; }
    for dep in ${M_REQUIRES[$s]:-} ${M_WANTS[$s]:-}; do
      if [[ -z "${rank[$dep]:-}" ]]; then
        warn "$s depends on '$dep', which is not in ORDER"; bad=1
      elif (( rank[$dep] >= rank[$s] )); then
        warn "ORDER violates $s -> $dep ($dep must come first)"; bad=1
      fi
    done
  done
  (( bad == 0 )) || die "ORDER is out of sync with the declared dependencies"
}

# ---------- selection ----------

usage() {
  cat <<'EOF'
Usage: install_all.sh [options]

  --all            run every core and opt-in installer (never `dangerous` ones)
  --none           run nothing (useful with --list)
  --only=a,b       run exactly these, plus anything they require
  --yes, -y        assume yes at every prompt
  --list           print the catalog and exit
  --check          validate metadata against ORDER and exit
  --dry-run        print what would run, in order, and change nothing
  --fail-fast      stop at the first failure instead of continuing
  -h, --help       this text

Environment:
  DOTFILES_INSTALL_ALL=all|none|<csv>   same as the flags, for unattended runs

With no terminal and no explicit flag, this prints an advisory and exits 0
without changing anything.
EOF
}

parse_args() {
  local a
  for a in "$@"; do
    case "$a" in
      --all)       MODE=all ;;
      --none)      MODE=none ;;
      --only=*)    MODE=only; ONLY="${a#--only=}" ;;
      --yes|-y)    ASSUME_YES=1 ;;
      --list)      MODE=list ;;
      --check)     MODE=check ;;
      --dry-run)   DRY_RUN=1 ;;
      --fail-fast) FAIL_FAST=1 ;;
      -h|--help)   usage; exit 0 ;;
      *)           die "unknown option: $a (try --help)" ;;
    esac
  done

  # --yes is an explicit statement of intent, so it must not degrade into the
  # advisory no-op below. "Yes to everything you would have asked about" is the
  # opt-in set, which still excludes `dangerous`.
  if [[ "$MODE" == prompt ]] && (( ASSUME_YES )); then MODE=all; fi

  if [[ "$MODE" == prompt && -n "${DOTFILES_INSTALL_ALL:-}" ]]; then
    case "$DOTFILES_INSTALL_ALL" in
      all)  MODE=all ;;
      none) MODE=none ;;
      *)    MODE=only; ONLY="$DOTFILES_INSTALL_ALL" ;;
    esac
  fi

  # No terminal, no prompt. This is the piped, cron, cloud-init and AI-agent
  # case, and it must behave exactly as this repo did before install_all
  # existed: print, change nothing, succeed. Both stdin AND stdout must be a
  # TTY — `curl | bash` leaves stdout a terminal but stdin a pipe, and
  # `cmd > log` leaves stdin a terminal with nobody reading the menu.
  if [[ "$MODE" == prompt ]] && { [[ ! -t 0 ]] || [[ ! -t 1 ]] || [[ -n "${CI:-}" ]]; }; then
    MODE=advise
  fi
}

in_list() { local n="$1"; shift; local e; for e in "$@"; do [[ "$e" == "$n" ]] && return 0; done; return 1; }

# Accepts `tailscale`, `install_tailscale`, or `install_tailscale.sh`.
resolve_name() {
  local want="$1" s
  for s in "${ORDER[@]}"; do
    [[ "$s" == "$want" || "$s" == "install_${want}.sh" || "${s%.sh}" == "$want" ]] && { printf '%s' "$s"; return 0; }
  done
  return 1
}

arch_ok() {
  local s="$1" want="${M_ARCH[$s]:-}"
  [[ -z "$want" || "$(uname -m)" == "$want" ]]
}

ask() {
  local s="$1" ans=""
  (( ASSUME_YES )) && return 0
  printf '  %-30s %s\n' "$s" "${M_SUMMARY[$s]:-}"
  [[ "${M_GROUP[$s]:-}" == dangerous ]] && \
    printf '    \033[33mnote:\033[0m this one changes your firewall\n'
  read -r -t 120 -p "    install it? [y/N] " ans || ans=""
  [[ "$ans" == [yY]* ]]
}

select_scripts() {
  local s want resolved
  case "$MODE" in
    none|list|check|advise) SELECTED=() ;;
    all)
      for s in "${ORDER[@]}"; do
        # `dangerous` is never swept up by --all. install_mosh_server.sh runs
        # `sudo ufw --force enable`, and on a box reached over a non-standard
        # port, or with Docker rules it knows nothing about, that can cut the
        # session it is running in.
        [[ "${M_GROUP[$s]}" == dangerous ]] && { SKIPPED+=("$s (excluded from --all; use --only)"); continue; }
        arch_ok "$s" || { SKIPPED+=("$s (needs $(printf '%s' "${M_ARCH[$s]}"))"); continue; }
        SELECTED+=("$s")
      done ;;
    only)
      local IFS=','
      for want in $ONLY; do
        resolved="$(resolve_name "$want")" || die "no such installer: $want (try --list)"
        in_list "$resolved" "${SELECTED[@]:-}" || SELECTED+=("$resolved")
      done
      unset IFS
      expand_requires ;;
    prompt)
      say "Optional installers — answer for each (default No):"
      echo
      for s in "${ORDER[@]}"; do
        [[ "${M_GROUP[$s]}" == core ]] && continue
        arch_ok "$s" || continue
        ask "$s" && SELECTED+=("$s")
      done
      echo
      expand_requires ;;
  esac
  reorder_selection
}

# Hard edges only. Pulling in a script's `wants:` would silently install things
# nobody asked for; pulling in its `requires:` is the difference between working
# and dying. Runs BEFORE the sudo preflight, since expansion can drag a
# root-needing script into a selection that looked sudo-free.
expand_requires() {
  local changed=1 s dep
  while (( changed )); do
    changed=0
    for s in "${SELECTED[@]:-}"; do
      for dep in ${M_REQUIRES[$s]:-}; do
        if ! in_list "$dep" "${SELECTED[@]:-}"; then
          say "also selecting $dep, required by $s"
          SELECTED+=("$dep"); changed=1
        fi
      done
    done
  done
}

# Sorts the selection into ORDER, and drops anything already recorded as done.
# Under bootstrap.sh the core scripts are pre-marked done, so this is what stops
# --all from running install_tools.sh a second time — while leaving it in DONE so
# a `requires:` edge pointing at it still resolves.
reorder_selection() {
  local s out=()
  for s in "${ORDER[@]}"; do
    in_list "$s" "${SELECTED[@]:-}" || continue
    if in_list "$s" "${DONE[@]:-}"; then
      say "$s already ran in this session; not running it again"
      continue
    fi
    out+=("$s")
  done
  SELECTED=("${out[@]:-}")
}

# ---------- sudo ----------

preflight_sudo() {
  local s need=0 required=() optional=()
  for s in "${SELECTED[@]:-}"; do
    case "${M_SUDO[$s]:-none}" in
      required) required+=("$s"); need=1 ;;
      optional) optional+=("$s"); need=1 ;;
    esac
  done
  (( need )) || { SUDO_MODE=none; return 0; }

  # A dry run executes nothing, so the plan it prints should be the plan you
  # would get with sudo — not whatever survives the sudo-less shell you happen
  # to be dry-running from.
  if (( DRY_RUN )); then SUDO_MODE=none; return 0; fi

  if sudo -n true 2>/dev/null; then SUDO_MODE=passwordless; return 0; fi

  if [[ -t 0 ]]; then
    (( ${#required[@]} )) && \
      say "Needs root: ${required[*]}"
    (( ${#optional[@]} )) && \
      say "Partly needs root: ${optional[*]}"
    say "You will be asked for your password once, now."
    if sudo -v; then SUDO_MODE=interactive; return 0; fi
  fi

  # No passwordless sudo and no human to ask. Drop only the scripts that cannot
  # do anything without it, rather than letting one sit on a password prompt
  # forever — which is what install_tools.sh does today if it gets that far.
  # `optional` scripts stay: they degrade internally and record their own
  # SKIPPED entries. install_k8s_tools.sh, for instance, installs five CLI
  # tools with no root at all and only needs sudo for two .deb packages.
  local kept=()
  for s in "${SELECTED[@]:-}"; do
    if [[ "${M_SUDO[$s]:-none}" == required ]]; then
      SKIPPED+=("$s (needs sudo, none available)")
    else
      kept+=("$s")
    fi
  done
  SELECTED=("${kept[@]:-}")
}

# A 633-line installer will outlive the 15-minute sudo timestamp; bootstrap.sh
# already concedes this in run_install_nodejs. Refresh between scripts rather
# than backgrounding a keepalive that needs a trap and leaks on kill -9.
refresh_sudo() {
  [[ "$SUDO_MODE" == none ]] && return 0
  sudo -v 2>/dev/null || warn "sudo timestamp expired; the next step may prompt"
}

# ---------- run ----------

run_one() {
  local s="$1" dep
  for dep in ${M_REQUIRES[$s]:-}; do
    if ! in_list "$dep" "${DONE[@]:-}"; then
      warn "$s requires $dep, which did not run successfully"
      BLOCKED+=("$s (needs $dep)"); return 0
    fi
  done
  for dep in ${M_CMD[$s]:-}; do
    command -v "$dep" >/dev/null 2>&1 || {
      warn "$s needs '$dep', which is not installed"
      SKIPPED+=("$s (no $dep)"); return 0; }
  done
  arch_ok "$s" || { SKIPPED+=("$s (needs ${M_ARCH[$s]})"); return 0; }

  if (( DRY_RUN )); then say "would run $s"; DONE+=("$s"); return 0; fi

  refresh_sudo
  say "Running $s"
  # </dev/null so a child (apt, snap, an upstream installer) can never consume
  # this script's stdin. sudo reads the password from /dev/tty, so the password
  # prompt still works.
  if "$HERE/$s" </dev/null; then
    DONE+=("$s")
  else
    warn "$s exited non-zero"
    FAILED+=("$s")
    (( FAIL_FAST )) && die "aborting after $s (--fail-fast)"
  fi
  return 0
}

# ---------- output ----------

print_catalog() {
  local s
  printf '  %-30s %-10s %-9s %s\n' SCRIPT GROUP SUDO SUMMARY
  for s in "${ORDER[@]}"; do
    printf '  %-30s %-10s %-9s %s\n' \
      "$s" "${M_GROUP[$s]:-?}" "${M_SUDO[$s]:-none}" "${M_SUMMARY[$s]:-}"
  done
}

print_advisory() {
  cat <<EOF

==> Optional extras were not installed (no terminal — nothing was changed).

    Run this from a real terminal to pick interactively:
        $HERE/install_all.sh
    Or non-interactively:
        $HERE/install_all.sh --only=tailscale,claude_code
        DOTFILES_INSTALL_ALL=all $HERE/install_all.sh

Available:
EOF
  print_catalog
  echo
}

print_summary() {
  echo
  say "install_all.sh summary"
  (( ${#DONE[@]}    )) && say  "ran:     ${DONE[*]}"
  (( ${#SKIPPED[@]} )) && warn "skipped: ${SKIPPED[*]}"
  (( ${#BLOCKED[@]} )) && warn "blocked: ${BLOCKED[*]}"
  (( ${#FAILED[@]}  )) && warn "failed:  ${FAILED[*]}"

  # tailscale up needs an interactive browser login, so install_tailscale.sh
  # only prints it. That means tailscale0 does not exist yet, and mosh's tailnet
  # rules were skipped with a NOTES warning rather than an error.
  if in_list install_tailscale.sh "${DONE[@]:-}" && in_list install_mosh_server.sh "${DONE[@]:-}"; then
    echo
    warn "tailscale and mosh ran in the same pass: the tailnet firewall rules were"
    warn "skipped because tailscale0 does not exist until you authenticate. Run"
    warn "'sudo tailscale up --ssh' and then re-run install_mosh_server.sh."
  fi

  if (( ${#FAILED[@]} )); then
    echo
    warn "if a failure mentions 'could not get lock', unattended-upgrades holds the"
    warn "apt lock — wait for it to finish and re-run."
  fi
  (( ${#FAILED[@]} == 0 ))
}

# ---------- main ----------

main() {
  parse_args "$@"
  load_metadata
  validate_order

  # --check and --list only read metadata, so they work on any platform on
  # purpose: --check is a pre-commit gate alongside `bash -n`, and it is no use
  # if it can only run on the machine being provisioned.
  case "$MODE" in
    check) say "metadata and ORDER agree (${#ORDER[@]} scripts)"; exit 0 ;;
    list)  print_catalog; exit 0 ;;
  esac

  [[ "$(uname -s)" == "Linux" ]] || die "this is the Ubuntu orchestrator; on macOS see scripts/macOS/"
  [[ "$(id -u)" -ne 0 ]] || die "do not run this as root: install_claude_code.sh refuses root, and link.sh would symlink into /root"

  # A child invoking bootstrap.sh, which invokes this, must not recurse.
  [[ -z "${DOTFILES_INSTALL_ALL_ACTIVE:-}" ]] \
    || die "install_all.sh is already running (a child invoked it); refusing to recurse"
  export DOTFILES_INSTALL_ALL_ACTIVE=1

  [[ "$MODE" == advise ]] && { print_advisory; exit 0; }

  # bootstrap.sh runs the core scripts itself, around a load-bearing
  # ~/.zshrc sequence this script must not get between. When it calls us, the
  # core four are already done — record them so `requires:` still resolves.
  if [[ -n "${DOTFILES_BOOTSTRAP_ACTIVE:-}" ]]; then
    local s
    for s in "${ORDER[@]}"; do
      [[ "${M_GROUP[$s]}" == core ]] && DONE+=("$s")
    done
  fi

  select_scripts
  if (( ${#SELECTED[@]} == 0 )); then
    say "Nothing selected."
    print_summary || true
    exit 0
  fi

  preflight_sudo

  local s
  for s in "${SELECTED[@]:-}"; do run_one "$s"; done

  print_summary
}

main "$@"
