##
## Lib0
## Extremely simple bash library
##


###
##  Logging
###

# logging settings

# if true, logging functions will be available by short-name:
# log-info, log-debug, etc
LIB0_LOG_SHORTCUTS=true


# default logging format
LIB0_DEFAULT_LOG_FORMAT='${TIME} [${LEVEL}] ${MESSAGE}'
# log info and up
LIB0_DEFAULT_LOG_LEVEL_NUM=1

LIB0_LOG_LEVEL_DEBUG=1
LIB0_LOG_LEVEL_INFO=2
LIB0_LOG_LEVEL_WARNING=3
LIB0_LOG_LEVEL_ERROR=4

LIB0_LOG_LEVEL_LABELS_DEBUG='DEBU'
LIB0_LOG_LEVEL_LABELS_INFO='INFO'
LIB0_LOG_LEVEL_LABELS_WARNING='WARN'
LIB0_LOG_LEVEL_LABELS_ERROR='ERRO'

LIB0_LOG_COLOR_DEBUG='\e[1;90m'
LIB0_LOG_COLOR_INFO='\e[0;32m'
LIB0_LOG_COLOR_WARNING='\e[0;33m'
LIB0_LOG_COLOR_ERROR='\e[0;31m'
LIB0_LOG_COLOR_NONE='\e[0m'

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

# Shortcut log funcs
if [ "$LIB0_LOG_SHORTCUTS" = true ]; then
    log-debug () {
        lib0-log-msg "DEBUG" "$@"
    }

    log-info () {
        lib0-log-msg "INFO" "$@"
    }

    log-warning () {
        lib0-log-msg "WARNING" "$@"
    }

    log-error () {
        lib0-log-msg "ERROR" "$@"
    }
fi






if [ "$LIB0_TEST" = true ]; then
    # log tests
    echo "______ LOG TESTS ______" >&2
    LIB0_LOG_LEVEL=1
    lib0-log-debug "log debug"
    lib0-log-info "log info"
    lib0-log-warning "log warning"
    lib0-log-error "log error"

fi

