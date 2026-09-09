#!/bin/zsh
# doctor.zsh — diagnose drift between this Mac and the dotfiles repo.
# Reports (but does not fix):
#   - Missing brew packages from Brewfile / Brewfile.k8s / Brewfile.apple
#   - Symlinks that don't point at $DOTFILES (or are missing)
#   - Shell startup time
#
# Run after `git pull` on a secondary Mac to confirm everything is in sync.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

autoload colors
colors

ok()    { echo $fg[green]"✓"$reset_color" $*"; }
warn()  { echo $fg[yellow]"⚠"$reset_color" $*"; }
fail()  { echo $fg[red]"✗"$reset_color" $*"; }
hdr()   { echo; echo $fg[cyan]"==> $*"$reset_color; }

drift=0            # required: main Brewfile + symlinks. Non-zero exit.
optional_drift=0   # optional toolchains. Reported, but never fails the run.

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

check_symlink "$HOME/.zshrc"               "$DOTFILES/zshrc"
check_symlink "$HOME/.config/starship.toml" "$DOTFILES/configurations/starship.toml"

# ---------- brew bundle ----------
hdr "Brewfile"
if brew bundle check --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
  ok "Brewfile satisfied"
else
  warn "Brewfile drift — missing items below:"
  brew bundle check --file="$DOTFILES/Brewfile" --verbose 2>&1 \
    | grep -E '^→' | sed 's/^/    /'
  drift=$((drift + 1))
fi

if [[ -f "$DOTFILES/Brewfile.k8s" ]]; then
  hdr "Brewfile.k8s"
  if brew bundle check --file="$DOTFILES/Brewfile.k8s" >/dev/null 2>&1; then
    ok "Brewfile.k8s satisfied"
  else
    warn "Brewfile.k8s drift (run scripts/macOS/install_k8s_tools.zsh to fix):"
    brew bundle check --file="$DOTFILES/Brewfile.k8s" --verbose 2>&1 \
      | grep -E '^→' | sed 's/^/    /'
    # Optional: counted separately so it never fails the run, but the
    # summary can still say it happened instead of claiming all is well.
    optional_drift=$((optional_drift + 1))
  fi
fi

if [[ -f "$DOTFILES/Brewfile.aitools" ]]; then
  hdr "Brewfile.aitools"
  if brew bundle check --file="$DOTFILES/Brewfile.aitools" >/dev/null 2>&1; then
    ok "Brewfile.aitools satisfied"
  else
    warn "Brewfile.aitools drift (run scripts/macOS/install_ai_tools.zsh to fix):"
    brew bundle check --file="$DOTFILES/Brewfile.aitools" --verbose 2>&1 \
      | grep -E '^→' | sed 's/^/    /'
    # Optional: counted separately so it never fails the run, but the
    # summary can still say it happened instead of claiming all is well.
    optional_drift=$((optional_drift + 1))
  fi
fi

if [[ -f "$DOTFILES/Brewfile.apple" ]]; then
  hdr "Brewfile.apple"
  if brew bundle check --file="$DOTFILES/Brewfile.apple" >/dev/null 2>&1; then
    ok "Brewfile.apple satisfied"
  else
    warn "Brewfile.apple drift (run scripts/macOS/install_apple_tools.zsh to fix):"
    brew bundle check --file="$DOTFILES/Brewfile.apple" --verbose 2>&1 \
      | grep -E '^→' | sed 's/^/    /'
    # Optional: counted separately so it never fails the run, but the
    # summary can still say it happened instead of claiming all is well.
    optional_drift=$((optional_drift + 1))
  fi
fi

# ---------- shell startup time ----------
hdr "Shell startup"
# EPOCHREALTIME is a shell parameter, so reading it costs nothing. The
# previous version shelled out to /usr/bin/python3 twice per run and paid
# ~60ms of interpreter startup *inside* the interval it was timing, which
# inflated every reported number well above what the shell actually takes.
zmodload zsh/datetime

local -i total=0 i runs=3
for i in {1..$runs}; do
  local start=$EPOCHREALTIME
  # -u CLAUDECODE: zshrc loads nvm eagerly when CLAUDECODE is set, which roughly
  # doubles startup. Inheriting it from an agent session would measure that
  # branch and warn about a budget the real interactive shell never exceeds.
  env -u CLAUDECODE zsh -i -c exit
  local end=$EPOCHREALTIME
  local -i elapsed_ms=$(( (end - start) * 1000 ))
  echo "  run $i: ${elapsed_ms}ms"
  total=$((total + elapsed_ms))
done
local avg=$((total / runs))
# 180ms: the documented budget is ~150ms and this measures ~155ms on a
# healthy machine, so this leaves room for a slow run without letting a
# real regression through. The old 250ms ceiling was set when the timing
# itself added ~60ms of overhead — with that gone it no longer bites.
if (( avg < 180 )); then
  ok "average startup: ${avg}ms"
else
  warn "average startup: ${avg}ms (expected <180ms)"
fi

# ---------- summary ----------
echo
if (( drift == 0 )); then
  if (( optional_drift == 0 )); then
    ok "No drift detected. This Mac is in sync with the repo."
  else
    ok "Core config in sync (Brewfile and symlinks)."
    warn "$optional_drift optional toolchain(s) have drift — see above for the installer to run."
  fi
  exit 0
else
  fail "$drift drift item(s) found. See above for details."
  echo "  Fix with:  ~/.dotfiles/bootstrap.sh"
  exit 1
fi
