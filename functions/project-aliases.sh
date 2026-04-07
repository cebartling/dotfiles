# Auto-load per-project alias files when entering their directory.
#
# Replaces the manual `<project>-aliases` loader pattern. To wire up
# a project, add an entry to the PROJECT_ALIAS_MAP below mapping a
# directory prefix to an alias file under $DOTFILES/aliases/.
#
# When you `cd` into a registered directory (or any subdirectory of
# it), the matching alias file is sourced exactly once per shell.

typeset -gA PROJECT_ALIAS_MAP=(
  [$HOME/github-sandbox/lifetime]=lifetime.sh
  [$HOME/github-sandbox/cebartling/acme-inc-2026]=acme-inc-2026.sh
  [$HOME/github-sandbox/cebartling/wici]=wici.sh
)

typeset -gA _PROJECT_ALIASES_LOADED=()

_project_aliases_chpwd() {
  local dir="$PWD"
  local prefix file
  for prefix file in ${(kv)PROJECT_ALIAS_MAP}; do
    if [[ "$dir" == "$prefix" || "$dir" == "$prefix"/* ]]; then
      if [[ -z "${_PROJECT_ALIASES_LOADED[$file]}" ]]; then
        local path="$DOTFILES/aliases/$file"
        if [[ -r "$path" ]]; then
          source "$path"
          _PROJECT_ALIASES_LOADED[$file]=1
        fi
      fi
    fi
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _project_aliases_chpwd

# Run once at shell start in case we launched inside a project dir.
_project_aliases_chpwd
