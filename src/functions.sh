#!/bin/bash
#
#
#
function gvt_msg_error () {
    echo -e "\033[31m [ERROR] $1 \033[0m"
}

function gvt_msg_info () {
    echo -e "\033[33m [INFO] $1 \033[0m"
}

function gvt_msg_success () {
    echo -e "\033[32m [SUCCESS] $1 \033[0m"
}

function gvt_check_argument_requirements () {
    METHOD=$1
    TAG=$2
    DIR=$3
    if [ -z "$METHOD" ]; then
        gvt_msg_error "The method [hotfix / release] needs to be specified"
    fi

    if [ -z "$TAG" ]; then
        gvt_msg_error "A tag must be specified is required"
    fi

    if [ -z "$DIR" ]; then
        gvt_msg_error "The path to the project must be specified"
    fi

    METHODS=(hotfix release)
    for method in ${METHODS[*]}
    do
        if [ $method = $METHOD ]; then
            return 0
        fi
    done
    gvt_msg_error "The given method [$METHOD] is not one of (hotfix, release)"
}

function gvt_check_environment_requirements () {
    HAS_GIT=$(which git)
    HAS_GIT_FLOW=$(git flow help)
    HAS_GIT_FLOW_VERSION=$(git flow version | grep AVH)
    if [ -z "$HAS_GIT" ]; then
        gvt_msg_error "Git is not installed on this machine"
    fi

    if [ -z "$HAS_GIT_FLOW" ]; then
        gvt_msg_error "git flow is required for this."
    fi

    if [ -z "$HAS_GIT_FLOW_VERSION" ]; then
        gvt_msg_error "The AVH version of git-flow is required for this script"
    fi

}

function gvt_check_repo_requirements () {
    DIR=$1
    # error-check: what if the folder doesn't exist
    if [ ! -d $DIR ]; then
        gvt_msg_error "The given directory [$DIR] doesn't exist"
    fi

    cd $DIR


    IS_GIT_FLOW_INITIALIZED=$(grep gitflow .git/config)
    OLD_TAG=$(git describe --tags --abbrev=0)

    # error-check: what if the connection to the remote fails
    if [ ! -d .git ]; then
        gvt_msg_error "The given directory [$DIR] isn't a git repository"
    fi

    # error-check: what if the develop branch doesn't exist
    if [ -z "$IS_GIT_FLOW_INITIALIZED" ]; then
        gvt_msg_error "The given directory [$DIR] hasn't been git flow initialized"
    fi

    # error-check: what if there are no existing tags
    if [ -z $OLD_TAG ]; then
        gvt_msg_error "The given directory [$DIR] has no existing tags"
    fi

    return 0;
}

function gvt_prepare_repository () {
    METHOD=$1
    TAG=$2
    DIR=$3
    cd $DIR
    # Warn the user of what's going on
    gvt_msg_info "Running git stash. If you had changes you want, run git stash pop after this is completed."
    git stash
    # Good enough. Lets get after it.
    git fetch --all
    git checkout master
    git pull origin master
    git checkout develop
    git pull origin develop

    git fsck
    git gc

    git tag -l

    git flow "$METHOD" start $TAG

    return 0;
}

function gvt_update_documentation () {
    DIR=$1
    OLD_TAG=$2
    NEW_TAG=$3

    cd $DIR
    # Warn the user of what's going on
    gvt_msg_info "Updating htaccess and README files that might have the current version referenced in them."

    FILES=`find . -type f \( -name '.htaccess' -or -name "README.md" \)`

    # iterate through files
    for file in $FILES
    do
        gvt_msg_info "editing [$file]"
        sed -i.bak -e "s/$OLD_TAG/$NEW_TAG/g" "$file"
        rm "$file.bak"
    done

    git add -u
    git commit -m "Documenting the [$TAG] release"

    return 0;
}

function gvt_commit_and_push () {
    METHOD=$1
    TAG=$2
    DIR=$3
    cd $DIR

    # Wanr the user of what's going on
    git config core.editor "echo yes"
    git flow "$METHOD" finish $TAG -m "releasing [$TAG]"
    git config --unset core.editor
    git push origin --all
    git push origin --tags
}


function gvt () {
    ROOT=$(pwd)

    METHOD=$1
    NEW_TAG=$2
    DIR=$3

    cd $DIR

    OLD_TAG=$(git describe --tags --abbrev=0)

    gvt_check_environment_requirements
    gvt_check_argument_requirements "$METHOD" "$NEW_TAG" "$DIR"

    gvt_check_repo_requirements "$DIR"

    CAN_PROCEED=$(gvt_prepare_repository "$METHOD" "$NEW_TAG" "$DIR")
    if [ -z "$CAN_PROCEED" ]; then
        gvt_msg_error "There are problems. Cannot continue"
        return 1
    fi

    gvt_update_documentation "$DIR" "$OLD_TAG" "$NEW_TAG"
    gvt_commit_and_push "$METHOD" "$NEW_TAG" "$DIR"

    gvt_msg_success "Updated repository, created tag, updated documentation, committed changes, and pushed to the origin"
    # go back to where we started
    cd $ROOT

}
