
function version_list_usage {

    cat <<EOL
Usage:
    $SCRIPT_MAIN list -h
        This message.

    $SCRIPT_MAIN list <application>
        List available application versions
EOL

}


function version_list_main {

    # Option parsing
    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            version_list_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "1" ]; then
        version_list_usage
        exit 1
    fi

    # assert that we have deps

    0exe? aws || 0exit 1 "Missing AWS CLI ( http://aws.amazon.com/cli/ )"


    local application="$1"

    # fetch application versiopns
    local versions
    versions="$(aws elasticbeanstalk describe-application-versions \
        --output=text \
        --application-name "$application")"

    if [ "$(echo -n "$versions" | wc -l)" -eq 0 ]; then
        0warning "No application versions found for application '$application'"
        return 1
    fi

    echo "$versions" | awk -F "\t" \
        '/APPLICATIONVERSIONS/{ print "- Version:\t" $6 "\n  Updated:\t" $4 "\n  Description:\t" $5 "\n" }'

}
