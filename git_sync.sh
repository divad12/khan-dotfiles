#!/usr/bin/env bash

# Find the git repo, branch, etc in "khan-dotfiles"
REPO="$(basename `git rev-parse --show-toplevel`)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
LOCAL_SHA=$(git rev-parse --verify HEAD)
REMOTE_SHA=$(git rev-parse --verify FETCH_HEAD)

if [ -z "$BRANCH" ]; then
    echo "Error: Could not locate a git branch in $REPO"
    exit 1
fi

# Check if we're on the master branch.
if [ "$BRANCH" != "master" ]; then
    echo "Your directory is running branch \"$BRANCH\""
    echo "You need to run in master branch at \"$REPO\""
    exit 1
fi

if [ $LOCAL_SHA != $REMOTE_SHA ]; then
    echo "your local repo \"$REPO\" is different with 'origin/master'"
    echo "please 'git pull' and re-run 'make' "
    exit 1
fi
