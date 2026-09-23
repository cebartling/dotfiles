

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
}


