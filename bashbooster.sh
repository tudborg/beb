# Bash Booster 0.2beta <http://www.bashbooster.net>
# =================================================
#
# Copyright (c) 2014, Dmitry Vakhrushev <self@kr41.net> and Contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

##
# ./source/00_var.sh
#

bb-var() {
    local VAR_NAME=$1
    local DEFAULT=$2
    if [[ -z "${!VAR_NAME}" ]]
    then
        eval "$VAR_NAME='$DEFAULT'"
    fi
}

##
# ./source/01_log.sh
#

BB_LOG_DEBUG=1
BB_LOG_INFO=2
BB_LOG_WARNING=3
BB_LOG_ERROR=4

declare -A BB_LOG_LEVEL_NAME
BB_LOG_LEVEL_NAME[$BB_LOG_DEBUG]='DEBUG'
BB_LOG_LEVEL_NAME[$BB_LOG_INFO]='INFO '
BB_LOG_LEVEL_NAME[$BB_LOG_WARNING]='WARN '
BB_LOG_LEVEL_NAME[$BB_LOG_ERROR]='ERROR'

declare -A BB_LOG_LEVEL_CODE
BB_LOG_LEVEL_CODE['DEBUG']=$BB_LOG_DEBUG
BB_LOG_LEVEL_CODE['INFO']=$BB_LOG_INFO
BB_LOG_LEVEL_CODE['WARNING']=$BB_LOG_WARNING
BB_LOG_LEVEL_CODE['ERROR']=$BB_LOG_ERROR

bb-var BB_LOG_LEVEL $BB_LOG_INFO
bb-var BB_LOG_PREFIX "$( basename "$0" )"
bb-var BB_LOG_TIME 'date +"%Y-%m-%d %H:%M:%S"'
bb-var BB_LOG_FORMAT '${PREFIX} [${LEVEL}] ${MESSAGE}'
bb-var BB_LOG_USE_COLOR false

$BB_LOG_USE_COLOR && BB_LOG_FORMAT="\${COLOR}${BB_LOG_FORMAT}\${NOCOLOR}"

bb-var BB_LOG_FORMAT "$BB_LOG_DEFAULT_FORMAT"

declare -A BB_LOG_COLORS
BB_LOG_COLORS[$BB_LOG_DEBUG]='\e[1;30m'      # Dark Gray
BB_LOG_COLORS[$BB_LOG_INFO]='\e[0;32m'       # Green
BB_LOG_COLORS[$BB_LOG_WARNING]='\e[0;33m'    # Brown/Orange
BB_LOG_COLORS[$BB_LOG_ERROR]='\e[0;31m'      # Red
BB_LOG_COLORS['NC']='\e[0m'

bb-log-level-code() {
    local CODE=$(( $BB_LOG_LEVEL ))
    if (( $CODE == 0 ))
    then
        CODE=$(( ${BB_LOG_LEVEL_CODE[$BB_LOG_LEVEL]} ))
    fi
    echo $CODE
}

bb-log-level-name() {
    local NAME="$BB_LOG_LEVEL"
    if (( $BB_LOG_LEVEL != 0 ))
    then
        NAME="${BB_LOG_LEVEL_NAME[$BB_LOG_LEVEL]}"
    fi
    echo $NAME
}

bb-log-prefix() {
    local PREFIX="$BB_LOG_PREFIX"
    local i=2
    while echo "${FUNCNAME[$i]}" | grep -q '^bb-log' || \
          [[ "${FUNCNAME[$i]}" == 'bb-exit' ]] || \
          [[ "${FUNCNAME[$i]}" == 'bb-cleanup' ]]
    do
        i=$(( $i + 1 ))
    done
    if echo "${FUNCNAME[$i]}" | grep -q '^bb-'
    then
        PREFIX=$( echo "${FUNCNAME[$i]}" | awk '{ split($0, PARTS, "-"); print PARTS[1]"-"PARTS[2] }' )
    fi
    echo "$PREFIX"
}

