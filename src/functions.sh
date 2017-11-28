#!/bin/bash
#
#
#

function check_environment_requirements {

}

function check_repo_requirements {

}

function update_repository {
    git stash
    # Good enough. Lets get after it.
    git fetch --all
    git checkout master
    git pull origin master
    git checkout develop
    git pull origin develop

    git fsck 
    git gc
}
