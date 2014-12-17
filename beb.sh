#!/usr/bin/env bash

unset CDPATH

# define variables available in all modules

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

MODULES_DIR="$SCRIPT_DIR/modules"
SCRIPT_MAIN="${BASH_SOURCE[0]}"

# source our tiny bash lib
source "$SCRIPT_DIR/lib0.sh"

# import our beb specific lib
source "$SCRIPT_DIR/beb.lib.sh"



#
# function for listing available modules
#
main_module_list () {
    module_list "$MODULES_DIR"
    return $?
}



#
# Define our top-level usage message
#
usage () {

    cat <<EOL
Usage:
    
    $0 [-d] [-q] <module> [-h] [<args>...]

    -d      Log at debug level
    -q      Log at warning level

Modules available:

$(main_module_list | sed 's/^/    /')

EOL
}


main () {

    #
    # Initial check for at least the module name
    #
    if [ "$#" -lt 1 ]; then
        usage
        exit 1
    fi


    OPTIND=1
    while getopts dqv opt; do
        case $opt in
        d)
            LIB0_LOG_LEVEL=1
        ;;
        q)
            LIB0_LOG_LEVEL=3
        ;;
        v)
            echo -e "beb\t$(get_git_tagish "$SCRIPT_DIR")"
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    #
    # Figure out what module to load
    #
    local module="$1"
    shift

    local modulepath="$MODULES_DIR/$module.module.sh"
    local modulemainfunc="${module}_main"

    # Load module and run it's main function
    if [ -f "$modulepath" ]; then
        source "$modulepath"
        "$modulemainfunc" "$@" || 0error "Failed to run $module"
    else
        0exit 1 "Unknown module '$module'"
    fi
}

main "$@"
exit $?