bb-log-msg() {
    local LEVEL_CODE=$(( $1 ))
    if (( $LEVEL_CODE >= $( bb-log-level-code ) ))
    then
        local MESSAGE="$2"
        local PREFIX="$( bb-log-prefix )"
        local TIME="$( eval "$BB_LOG_TIME" )"
        local LEVEL="${BB_LOG_LEVEL_NAME[$LEVEL_CODE]}"
        local COLOR="${BB_LOG_COLORS[$LEVEL_CODE]}"
        local NOCOLOR="${BB_LOG_COLORS['NC']}"
        eval "echo -e $BB_LOG_FORMAT" >&2
    fi
}

bb-log-debug() {
    bb-log-msg $BB_LOG_DEBUG "$*"
}

bb-log-info() {
    bb-log-msg $BB_LOG_INFO "$*"
}

bb-log-warning() {
    bb-log-msg $BB_LOG_WARNING "$*"
}

bb-log-error() {
    bb-log-msg $BB_LOG_ERROR "$*"
}

bb-log-deprecated() {
    local ALTERNATIVE="$1"
    local CURRENT="${2-${FUNCNAME[1]}}"
    bb-log-warning "'$CURRENT' is deprecated, use '$ALTERNATIVE' instead"
}

bb-log-callstack() {
    local FRAME=$(( ${1-"1"} ))
    local MSG="Call stack is:"
    for (( i = $FRAME; i < ${#FUNCNAME[@]}; i++ ))
    do
        MSG="$MSG\n\t${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}\t${FUNCNAME[$i]}()"
    done
    bb-log-debug "$MSG"
}

##
# ./source/02_exit.sh
#

bb-exit() {
    local CODE=$(( $1 ))
    shift
    if (( $CODE == 0 ))
    then
        bb-log-info "$@"
    else
        bb-log-error "$@"
        bb-log-callstack 2
    fi
    exit $CODE
}

##
# ./source/03_assert.sh
#

BB_ASSERT_ERROR=3

bb-assert() {
    # Local vars are prefixed to avoid conflicts with ASSERTION expression
    local __ASSERTION="$1"
    local __MESSAGE="${2-Assertion error '$__ASSERTION'}"

    if ! eval "$__ASSERTION"
    then
        bb-exit $BB_ASSERT_ERROR "$__MESSAGE"
    fi
}

##
# ./source/04_ext.sh
#

declare -A BB_EXT_BODIES

bb-ext-python() {
    local NAME="$1"
    BB_EXT_BODIES[$NAME]="$( cat )"

    eval "$NAME() { python -c \"\${BB_EXT_BODIES[$NAME]}\" \"\$@\"; }"
}

##
# ./source/09_exe.sh
#

bb-exe?() {
    local EXE="$1"
    type -t "$EXE" > /dev/null
}

##
# ./source/10_workspace.sh
#

bb-var BB_WORKSPACE ".bb-workspace"

BB_WORKSPACE_ERROR=10

bb-workspace-init() {
    bb-log-debug "Initializing workspace at '$BB_WORKSPACE'"
    if [[ ! -d "$BB_WORKSPACE" ]]
    then
        mkdir -p "$BB_WORKSPACE" || \
        bb-exit $BB_WORKSPACE_ERROR "Failed to initialize workspace at '$BB_WORKSPACE'"
    fi

    # Ensure BB_WORKSPACE stores absolute path
    cd "$BB_WORKSPACE"
    BB_WORKSPACE="$( pwd )"
    cd - > /dev/null
}

bb-workspace-cleanup() {
    bb-log-debug "Cleaning up workspace at '$BB_WORKSPACE'"
    if [[ -z "$( ls "$BB_WORKSPACE" )" ]]
    then
        bb-log-debug "Workspace is empty. Removing"
        rm -rf "$BB_WORKSPACE"
    else
        bb-log-debug "Workspace is not empty"
    fi
}

##
# ./source/11_tmp.sh
#

bb-tmp-init() {
    if [[ -d "$BB_WORKSPACE/tmp" ]]
    then
        rm -rf "$BB_WORKSPACE/tmp/"
    fi
    mkdir "$BB_WORKSPACE/tmp"
}

bb-tmp-file() {
    FILENAME="$BB_WORKSPACE/tmp/$( date +%s )$RANDOM"
    touch "$FILENAME"
    echo "$FILENAME"
}

bb-tmp-dir() {
    DIRNAME="$BB_WORKSPACE/tmp/$( date +%s%N )"
    mkdir -p "$DIRNAME"
    echo "$DIRNAME"
}

bb-tmp-cleanup() {
    rm -rf "$BB_WORKSPACE/tmp"
}

##
# ./source/12_template.sh
#

bb-template() {
    local TEMPLATE="$1"
    eval "echo \"$( < $TEMPLATE )\""
}

##
# ./source/13_properties.sh
#

bb-properties-read() {
    bb-log-deprecated 'bb-read-properties'
    bb-read-properties "$@"
}

##
# ./source/20_event.sh
#

declare -A BB_EVENT_DEPTH
BB_EVENT_DELAY_DEPTH=0
BB_EVENT_MAX_DEPTH=1000
BB_EVENT_ERROR_MAX_DEPTH_REACHED=20

bb-event-init() {
    BB_EVENT_DIR="$( bb-tmp-dir )"
}

bb-event-on() {
    local EVENT=$1
    local HANDLER=$2
    local HANDLERS="$BB_EVENT_DIR/$EVENT.handlers"
    touch "$HANDLERS"
    if [[ -z "$( cat "$HANDLERS" | grep "^$HANDLER\$" )" ]]
    then
        bb-log-debug "Subscribed handler '$HANDLER' on event '$EVENT'"
        echo "$HANDLER" >> "$HANDLERS"
    fi
}

bb-event-off() {
    local EVENT=$1
    local HANDLER=$2
    local HANDLERS="$BB_EVENT_DIR/$EVENT.handlers"
    if [[ -f "$HANDLERS" ]]
    then
        bb-log-debug "Removed handler '$HANDLER' from event '$EVENT'"
        cat "$HANDLERS" | grep -v "^$HANDLER\$" > "$HANDLERS"
    fi
}

bb-event-fire() {
    local EVENT=$1
    shift
    [[ -n "$EVENT" ]] || return 0
    BB_EVENT_DEPTH["$EVENT"]=$(( ${BB_EVENT_DEPTH["$EVENT"]} + 1 ))
    if (( ${BB_EVENT_DEPTH["$EVENT"]} >= $BB_EVENT_MAX_DEPTH ))
    then
        bb-exit $BB_EVENT_ERROR_MAX_DEPTH_REACHED "Max recursion depth has been reached on processing event '$EVENT'"
    fi
    if [[ -f "$BB_EVENT_DIR/$EVENT.handlers" ]]
    then
        bb-log-debug "Run handlers for event '$EVENT'"
        while read -r HANDLER
        do
            eval "$HANDLER $@"
        done < "$BB_EVENT_DIR/$EVENT.handlers"
    fi
    BB_EVENT_DEPTH["$EVENT"]=$(( ${BB_EVENT_DEPTH["$EVENT"]} - 1 ))
}

bb-event-delay() {
    local EVENT="$@"
    local EVENTS="$BB_EVENT_DIR/events"
    [[ -n "$EVENT" ]] || return 0
    touch "$EVENTS"
    if [[ -z "$( cat "$EVENTS" | grep "^$EVENT\$" )" ]]
    then
        bb-log-debug "Delayed event '$EVENT'"
        echo "$EVENT" >> "$EVENTS"
    fi
}

bb-event-cleanup() {
    BB_EVENT_DEPTH["__delay__"]=$(( ${BB_EVENT_DEPTH["__delay__"]} + 1 ))
    if (( ${BB_EVENT_DEPTH["__delay__"]} >= $BB_EVENT_MAX_DEPTH ))
    then
        bb-exit $BB_EVENT_ERROR_MAX_DEPTH_REACHED "Max recursion depth has been reached on processing event '__delay__'"
        return $?
    fi
    local EVENTS="$BB_EVENT_DIR/events"
    if [[ -f "$EVENTS" ]]
    then
        local EVENT_LIST="$( bb-tmp-file )"
        cp -f "$EVENTS" "$EVENT_LIST"
        rm "$EVENTS"
        while read -r EVENT
        do
            bb-event-fire $EVENT
        done < "$EVENT_LIST"
        # If any event hadler calls "bb-event-delay", the "$EVENTS" file
        # will be created again and we should repeat this processing
        if [[ -f "$EVENTS" ]]
        then
            bb-event-cleanup
        fi
    fi
    BB_EVENT_DEPTH["__delay__"]=$(( ${BB_EVENT_DEPTH["__delay__"]} - 1 ))
}

##
# ./source/30_download.sh
#

bb-download-init() {
    BB_DOWNLOAD_DIR="$BB_WORKSPACE/download"
}

bb-download() {
    if [[ ! -d "$BB_DOWNLOAD_DIR" ]]
    then
        bb-log-debug "Creating download directory at '$BB_DOWNLOAD_DIR'"
        mkdir "$BB_DOWNLOAD_DIR"
    fi

    local URL="$1"
    local TARGET="${2-$( basename "$URL" )}"
    TARGET="$BB_DOWNLOAD_DIR/$TARGET"

    bb-log-info "Downloading $URL"
    wget -O "$TARGET" -nc "$URL"
    echo "$TARGET"
}

bb-download-clean() {
    rm -rf "$BB_DOWNLOAD_DIR"
}

##
# ./source/30_flag.sh
#

bb-flag-init() {
    BB_FLAG_DIR="$BB_WORKSPACE/flag"
}

bb-flag?() {
    local FLAG="$1"
    [[ -f "$BB_FLAG_DIR/$FLAG" ]]
}

bb-flag-set() {
    local FLAG="$1"
    if [[ ! -d "$BB_FLAG_DIR" ]]
    then
        bb-log-debug "Creating flag directory at '$BB_DOWNLOAD_DIR'"
        mkdir "$BB_FLAG_DIR"
    fi
    touch "$BB_FLAG_DIR/$FLAG"
}

bb-flag-unset() {
    local FLAG="$1"
    [[ ! -f "$BB_FLAG_DIR/$FLAG" ]] || rm "$BB_FLAG_DIR/$FLAG"
}

bb-flag-clean() {
    bb-log-debug "Removing flag directory"
    rm -rf "$BB_FLAG_DIR"
}

bb-flag-cleanup() {
    if [[ -d "$BB_FLAG_DIR" && -z "$( ls "$BB_FLAG_DIR" )" ]]
    then
        bb-log-debug "Flag directory is empty"
        bb-flag-clean
    fi
}

##
# ./source/30_read.sh
#

# normalizing, reading and evaluating key=value lines from the properties file
# regexp searches for lines with key=value, key:value, key: value etc.. pattern,
# see http://docs.oracle.com/javase/7/docs/api/java/util/Properties.html#load(java.io.Reader)
bb-ext-python 'bb-read-properties-helper' <<EOF
import re
import sys

filename = sys.argv[1]
prefix = sys.argv[2]
with open(filename, 'r') as properties:
    for line in properties:
        line = line.strip()
        match = re.match(r'^(?P<key>[^#!]*?)[\s:=]+(?P<value>.+)', line)
        if match:
            match = match.groupdict()
            match['key'] = re.sub(r'[\W]', '_', match['key'])
            print('{prefix}{key}="{value}"'.format(prefix=prefix, **match))
EOF

bb-read-properties() {
    local FILENAME="$1"
    local PREFIX="$2"

    if [[ ! -r "$FILENAME" ]]
    then
        bb-log-error "'$FILENAME' is not readable"
        return 1
    fi

    eval "$( bb-read-properties-helper "$FILENAME" "$PREFIX" )"
}


bb-ext-python 'bb-read-ini-helper' <<EOF
import re
import sys
try:
    from ConfigParser import SafeConfigParser as ConfigParser
except ImportError:
    # Python 3.x
    from configparser import ConfigParser

filename = sys.argv[1]
section = sys.argv[2]
prefix = sys.argv[3]
reader = ConfigParser()
reader.read(filename)

if not section or section == '*':
    sections = reader.sections()
else:
    sections = [section]
for section in sections:
    for key, value in reader.items(section):
        section = re.sub(r'[\W]', '_', section)
        key = re.sub(r'[\W]', '_', key)
        print(
            '{prefix}{section}_{key}="{value}"'.format(
                prefix=prefix,
                section=section,
                key=key,
                value=value
            )
        )
EOF

bb-read-ini() {
    local FILENAME="$1"
    local SECTION="$2"
    local PREFIX="$3"

    if [[ ! -r "$FILENAME" ]]
    then
        bb-log-error "'$FILENAME' is not readable"
        return 1
    fi

    eval "$( bb-read-ini-helper "$FILENAME" "$SECTION" "$PREFIX" )"
}


bb-ext-python 'bb-read-json-helper' <<EOF
import re
import sys
import json

filename = sys.argv[1]
prefix = sys.argv[2]

def serialize(value, name):
    if value is None:
        print('{0}=""'.format(name))
    elif hasattr(value, 'items'):
        for key, subvalue in value.items():
            key = re.sub(r'[\W]', '_', key)
            serialize(subvalue, name + '_' + key)
    elif hasattr(value, '__iter__'):
        print("{0}_len={1}".format(name, len(value)))
        for i, v in enumerate(value):
            serialize(v, name + '_' + str(i))
    else:
        print('{0}="{1}"'.format(name, value))

with open(filename, 'r') as json_file:
    data = json.load(json_file)
    serialize(data, prefix)

EOF

bb-read-json() {
    local FILENAME="$1"
    local PREFIX="$2"

    if [[ ! -r "$FILENAME" ]]
    then
        bb-log-error "'$FILENAME' is not readable"
        return 1
    fi

    eval "$( bb-read-json-helper "$FILENAME" "$PREFIX" )"
}


bb-ext-python 'bb-read-yaml-helper' <<EOF
import re
import sys
import yaml

filename = sys.argv[1]
prefix = sys.argv[2]

def serialize(value, name):
    if value is None:
        print('{0}=""'.format(name))
    elif hasattr(value, 'items'):
        for key, subvalue in value.items():
            key = re.sub(r'[\W]', '_', key)
            serialize(subvalue, name + '_' + key)
    elif hasattr(value, '__iter__'):
        print("{0}_len={1}".format(name, len(value)))
        for i, v in enumerate(value):
            serialize(v, name + '_' + str(i))
    else:
        print('{0}="{1}"'.format(name, value))

with open(filename, 'r') as yaml_file:
    data = yaml.load(yaml_file)
    serialize(data, prefix)

EOF

bb-ext-python 'bb-read-yaml?' <<EOF
try:
    import yaml
except ImportError:
    exit(1)

EOF

bb-read-yaml() {
    local FILENAME="$1"
    local PREFIX="$2"

    if [[ ! -r "$FILENAME" ]]
    then
        bb-log-error "'$FILENAME' is not readable"
        return 1
    fi

    eval "$( bb-read-yaml-helper "$FILENAME" "$PREFIX" )"
}



##
# ./source/30_sync.sh
#

bb-sync-file() {
    local DST_FILE="$1"
    local SRC_FILE="$2"
    shift 2
    local EVENT="$@"
    if [[ ! -f "$DST_FILE" ]]
    then
        touch "$DST_FILE"
        bb-event-delay $EVENT
    fi
    if [[ -n "$( diff -q "$SRC_FILE" "$DST_FILE" )" ]]
    then
        cp -f "$SRC_FILE" "$DST_FILE"
        bb-event-delay $EVENT
    fi
}

bb-sync-dir() {
    local DST_DIR="$1"
    local SRC_DIR="$2"
    shift 2
    local EVENT="$@"
    if [[ ! -d "$DST_DIR" ]]
    then
        mkdir -p "$DST_DIR"
        bb-event-delay $EVENT
    fi

    local ORIGINAL_DIR="$( pwd )"

    cd "$SRC_DIR"
    while read -r NAME
    do
        if [[ -f "$SRC_DIR/$NAME" ]]
        then
            bb-sync-file "$DST_DIR/$NAME" "$SRC_DIR/$NAME" "$EVENT"
        elif [[ -d "$SRC_DIR/$NAME" ]]
        then
            bb-sync-dir "$DST_DIR/$NAME" "$SRC_DIR/$NAME" "$EVENT"
        fi
    done < <( ls )
    cd "$DST_DIR"
    while read -r FILE
    do
        if [[ ! -e "$SRC_DIR/$FILE" ]]
        then
            rm -rf "$DST_DIR/$FILE"
            bb-event-delay $EVENT
        fi
    done < <( find . )

    cd "$ORIGINAL_DIR"
}

##
# ./source/30_wait.sh
#

bb-wait() {
    local __CONDITION="$1"
    local __TIMEOUT="$2"
    local __COUNTER=$(( $__TIMEOUT ))

    while ! eval "$__CONDITION"
    do
        sleep 1
        if [[ -n "$__TIMEOUT" ]]
        then
            __COUNTER=$(( $__COUNTER - 1 ))
            if (( $__COUNTER <= 0 ))
            then
                bb-log-error "Timeout has been reached during wait for '$__CONDITION'"
                return 1
            fi
        fi
    done
}

##
# ./source/50_apt.sh
#

bb-var BB_APT_UPDATED false

bb-apt?() {
    bb-exe? apt-get
}

bb-apt-repo?() {
    local REPO=$1
    cat /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null | grep -v '^#' | grep -qw "$REPO"
}

bb-apt-package?() {
    local PACKAGE=$1
    dpkg -s "$PACKAGE" 2> /dev/null | grep -q '^Status:.\+installed'
}

bb-apt-update() {
    $BB_APT_UPDATED && return 0
    bb-log-info 'Updating apt cache'
    apt-get update
    BB_APT_UPDATED=true
}

bb-apt-install() {
    for PACKAGE in "$@"
    do
        if ! bb-apt-package? "$PACKAGE"
        then
            bb-apt-update
            bb-log-info "Installing package '$PACKAGE'"
            apt-get install -y "$PACKAGE"
            local STATUS=$?
            if (( $STATUS == 0 ))
            then
                bb-event-fire "bb-package-installed" "$PACKAGE"
            else
                bb-exit $STATUS "Failed to install package '$PACKAGE'"
            fi
        fi
    done
}

##
# ./source/50_yum.sh
#

bb-var BB_YUM_UPDATED false

bb-yum?() {
    bb-exe? yum
}

bb-yum-repo?() {
    local REPO=$1
    yum -C repolist | grep -qw "^$REPO"
}

bb-yum-package?() {
    local PACKAGE=$1
    yum -C list installed "$PACKAGE" &> /dev/null
}

bb-yum-update() {
    $BB_YUM_UPDATED && return 0
    bb-log-info 'Updating yum cache'
    yum clean all
    yum makecache
    BB_YUM_UPDATED=true
}

bb-yum-install() {
    for PACKAGE in "$@"
    do
        if ! bb-yum-package? "$PACKAGE"
        then
            bb-yum-update
            bb-log-info "Installing package '$PACKAGE'"
            yum install -y "$PACKAGE"
            local STATUS=$?
            if (( $STATUS == 0 ))
            then
                bb-event-fire "bb-package-installed" "$PACKAGE"
            else
                bb-exit $STATUS "Failed to install package '$PACKAGE'"
            fi
        fi
    done
}

##
# ./source/99_init.sh
#

bb-workspace-init
bb-tmp-init
bb-event-init
bb-download-init
bb-flag-init

bb-cleanup() {
    bb-event-fire bb-cleanup

    bb-flag-cleanup
    bb-event-cleanup
    bb-tmp-cleanup
    bb-workspace-cleanup
}

trap bb-cleanup EXIT

