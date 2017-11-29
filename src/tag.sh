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

ROOT=$(pwd)

METHOD=$1
NEW_TAG=$2
DIR=$3

cd $DIR

OLD_TAG=$(git describe --tags --abbrev=0)

source "$ROOT/src/functions.sh"
gvt_check_environment_requirements
gvt_check_argument_requirements "$METHOD" "$NEW_TAG" "$DIR"

gvt_check_repo_requirements "$DIR"
gvt_prepare_repository "$DIR" "$NEW_TAG"

git flow "$METHOD" start $NEW_TAG

gvt_update_documentation "$DIR" "$OLD_TAG" "$NEW_TAG"
gvt_commit_and_push "$METHOD" "$NEW_TAG" "$DIR"

gvt_msg_success "Updated repository, created tag, updated documentation, committed changes, and pushed to the origin"
# go back to where we started
cd $ROOT
