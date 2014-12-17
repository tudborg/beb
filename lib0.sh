##
## Lib0
## Extremely simple bash library
##
## Bunch of stuff ported from the bashbooster library.
## Reason for not using bashbooster directly is that bashbooster requires
## bash 4, and contains a lot of stuff that doesn't belong in a tiny
## base library.
##

## SETTINGS

# debugging
LIB0_DEBUG=${LIB0_DEBUG:-true}


###
##  Logging
###

# default logging format
LIB0_DEFAULT_LOG_FORMAT='${TIME} [${LEVEL}] ${MESSAGE}'
# log info and up
LIB0_DEFAULT_LOG_LEVEL_NUM=2

LIB0_LOG_LEVEL_DEBUG=1
LIB0_LOG_LEVEL_INFO=2
LIB0_LOG_LEVEL_WARNING=3
LIB0_LOG_LEVEL_ERROR=4

LIB0_LOG_LEVEL_LABELS_DEBUG='DEBU'
LIB0_LOG_LEVEL_LABELS_INFO='INFO'
LIB0_LOG_LEVEL_LABELS_WARNING='WARN'
LIB0_LOG_LEVEL_LABELS_ERROR='ERRO'

LIB0_LOG_COLOR_DEBUG='\033[1;90m'
LIB0_LOG_COLOR_INFO='\033[0;32m'
LIB0_LOG_COLOR_WARNING='\033[0;33m'
LIB0_LOG_COLOR_ERROR='\033[0;31m'
LIB0_LOG_COLOR_NONE='\033[0m'

lib0-log-msg () {
    ##
    ## Write log message to stdout
    ##
    local LEVELNAME="$1"
    local LEVELNUMVAR="LIB0_LOG_LEVEL_${LEVELNAME}"
    local LEVELLABELVAR="LIB0_LOG_LEVEL_LABELS_${LEVELNAME}"
    local LEVELCOLORVAR="LIB0_LOG_COLOR_${LEVELNAME}"
    local LEVELNUM="$(eval echo "\$$LEVELNUMVAR")"
    local LEVELCOLOR="$(eval echo "\$$LEVELCOLORVAR")"
    local LEVELLABEL="$(eval echo "\$$LEVELLABELVAR")"

    LEVELCOLOR="$LIB0_LOG_COLOR_WARNING"

    local LEVEL="${LEVELCOLOR}${LEVELLABEL}${LIB0_LOG_COLOR_NONE}"

    if [ "$LEVELNUM" -ge "${LIB0_LOG_LEVEL:-$LIB0_DEFAULT_LOG_LEVEL_NUM}" ]; then
        local MESSAGE="$2"
        local TIME="$(date +"%Y-%m-%d %H:%M:%S")"
        eval "echo -e ${LIB0_LOG_FORMAT:-$LIB0_DEFAULT_LOG_FORMAT}" >&2
    fi
}

lib0-log-debug () {
    lib0-log-msg "DEBUG" "$@"
}

lib0-log-info () {
    lib0-log-msg "INFO" "$@"
}

lib0-log-warning () {
    lib0-log-msg "WARNING" "$@"
}

lib0-log-error () {
    lib0-log-msg "ERROR" "$@"
}


# shortcuts
0debug () {
    lib0-log-msg "DEBUG" "$@"
}

0info () {
    lib0-log-msg "INFO" "$@"
}

0warning () {
    lib0-log-msg "WARNING" "$@"
}

0error () {
    lib0-log-msg "ERROR" "$@"
}

# if LIB0_DEBUG is set to true,
# set default log output to debug level
if [ "$LIB0_DEBUG" = true ]; then
    LIB0_DEFAULT_LOG_LEVEL_NUM=1
fi







##
## Abort and exit utils
##

0exit() {
    ##
    ## Handle exit. args:
    ## <exitcode> [<message>]
    ##

    if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
       echo "0exit called with invalid first argument." >&2
       stacktrace
       exit 1
    fi
    local code="$1"
    shift

    if [ ! -z "$*" ]; then
        if [ "$code" -eq 0 ]; then
            lib0-log-info "$@"
        else
            lib0-log-error "$@"
        fi
    fi

    exit $code
}


0trigger-exit-remove () {
    for name in ${__ON_EXIT_REMOVE[@]}; do
        # To protect accidental deleting of root folders, we check that name is longer than 5 characters.
        # This is a pretty stupid protection, and should be fixed to something better
        if [ ${#name} -gt 5 ]; then
            #rm -rf "$name"
            echo rm -rf "$name"
        else
            0warning "Refusing to delete '$name'"
        fi
    done
    __ON_EXIT_REMOVE=()
}

__ON_EXIT_REMOVE=()
0on-exit-remove () {
    ##
    ## When exit is called, just before exiting, remove the files/directories
    ## registered with this function
    ##
    local name
    for name in "$@"; do
        __ON_EXIT_REMOVE+=("$name")
    done
}

# Bind the cleaner function to EXIT
trap 0trigger-exit-remove EXIT


##
## Debugging
##

## From http://www.runscripts.com/support/guides/scripting/bash/debugging-bash/stack-trace
stacktrace ()
{
    declare frame=0
    declare argv_offset=0
 
    while caller_info=( $(caller $frame) ) ; do
 
        if shopt -q extdebug ; then
 
            declare argv=()
            declare argc
            declare frame_argc
 
            for ((frame_argc=${BASH_ARGC[frame]},frame_argc--,argc=0; frame_argc >= 0; argc++, frame_argc--)) ; do
                argv[argc]=${BASH_ARGV[argv_offset+frame_argc]}
                case "${argv[argc]}" in
                    *[[:space:]]*) argv[argc]="'${argv[argc]}'" ;;
                esac
            done
            argv_offset=$((argv_offset + ${BASH_ARGC[frame]}))
            echo ":: ${caller_info[2]}: Line ${caller_info[0]}: ${caller_info[1]}(): ${FUNCNAME[frame]} ${argv[*]}"
        fi
 
        frame=$((frame+1))
    done
 
    if [[ $frame -eq 1 ]] ; then
        caller_info=( $(caller 0) )
        echo ":: ${caller_info[2]}: Line ${caller_info[0]}: ${caller_info[1]}"
    fi
}

# set extdebug and set a track that calls stacktrace on error
if [ "$LIB0_DEBUG" = true ]; then
    shopt -s extdebug
    trap 'stacktrace' ERR
    set -o errtrace
fi









##
## Testing utils
##

0exe?() {
    # from bashboosters "bb-exe?"
    type -t "$1" > /dev/null
}


0assert() {
    # From bashboosters "bb-assert"
    local __ASSERTION="$1"
    local __MESSAGE="${2-Assertion error '$__ASSERTION'}"

    if ! eval "$__ASSERTION"
    then
        0exit 1 "$__MESSAGE"
    fi
}



##
## Testing
##



if [ "$LIB0_TEST" = true ]; then

    # log tests
    echo "______ LOG TESTS ______" >&2
    LIB0_LOG_LEVEL=1
    lib0-log-debug "log debug"
    lib0-log-info "log info"
    lib0-log-warning "log warning"
    lib0-log-error "log error"

    # stacktrace
    echo "______ STACK TRACE ______" >&2
    level3 () {
        stacktrace
    }
    level2 () {
        level3 "level3 arg 1" "level3 arg 2"
    }
    level1 () {
        level2 "level2 arg 1" "level2 arg 2"
    }
    level1 "level1 arg 1" "level1 arg 2"


    0on-exit-remove "a" "b" "c"
    0on-exit-remove "d" "e" "f"

    0exit 0

fi

