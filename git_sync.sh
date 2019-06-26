#!/usr/bin/env bash

# Load shared setup functions.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
. "$SCRIPT_DIR/shared-functions.sh"

# Find the git repo, branch, etc in "khan-dotfiles"
REPO="$(basename `git rev-parse --show-toplevel`)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
LOCAL_SHA=$(git rev-parse --verify HEAD)
REMOTE_SHA=$(git ls-remote . | grep refs/remotes/origin/HEAD | cut -f 1)

echo "Welcome to Khan-dotfiles!"
if [ -z "$BRANCH" ]; then
    echo "Error: Could not locate a git branch in $REPO"
    exit 1
fi

# Check if we're on the master branch.
if [ "$BRANCH" != "master" ]; then
    echo "Running branch \"$BRANCH\", not master."
    [ ! "$(get_yn_input "Would you like to continue?" "n")" != "y" ]
    exit $?

fi
if [ $LOCAL_SHA != $REMOTE_SHA ]; then
    echo "your local repo \"$REPO\" is different from 'origin/master'"
    if [ "$(get_yn_input "Would you like to run 'git pull'?" "y")" = "y" ]; then
        git pull
    else
        exit 0
    fi
fi
