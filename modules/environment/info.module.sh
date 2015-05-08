
environment_info_usage () {
    cat <<EOL
Usage:
    $SCRIPT_MAIN info
        This message.

    $SCRIPT_MAIN info <environment-name>
        Info about <environment-name>
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
        --query 'Environments[*].[EnvironmentName, VersionLabel, Status, SolutionStackName, Health, DateUpdated]' \
        --environment-names "$envname")"
    if [ "$?" -gt 0 ]; then
        return 1
    fi
    if [ "$(echo -n "$envdata" | wc -w)" -eq 0 ]; then
        0warning "Could not find environment '$envname'"
        return 1
    fi

    local envname="$(echo "$envdata" | cut -f 1)"
    local label="$(echo "$envdata" | cut -f 2)"
    local state="$(echo "$envdata" | cut -f 3)"
    local stack="$(echo "$envdata" | cut -f 4)"
    local health="$(echo "$envdata" | cut -f 5)"
    local updated="$(echo "$envdata" | cut -f 6)"

    cat <<EOL
Name:   	$envname
Health: 	$health
Stack:  	$stack
State:  	$state
updated:	$updated
release:	$label
EOL

}
