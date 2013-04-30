#!/bin/bash

# Symlinks dotfiles into home directory

dir=`pwd`

for file in .*; do
    if [[ "$file" == ".git" || "$file" == "." || "$file" == ".." ]]; then
        continue
    fi
    source="$dir/$file"
    dest="$HOME/$file"
    if [ -e "$dest" ]; then
        echo "WARNING: Not symlinking to $dest because it already exists."
        continue
    fi
    ln -sfvn "$source" "$dest"
done

# Also create the pre-commit hook git symlink.
mkdir -p ~/.git_template/hooks
ln -snf $HOME/khan/devtools/khan-linter/githook.py ~/.git_template/hooks/commit-msg
