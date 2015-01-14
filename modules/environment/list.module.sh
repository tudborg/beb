
environment_list_usage () {
    cat <<EOL
Usage:
    $SCRIPT_MAIN list
        This message.

    $SCRIPT_MAIN list [<application name>]
        List available environments.
        Optionally filter by application name.
EOL
}

environment_list_main () {
    local envdata opt appname

    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            environment_list_usage
            return 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "1" ]; then
        # no app name, list all envs
        envdata="$(aws elasticbeanstalk describe-environments \
            --output=text | grep '^ENVIRONMENTS')"
        if [ "$?" -gt 0 ]; then
            return 1
        fi
    else
        appname="$1"
        envdata="$(aws elasticbeanstalk describe-environments \
            --output=text \
            --application-name="$appname" | grep '^ENVIRONMENTS')"
        if [ "$?" -gt 0 ]; then
            return 1
        fi
    fi
    # check number of environments
    if [ "$(echo -n "$envdata" | wc -w)" -eq 0 ]; then
        0warning "Didn't find any environments"
        return 1
    fi

    while read line
    do
        local envname="$(echo "$line" | cut -f 2)"
        local updated="$(echo "$line" | cut -f 5)"
        local health="$(echo "$line" | cut -f 10)"
        local stack="$(echo "$line" | cut -f 11)"
        local state="$(echo "$line" | cut -f 12)"
        local release="$(echo "$line" | cut -f 13)"

        cat <<EOL
Name:       $envname
Health:     $health
Stack:      $stack
State:      $state
updated:    $updated
release:    $release
------------------------------------------------------------
EOL

    done < <(echo "$envdata")



}
