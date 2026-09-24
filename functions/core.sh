

function h() {
  if [ -z "$1" ]
  then
    history
  else
    history | grep "$@"
  fi
}


# Export GITHUB_TOKEN from the gh CLI's own cached auth, for tools that
# read GITHUB_TOKEN from the environment instead of shelling out to `gh`.
# Also writes it to $GHTOKEN_CACHE (mode 600), which zshrc reads at startup
# so a new shell never waits on `gh`. Run it again after a token rotation.
GHTOKEN_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/ghtoken
function ghtoken() {
  if ! command -v gh >/dev/null 2>&1; then
    print -u2 "ghtoken: gh CLI not found"
    return 1
  fi
  local token
  if ! token=$(gh auth token 2>/dev/null); then
    print -u2 "ghtoken: not logged in — run 'gh auth login'"
    return 1
  fi
  export GITHUB_TOKEN="$token"
  mkdir -p "${GHTOKEN_CACHE:h}" && (umask 077; print -r -- "$token" >| "$GHTOKEN_CACHE")
}


