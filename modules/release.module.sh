
release_usage () {

    cat <<EOL
Usage:
    $SCRIPT_MAIN release -h
        This message.

    $SCRIPT_MAIN release <label> <environment-name>
        Release <label> to <environment-name>
EOL

}



release_main () {

    # Option parsing
    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            release_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "2" ]; then
        release_usage
        exit 1
    fi

    # assert that we have deps

    0exe? aws || 0exit 1 "Missing AWS CLI ( http://aws.amazon.com/cli/ )"

    local label="$1"
    local environment="$2"

    if [ -z "$label" ]; then
        0exit 1 "Got empty label"
    fi
    if [ -z "$environment" ]; then
        0exit 1 "Got empty environment"
    fi

    # check that environment is valid
    local numapp="$(aws elasticbeanstalk describe-environments \
        --output=text \
        --environment-names "$environment" | wc -l)"
    if [ "$numapp" -eq 0 ]; then
        0exit "Environment with name '$environment' Does not exist"
    fi

    # check that we have a version named <label>
    local numver="$(aws elasticbeanstalk describe-application-versions \
        --output=text \
        --version-labels "$label" | wc -l)"
    if [ "$numver" -lt 1 ]; then
        0exit 1 "Application Version with label "$label" does not exist"
    fi

    # create application version

    aws elasticbeanstalk update-environment \
        --output=text \
        --environment-name "$environment" \
        --version-label "$label" > /dev/null

    if [ "$?" -eq 0 ]; then
        0info "Successfully started release..."
    else
        0exit 1 "Could not start release."
    fi

    local lastFetch
    local status="Updating"
    # poll for status updates
    while [ $status == "Updating" ]; do
        sleep 4
        lastFetch="$(aws elasticbeanstalk describe-environments \
                    --output=text \
                    --environment-names "$environment" | grep ENVIRONMENTS)"
        status=$(echo "$lastFetch" | cut -f 13)
        0info "'$environment' is in state: '$status'"
    done

    local health="$(echo "$lastFetch"|cut -f 11)"
    local running="$(echo "$lastFetch"|cut -f 13)"
    local updated="$(echo "$lastFetch"|cut -f 5)"

    local msg="$environment's health is $health, running version $running, updated at $updated"
    if [ "$health" == "Green" ]; then
        0info "$msg"
    else
        0warning "$msg"
    fi

    echo -e "$environment\t$health\t$running"

}
