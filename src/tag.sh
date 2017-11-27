#!/bin/bash
#
# Script to automate the process of releasing tags
#
# Usage: ./src/tag.sh <tag> /path/to/project
#
#   i.e. ./src/tag/sh 1.0.4 ~/Repositories/example.com
#
# Requirements:
# The project must be git flow initialized already, and there must already be at least
# 1 existing tag for the project.

TAG=$1
DIR=$2
ROOT=$(pwd)
cd $DIR

CURRENT=$(git describe --tag)

echo $DIR
echo $CURRENT
echo $TAG

# First, we do all of the sanity checks.
# error-check: make sure we have the right version of Git Flow
if [ $(git flow version | grep AVH) -eq 0 ]; then
    echo "The AVH version of git-flow is required for this script"
    exit 1
fi

# error-check: what if the folder doesn't exist
if [ ! -d $DIR ]; then
    echo "The given directory [$DIR] doesn't exist"
    exit 1
fi

# error-check: what if the connection to the remote fails
if [ ! -d .git ]; then
    echo "The given directory [$DIR] isn't a git repository"
    exit 1
fi

# error-check: what if the develop branch doesn't exist
if [ $(grep -q gitflow .git/config) -eq 0 ]; then
    echo "The given directory [$DIR] hasn't been git flow initialized"
    exit 1
fi

# error-check: what if there are no existing tags
if [ -z $CURRENT ]; then
    echo "The given directory [$DIR] has no existing tags"
    exit 1
fi

# Good enough. Lets get after it.
git fetch --all
git checkout develop
git pull origin develop
git checkout master
git pull origin master
git flow release start $TAG

# error-check: what if the the files don't exist
sed -i.bak -e "s/$CURRENT/$TAG/g" "$DIR/.htaccess"
sed -i.bak -e "s/$CURRENT/$TAG/g" "$DIR/README.md"
rm *.bak
rm .htaccess.bak
git add -u
git commit -m "Documenting the [$TAG] release"
git config core.editor "echo yes"
git flow release finish $TAG -m "releasing [$TAG]"
git config --unset core.editor
git push origin --all
git push origin --tags

# go back to where we started
cd $ROOT
