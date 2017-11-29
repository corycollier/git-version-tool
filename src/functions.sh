#!/bin/bash
#
#
#
function gvt_msg_error () {
    echo -e "\033[31m [ERROR] $1 \033[0m"
    exit 1
}

function gvt_msg_info () {
    echo -e "\033[33m [INFO] $1 \033[0m"
}

function gvt_msg_success () {
    echo -e "\033[32m [SUCCESS] $1 \033[0m"
}

function gvt_check_environment_requirements () {
    HAS_GIT=$(which git)
    HAS_GIT_FLOW=$(git flow help)
    HAS_GIT_FLOW=$(git flow version | grep AVH)
    if [ -z "$HAS_GIT" ]; then
        gvt_msg_error "Git is not installed on this machine"
    fi

    if [ -z "$HAS_GIT_FLOW" ]; then
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
    DIR=$1
    NEW_TAG=$2
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
    EXISTING=$(git tag -l)
    for tag in $EXISTING
    do
        if [ "$tag" = "$NEW_TAG" ]; then
            gvt_msg_error "The tag you're trying to create [$NEW_TAG] already exists in [$EXISTING]"
        fi
    done

    git flow release start $NEW_TAG
    return 0;
}

function gvt_update_documentation () {
    DIR=$1
    cd $DIR
    # Warn the user of what's going on
    gvt_msg_info "Updating htaccess and README files that might have the current version referenced in them."

    OLD_TAG=$2
    NEW_TAG=$3

    FILES=`find . -type f \( -name '.htaccess' -or -name "README.md" \)`

    # iterate through files
    for file in $FILES
    do
        gvt_msg_info "editing [$file]"
        sed -i.bak -e "s/$OLD_TAG/$NEW_TAG/g" "$file"
        rm "$file.bak"
    done

    return 0;
}

function gvt_commit_and_push () {
    DIR=$1
    TAG=$2
    cd $DIR

    # Wanr the user of what's going on
    git add -u
    git commit -m "Documenting the [$TAG] release"
    git config core.editor "echo yes"
    git flow release finish $TAG -m "releasing [$TAG]"
    git config --unset core.editor
    git push origin --all
    git push origin --tags
}
