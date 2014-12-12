
function build_usage {

    cat <<EOL
Usage:
    $SCRIPT_MAIN build -h
        This message.

    $SCRIPT_MAIN build <git-dir> [<bundle-out-file>]
        Build a zip-bundle placed at <bundle-out-file> from git repo at <git-dir>.
        If <bundle-out-file> is not given, it will default to something sane
        based on your git repo's refs.

EOL

}


#
# Project type detection.
# If failure, will return with code 1
# If success, stdout will contain a line:
# $compiler_func\t$artifactor_func\t$project_type_name
#
function build_detect_project {
    local gitdir="$1"
    bb-assert "is_git_repo $gitdir" "'$gitdir' is not a git directory"

    # PHP directory, look for composer.json file, or a php.project file
    if [ -f "$gitdir/composer.json" ]; then
        echo -e "build_compiler_php_composer\tbuild_artifactor_zip\tPHP Composer Project"
        return 0
    elif [ -f "$gitdir/php.project" ]; then
        echo -e "build_compiler_noop\tbuild_artifactor_zip\tPHP Project"
        return 0
    fi


    return 1
}

#
# build_compiler_noop does nothing
#
function build_compiler_noop {
    return 0
}

#
# build_compiler_php_composer
# PHP Composer Project Builder
# $1 must be path to temp build directory
#
function build_compiler_php_composer {
    # Check where we can find the composer bin
    # report error and return 1 if we cant find it
    bb-var COMPOSER_BIN "composer"
    bb-var COMPOSER_INSTALL_ARGS "-v --prefer-dist --no-dev --optimize-autoloader --ignore-platform-reqs"
    if ! bb-exe? $COMPOSER_BIN; then
        bb-log-error "Missing dependency: composer ( https://getcomposer.org/ )"
        return 1
    fi

    bb-log-info "Running composer..."
    if ! $COMPOSER_BIN install $COMPOSER_INSTALL_ARGS; then
        bb-log-error "Composed failed to run install"
        return 1
    fi | sed 's/^/---->  /'

    # success :)
    return 0
}


#
# build_artifactor_zip
# Simply zips up the entire build' dir
# $1 is the build dir,
# $2 is the expected outfile
function build_artifactor_zip {
    local dir="$1"
    local artifact="$2"
    bb-assert 'test -d "$dir"' "'$dir' is not a directory"
    bb-assert 'bb-exe? zip' "Missing dependency: zip"

    pushd $dir >/dev/null
    if zip -q -r "$artifact" "." >&2; then
        popd >/dev/null
        return 0
    else
        popd >/dev/null
        bb-log-error "Failed to create zip artifact from '$dir' to '$artifact'"
        return 1
    fi
}





#
# Entrypoint
#

function build_main {

    # Option parsing
    OPTIND=1
    while getopts h opt; do
        case $opt in
        h)
            build_usage
            exit 1
        ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$#" -lt "1" ]; then
        build_usage
        exit 1
    fi


    local gitdir="$(dir_resolve $1)"
    bb-assert "is_git_repo $gitdir" "'$gitdir' is not a git directory"
    
    if [ "$#" -lt "2" ]; then
        # only git dir given
        # figure out name from that
        local tagish="$(get_git_tagish "$gitdir")"
        local artifactfile="$(dir_resolve "./$tagish.zip")"
    else
        # name given
        local artifactfile="$(dir_resolve $2)"
    fi


    local compilerfunc
    local artifacterfunc
    local projecttype


    # assert that variables are correct-ish
    bb-assert "touch -a $artifactfile 2>/dev/null" "'$artifactfile' is not writable"
    rm "$artifactfile"


    # detect what builder to run
    compilerfunc="$(build_detect_project $gitdir | cut -f 1)"
    artifacterfunc="$(build_detect_project $gitdir | cut -f 2)"
    projecttype="$(build_detect_project $gitdir | cut -f 3-)"
    [ "$?" -eq "0" ] || bb-exit 1 "Could not detect project type for '$gitdir'"

    bb-log-info "detected project type: $projecttype"
    bb-log-debug "compiler function: $compilerfunc"
    bb-log-debug "artifact function: $artifacterfunc"

    local compiledir="$(bb-tmp-dir)"
    bb-log-debug "Original repo: '$gitdir'"
    bb-log-debug "Build directory created at '$compiledir'"
    bb-log-debug "Artifact will be placed at '$artifactfile'"

    # CLONE REPO TO COMPILE DIR
    git clone --depth 1 --recurse-submodules "file://$gitdir" "$compiledir"\
        || bb-exit 1 "Failed to git clone '$gitdir' to a temp build directory"

    # for ease, go to the temp dir
    pushd "$compiledir" >/dev/null

    # BUILD
    "$compilerfunc" "$compiledir" >&2 || bb-exit 1 "Failed to compile $projecttype"

    # ARTIFACT
    "$artifacterfunc" "$compiledir" "$artifactfile" >&2 || bb-exit 1 "Failed to create artifact $projecttype"

    # go back to prev. dir
    popd >/dev/null


    if which du >/dev/null; then
        bb-log-info "Created artifact of size $(du -h "$artifactfile" | cut -f 1)"
    fi


    # echo out our final build artifact path
    echo -e "Artifact:\t$artifactfile"

}
