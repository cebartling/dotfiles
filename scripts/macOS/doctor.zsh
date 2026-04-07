#!/bin/zsh
# doctor.zsh — diagnose drift between this Mac and the dotfiles repo.
# Reports (but does not fix):
#   - Missing brew packages from Brewfile / Brewfile.k8s
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

drift=0

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
    # k8s drift is not counted as overall drift since it's optional
  fi
fi

# ---------- shell startup time ----------
hdr "Shell startup"
local total=0 i runs=3
for i in {1..$runs}; do
  local start_ns=$(/usr/bin/python3 -c 'import time; print(int(time.time_ns()))')
  zsh -i -c exit
  local end_ns=$(/usr/bin/python3 -c 'import time; print(int(time.time_ns()))')
  local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  echo "  run $i: ${elapsed_ms}ms"
  total=$((total + elapsed_ms))
done
local avg=$((total / runs))
if (( avg < 250 )); then
  ok "average startup: ${avg}ms"
else
  warn "average startup: ${avg}ms (expected <250ms)"
fi

# ---------- summary ----------
echo
if (( drift == 0 )); then
  ok "No drift detected. This Mac is in sync with the repo."
  exit 0
else
  fail "$drift drift item(s) found. See above for details."
  echo "  Fix with:  ~/.dotfiles/bootstrap.sh"
  exit 1
fi
