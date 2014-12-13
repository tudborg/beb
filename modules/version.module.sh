
VERSION_SUBMODULES_DIR="$MODULES_DIR/version"

#
# function for listing available "version" sub-modules
#
function get_version_modules {
    local file
    for file in $(ls $VERSION_SUBMODULES_DIR | grep "$MODULE_FILE_POSTFIX\$")
    do
        echo "${file%$MODULE_FILE_POSTFIX}"
    done
}


function version_usage {

    cat <<EOL
Usage:
    $SCRIPT_MAIN version [-h]
        This message.

    $SCRIPT_MAIN version <cmd> [<args>...]

Commands available:
$(get_version_modules | sed 's/^/    /')
EOL

}




function version_main {

    #
    # Initial check for at least the module name
    #
    if [ "$#" -lt 1 ]; then
        version_usage
        exit 1
    fi

    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            version_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    # as this is a submodule, rewrite script main
    # to be path of submodule root
    local originalmain="$SCRIPT_MAIN"
    SCRIPT_MAIN="$originalmain version"


    #
    # Figure out what submodule to load
    #
    local module="$1"
    shift

    local modulepath="$VERSION_SUBMODULES_DIR/$module.module.sh"
    local modulemainfunc="version_${module}_main"

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
