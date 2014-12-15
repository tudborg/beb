
function version_create_usage {

    cat <<EOL
Usage:
    $SCRIPT_MAIN create -h
        This message.

    $SCRIPT_MAIN create <application> <bucket> <key> <label> [<description>]
        Create a new application version for <application>
        found on <bucket>://<key> with the label <label> and description <description>
EOL

}



function version_create_main {

    # Option parsing
    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            version_create_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "4" ]; then
        version_create_usage
        exit 1
    fi

    # assert that we have deps

    bb-exe? aws || bb-exit 1 "Missing AWS CLI ( http://aws.amazon.com/cli/ )"


    local application="$1"
    local bucket="$2"
    local key="$3"
    local label="$4"
    local description="$5"

    if [ -z "$label" ]; then
        bb-exit 1 "Got empty label"
    fi
    if [ -z "$description" ]; then
        description="Release from '$label'"
    fi

    # check that application is valid
    local numapp="$(aws elasticbeanstalk describe-applications \
        --output=text \
        --application-names "$application" | wc -l)"
    if [ "$numapp" -eq 0 ]; then
        bb-exit "Application with name '$application' Does not exist"
    fi

    # check that key exists
    if ! aws s3api head-object --bucket "$bucket" --key "$key" 2>&1 >/dev/null; then
        bb-exit 1 "Key '$key' in bucket '$bucket' does not exist"
    fi

    # check that we don't already have another version by the same name (label)
    local numver="$(aws elasticbeanstalk describe-application-versions \
        --output=text \
        --application-name "$application" \
        --version-labels "$label" | wc -l)"
    if [ "$numver" -gt 0 ]; then
        bb-exit 1 "Application Version with label "$label" already exists"
    fi

    # create application version
    local status
    status=$(aws elasticbeanstalk create-application-version \
            --output=text \
            --application-name "$application" \
            --version-label "$label" \
            --description "$description" \
            --source-bundle "S3Bucket=$bucket,S3Key=$key")

    if [ "$?" -eq 0 ]; then
        bb-log-info "Successfully created application version '$label' for application '$application'"
    else
        bb-exit 1 "Could not create application version"
    fi

    # output the application and the label we created
    echo -e "$application\t$label"

}