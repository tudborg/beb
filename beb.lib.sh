
function is_git_repo {
    git --git-dir "$1"/.git --work-tree "$1" status --porcelain >/dev/null 2>/dev/null
    return $?
}

function get_git_tagish {
    git --git-dir "$1"/.git --work-tree "$1" describe --dirty=-dirty --always --tags --long | sed 's/\//_/'
}



#
# Util to ask user Y/N questions
# https://gist.github.com/davejamesmiller/1965569
#
ask() {
    # http://djm.me/ask
    while true; do
 
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
 
        # Ask the question
        read -p "$1 [$prompt] " REPLY
 
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
 
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
 
    done
}


#http://stackoverflow.com/questions/7126580/expand-a-possible-relative-path-in-bash
function dir_resolve {
  local dir=`dirname "$1"`
  local file=`basename "$1"`
  pushd "$dir" &>/dev/null || return $? # On error, return error code
  echo "`pwd -P`/$file" # output full, link-resolved path with filename
  popd &> /dev/null
}