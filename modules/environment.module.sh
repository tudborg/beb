
ENVIRONMENT_SUBMODULES_DIR="$MODULES_DIR/environment"

#
# function for listing available "environment" sub-modules
#
function get_environment_modules {
    local file
    for file in $(ls $ENVIRONMENT_SUBMODULES_DIR | grep "$MODULE_FILE_POSTFIX\$")
    do
        echo "${file%$MODULE_FILE_POSTFIX}"
    done
}


function environment_usage {

    cat <<EOL
Usage:
    $SCRIPT_MAIN environment [-h]
        This message.

    $SCRIPT_MAIN environment <cmd> [<args>...]

Commands available:
$(get_environment_modules | sed 's/^/    /')
EOL

}




function environment_main {

    #
    # Initial check for at least the module name
    #
    if [ "$#" -lt 1 ]; then
        environment_usage
        exit 1
    fi

    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            environment_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    # as this is a submodule, rewrite script main
    # to be path of submodule root
    local originalmain="$SCRIPT_MAIN"
    SCRIPT_MAIN="$originalmain environment"


    #
    # Figure out what submodule to load
    #
    local module="$1"
    shift

    local modulepath="$ENVIRONMENT_SUBMODULES_DIR/$module.module.sh"
    local modulemainfunc="environment_${module}_main"

    # Load module and run it's main function
    if [ -f "$modulepath" ]; then
        source "$modulepath"
        "$modulemainfunc" "$@" || bb-exit 1 "Failed to run $module"
    else
        bb-exit 1 "Unknown module '$module'"
    fi

    # restore script main
    SCRIPT_MAIN="$originalmain"
}
