
environment_info_usage () {
    cat <<EOL
Usage:
    $SCRIPT_MAIN info
        This message.

    $SCRIPT_MAIN info <environment>
        Info about <environment>
EOL
}

environment_info_main () {

    if [ "$#" -lt 1 ]; then
        environment_info_usage
        exit 1
    fi

    local envname="$1"

    # check that environment is valid
    local envdata
    envdata="$(aws elasticbeanstalk describe-environments \
        --output=text \
        --environment-names "$envname" | grep '^ENVIRONMENTS')"
    if [ "$?" -gt 0 ]; then
        return 1
    fi
    if [ "$(echo -n "$envdata" | wc -w)" -eq 0 ]; then
        0warning "Could not find environment '$envname'"
        return 1
    fi

    local updated="$(echo "$envdata" | cut -f 5)"
    local health="$(echo "$envdata" | cut -f 10)"
    local stack="$(echo "$envdata" | cut -f 11)"
    local state="$(echo "$envdata" | cut -f 12)"
    local release="$(echo "$envdata" | cut -f 13)"

    cat <<EOL
Name:		$envname
Health:		$health
Stack: 		$stack
State:		$state

updated:	$updated
release:	$release
EOL

}
