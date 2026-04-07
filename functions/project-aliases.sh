# Auto-load per-project alias files when entering their directory.
#
# Replaces the manual `<project>-aliases` loader pattern. To wire up
# a project, add an entry to PROJECT_ALIAS_MAP below mapping a
# directory prefix to an alias file under $DOTFILES/aliases/.
#
# When you `cd` into a registered directory (or any subdirectory of
# it), the matching alias file is sourced exactly once per shell.
# Entries whose directory does not exist are silently skipped, so
# stale projects can stay in the map without causing errors.

typeset -gA PROJECT_ALIAS_MAP=(
  # Personal projects under ~/github-sandbox/cebartling/
  [$HOME/github-sandbox/cebartling/acme-inc-2026]=acme-inc-2026.sh
  [$HOME/github-sandbox/cebartling/aws-cdk-experiments]=aws-cdk-experiments.sh
  [$HOME/github-sandbox/cebartling/aws-explorer]=aws-explorer.sh
  [$HOME/github-sandbox/cebartling/azure-experiments]=azure-experiments.sh
  [$HOME/github-sandbox/cebartling/coding-katas]=coding-katas.sh
  [$HOME/github-sandbox/cebartling/d3-experiments]=d3-experiments.sh
  [$HOME/github-sandbox/cebartling/deck-gl-spikes]=deck-gl-spikes.sh
  [$HOME/github-sandbox/cebartling/gummi-bears]=gummi-bears.sh
  [$HOME/github-sandbox/cebartling/joy-of-react-project-wordle]=joy-of-react.sh
  [$HOME/github-sandbox/cebartling/kafka-experiments]=kafka-experiments.sh
  [$HOME/github-sandbox/cebartling/kubernetes-experiments]=kubernetes-experiments.sh
  [$HOME/github-sandbox/cebartling/nfl-draft-2026]=nfl-draft-2026.sh
  [$HOME/github-sandbox/cebartling/otherworlds-rpg]=otherworlds-rpg.sh
  [$HOME/github-sandbox/cebartling/pneuma]=pneuma.sh
  [$HOME/github-sandbox/cebartling/react-experiments]=react-experiments.sh
  [$HOME/github-sandbox/cebartling/real-python-solutions]=real-python.sh
  [$HOME/github-sandbox/cebartling/remix-ecommerce]=remix-ecommerce.sh
  [$HOME/github-sandbox/cebartling/remix-experiments]=remix-experiments.sh
  [$HOME/github-sandbox/cebartling/saga-pattern-examples]=saga-pattern.sh
  [$HOME/github-sandbox/cebartling/spring-boot-spikes]=spring-boot-spikes.sh
  [$HOME/github-sandbox/cebartling/study-books]=studying.sh
  [$HOME/github-sandbox/cebartling/tailwind-css-experiments]=tailwind-css-experiments.sh
  [$HOME/github-sandbox/cebartling/tauri-experiments]=tauri-experiments.sh
  [$HOME/github-sandbox/cebartling/test-driven]=test-driven.sh
  [$HOME/github-sandbox/cebartling/testcontainers-experiments]=testcontainers-experiments.sh

  # Quizzer has two roots
  [$HOME/github-sandbox/cebartling/certification-exam-quizzer-rails]=quizzer.sh
  [$HOME/github-sandbox/cebartling/certification-exam-quizzer-react]=quizzer.sh

  # Swift projects (different sandbox root)
  [$HOME/git-sandbox/cebartling]=swift.sh

  # Client / external project roots
  [$HOME/github-sandbox/lifetime]=lifetime.sh
  [$HOME/github-sandbox/ReplayForensics]=replay-forensics.sh
  [$HOME/github-sandbox/schoolhouse-educational-services]=wici.sh
)

typeset -gA _PROJECT_ALIASES_LOADED=()

_project_aliases_chpwd() {
  local dir="$PWD"
  local prefix file
  for prefix file in ${(kv)PROJECT_ALIAS_MAP}; do
    if [[ "$dir" == "$prefix" || "$dir" == "$prefix"/* ]]; then
      if [[ -z "${_PROJECT_ALIASES_LOADED[$file]}" ]]; then
        local alias_path="$DOTFILES/aliases/$file"
        if [[ -r "$alias_path" ]]; then
          source "$alias_path"
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
