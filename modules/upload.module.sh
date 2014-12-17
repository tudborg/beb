
upload_usage () {

    cat <<EOL
Usage:
    $SCRIPT_MAIN upload -h
        This message.

    $SCRIPT_MAIN upload [-f] <artifact> <bucket> <key>
        Upload the artifact to <bucket> at <key>,
        but fails if <key> is already present.
        (we don't want to re-write a previous version!)
        the -f flag forces the write (careful now!)
EOL

}



upload_main () {

    # Option parsing
    OPTIND=1
    local force=false
    while getopts hf opt; do
        case $opt in
        h)
            upload_usage
            exit 1
        ;;
        f)
            force=true
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "2" ]; then
        upload_usage
        exit 1
    fi

    # assert that we have deps

    bb-exe? aws || bb-exit 1 "Missing AWS CLI ( http://aws.amazon.com/cli/ )"


    local artifact="$1"
    local bucket="$2"
    local key
    if [ "$#" -lt "3" ]; then
        key="beb_uploads/$(basename "$artifact")"
    else
        key="$3"
    fi


    # CHECK THAT BUCKET EXISTS
    if ! aws s3api head-bucket --output=text --bucket "$bucket" >&2 2>/dev/null; then
        bb-exit 1 "Bucket '$bucket' does not exist, or you don't have permission to access it."
    fi

    if ! $force; then
        # CHECK THAT KEY DOES _NOT_ EXIST
        if aws s3api head-object --output=text --bucket "$bucket" --key "$key" >&2 2>/dev/null; then
            bb-exit 1 "Key '$key' already exists in bucket '$bucket'."
        fi
    fi

    # VALIDATE ARTIFACT IS A FILE
    if [ ! -f "$artifact" ]; then
        bb-exit 1 "Artifact at '$artifact' is not a file"
    fi

    # UPLOAD
    bb-log-info "Uploading artifact '$artifact' to 's3://$bucket/$key'"
    if which du >/dev/null; then
        bb-log-info "Note that the filesize of the artifact is $(du -h $artifact | cut -f 1)"
    fi
    aws --output=text s3 cp "$artifact" "s3://$bucket/$key" >&2 \
        || bb-exit 1 "Failed to upload '$artifact' to bucket '$bucket' key '$key'"

    echo -e "$bucket\t$key"
}