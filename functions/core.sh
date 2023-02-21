

function h() {
  if [ -z "$1" ]
  then
    history
  else
    history | grep "$@"
  fi
}


