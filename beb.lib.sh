
is_git_repo () {
    git --git-dir "$1"/.git --work-tree "$1" status --porcelain >/dev/null 2>/dev/null
    return $?
}

get_git_tagish () {
    git --git-dir "$1"/.git --work-tree "$1" describe --dirty=-dirty --always --tags --long | sed 's/\//_/'
}



#
# Module helpers
#

MODULE_FILE_POSTFIX=".module.sh"

module_list () {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 1
    fi

    local file
    for file in $(ls $dir | grep "$MODULE_FILE_POSTFIX\$")
    do
        echo "${file%$MODULE_FILE_POSTFIX}"
    done
}


#
# Submodule helper
# takes:
#   $modules_dir $root_modules_name $submodname $args...
#
submodule_main () {
    local moddir="$1"
    local modname="$2"
    shift 2

    if [ "$#" -lt 1 ]; then
        local usagefuncname="${modname}_usage"
        if declare -f "$usagefuncname" > /dev/null; then
            eval "$usagefuncname"
        else
            submodule_usage "$moddir" "$modname"
        fi
        exit 1
    fi

    local submodname="$1"
    shift 1

    # as this is a submodule, rewrite script main
    # to be path of submodule root
    local originalmain="$SCRIPT_MAIN"
    SCRIPT_MAIN="$originalmain environment"

    local modulepath="$moddir/${modname}/${submodname}.module.sh"
    local modulemainfunc="${modname}_${submodname}_main"

    # Load module and run it's main function
    if [ -f "$modulepath" ]; then
        source "$modulepath"
        "$modulemainfunc" "$@"
        if [ "$?" -gt 0 ]; then
            bb-exit 1 "Failed to run '${modname}' -> '$submodname'"
        fi
    else
        bb-exit 1 "Unknown submodule '$submodname'"
    fi

    # restore script main
    SCRIPT_MAIN="$originalmain"
}
#
# Helper for undefined usage
# takes
#   $moddir $modname
#
submodule_usage () {
    local moddir="$1"
    local modname="$2"
    cat <<EOL
Usage:
    $SCRIPT_MAIN $modname
        This message.

    $SCRIPT_MAIN $modname <cmd> [<args>...]

Commands available:
$(module_list "$moddir/$modname" | sed 's/^/    /')
EOL
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
dir_resolve () {
  local dir=`dirname "$1"`
  local file=`basename "$1"`
  pushd "$dir" &>/dev/null || return $? # On error, return error code
  echo "`pwd -P`/$file" # output full, link-resolved path with filename
  popd &> /dev/null
}