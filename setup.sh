#!/bin/sh

# This has files that are used by Khan Academy developers.  This setup
# script is OS-agnostic; it installs things like dotfiles, python
# libraries, etc that are the same on Linux, OS X, maybe even cygwin.
# It is intended to be idempotent; you can safely run it multiple
# times.  It should be run from the root of the khan-dotfiles directory.


# Bail on any errors
set -e

# Install in $HOME by default, but can set an alternate destination via $1.
ROOT=${1-$HOME}
mkdir -p "$ROOT"

# the directory all repositories will be cloned to, located under $ROOT
REPOS_DIR="khan"

warnings=""

add_warning() {
    echo "WARNING: $*"
    warnings="$warnings\nWARNING: $*"
}

add_fatal_error() {
    echo "FATAL ERROR: $*"
    echo "FATAL ERROR: Fix this problem and then re-run $0"
    exit 1
}

check_dependencies() {
    echo "Checking system dependencies"
    # We need git >=1.7.11 for '[push] default=simple'.
    if ! git --version | grep -q -e 'version 1.7.1[1-9]' \
                                 -e 'version 1.[89]' \
                                 -e 'version 2'; then
        echo "Must have git >= 1.8.  See http://git-scm.com/downloads"
        exit 1
    fi

    # You need to have run the setup to install binaries: node, npm/etc.
    if ! npm --version >/dev/null; then
        echo "You must install binaries before running $0.  See"
        echo "   https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup"
        exit 1
    fi
}

install_dotfiles() {
    echo "Installing and updating dotfiles (.bashrc, etc)"
    # Most dotfiles are installed as symlinks.
    # (But we ignore .git which is actually part of the khan-dotfiles repo!)
    for file in `find .[!.]* -name .git -prune -o -type f -print`; do
        mkdir -p "$ROOT"/`dirname "$file"`
        source=`pwd`/"$file"
        dest="$ROOT/$file"
        if [ -h "$dest" -a "`readlink $dest`" = "$source" ]; then
            :
        elif [ -e "$dest" ]; then
            add_warning "Not symlinking to $dest because it already exists."
        else
            ln -sfvn "$source" "$dest"
        fi
    done

    # A few dotfiles are copied so the user can change them.  They all
    # have names like bashrc.default, which is installed as .bashrc.
    # They all have the property they 'include' khan-specific code.
    for file in *.default; do
        dest="$ROOT/.`echo "$file" | sed s/.default$//`"  # foo.default -> .foo
        ka_version=.`echo "$file" | sed s/default/khan/`  # .bashrc.khan, etc.
        if [ ! -e "$dest" ]; then
            cp -f "$file" "$dest"
        elif ! fgrep -q "$ka_version" "$dest"; then
            add_fatal_error "$dest does not 'include' $ka_version;" \
                            "see `pwd`/$file and add the contents to $dest"
        fi
    done
}

edit_system_config() {
    echo "Modifying system configs: /etc/hosts, etc"
    # This will let you visit the khan academy homepage by just typing
    # www (or www/) into your browser's address bar, rather than
    # having to type www.khanacademy.org.
    if ! grep -q "search khanacademy.org" /etc/resolv.conf; then
        sudo sh -c 'echo "search khanacademy.org" >> /etc/resolv.conf'
    fi

    # This command avoids the spew when you deploy the Khan Academy
    # appengine app:
    #   Cannot guess mime-type for XXX.  Using application/octet-stream
    line="application/octet-stream  less eot ttf woff otf as fla sjs flash tmpl"
    if [ -s /usr/local/etc/mime.types ]; then
        # Replace any existing line with 'less' and 'eot' with the new line.
        grep -v 'less eot' /usr/local/etc/mime.types | \
            sudo sh -c "cat; echo '$line' > /usr/local/etc/mime.types"
    else
        sudo sh -c 'echo "$line" > /usr/local/etc/mime.types'
    fi
    sudo chmod a+r /usr/local/etc/mime.types

    # If there is no ssh key, make one.
    mkdir -p "$ROOT/.ssh"
    if [ ! -e "$ROOT/.ssh/id_rsa" -a ! -e "$ROOT/.ssh/id_dsa" ]; then
        ssh-keygen -q -N "" -t rsa -f "$ROOT/.ssh/id_rsa"
    fi
}

# $1: url of the repository to clone.  $2: directory to put repo, under $ROOT
clone_repo() {
    (
        mkdir -p "$ROOT/$2"
        cd "$ROOT/$2"
        dirname=`basename "$1"`
        if [ ! -d "$dirname" ]; then
            git clone "$1"
            cd `basename $1`
            git submodule update --init --recursive
        else
            cd `basename $1`
            # This 'git init' installs any new hooks we may have created.
            git init -q
        fi
    )
}

clone_repos() {
    echo "Cloning repositories, including the main 'webapp' repo"
    clone_webapp
    clone_devtools
}

clone_webapp() {
    clone_repo git@github.com:Khan/webapp       "$REPOS_DIR/"
}

clone_devtools() {
    clone_repo git@github.com:Khan/khan-linter  "$REPOS_DIR/devtools/"
    clone_repo git@github.com:Khan/libphutil    "$REPOS_DIR/devtools/"
    clone_repo git@github.com:Khan/arcanist     "$REPOS_DIR/devtools/"
    clone_repo git@github.com:Khan/git-bigfile  "$REPOS_DIR/devtools/"
    clone_repo git@github.com:Khan/git-workflow "$REPOS_DIR/devtools/"
}

# Depends on khan-linter having been pulled first.
install_git_hooks() {
    echo "Installing git hooks"
    mkdir -p "$ROOT/.git_template/hooks"
    ln -snfv "$ROOT/khan/devtools/khan-linter/githook.py" \
             "$ROOT/.git_template/hooks/commit-msg"
    ln -snfv "$ROOT/khan/devtools/khan-dotfiles/no-commit-to-master" \
             "$ROOT/.git_template/hooks/pre-commit"
    ln -snfv "$ROOT/khan/devtools/khan-dotfiles/no-push-to-master" \
             "$ROOT/.git_template/hooks/pre-push"
}

# Must have cloned the repos first.
install_deps() {
    echo "Installing python, node libraries"
    # pip is a nicer installer/package manager than easy-install.
    sudo easy_install --quiet pip

    # Install virtualenv.
    # https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/using-virtualenv
    sudo pip install -q virtualenv
    if [ ! -d "$ROOT/.virtualenv/khan27" ]; then
        # With recent versions of MacOSX XCode CLI Tools, it is no longer
        # possible to compile PyObjC without a full Xcode install. Since PyObjC
        # is typically preinstalled with the MacOSX version of Python, use
        # system packages for our virtualenv so we won't need to compile it.
        #
        # Note to future maintainers: the PyObjC dependency is part of webapp,
        # and gets installed later via requirements.darwin.txt in that repo.
        if [ `uname -s` = Darwin ]; then
            virtualenv -q --python="`which python2.7`" --system-site-packages \
                "$ROOT/.virtualenv/khan27"
        else
            virtualenv -q --python="`which python2.7`" --no-site-packages \
                "$ROOT/.virtualenv/khan27"
        fi
    fi
    # Activate the virtualenv.
    . ~/.virtualenv/khan27/bin/activate

    # This is useful for profiling
    # cf. https://sites.google.com/a/khanacademy.org/forge/technical/performance/using-kcachegrind-qcachegrind-with-gae_mini_profiler-results
    pip install pyprof2calltree

    # This is needed by git-bigfile.
    pip install boto

    # Install all the requirements for khan, khan-exercises.
    # This also installs npm deps.
    ( cd "$ROOT/$REPOS_DIR/webapp" && make install_deps )
    ( cd "$ROOT/$REPOS_DIR/webapp/khan-exercises" && pip install -r requirements.txt )
}

update_credentials() {
    echo "Updating information in your git config"
    # sed -i means 'replace in-place'
    if grep -q '%NAME_FIRST_LAST%' "$ROOT/.gitconfig"; then
        read -p "Enter your full name (First Last): " name
        perl -pli -e "s/%NAME_FIRST_LAST%/$name/g" "$ROOT/.gitconfig"
    fi

    if grep -q '%EMAIL%' "$ROOT/.gitconfig"; then
        read -p "Enter your KA email, without the @khanacademy.org (e.g. $USER): " email
        perl -pli -e "s/%EMAIL%/$email/g" "$ROOT/.gitconfig"
    fi

    if [ ! -s "$HOME/git-bigfile-storage.secret" ]; then
        echo "You must update your S3 credentials for use with git-bigfile."
        echo "Visit https://phabricator.khanacademy.org/K65 and click"
        echo "'show secret' and copy the contents into a file called"
        echo "   $HOME/git-bigfile-storage.secret"
        read -p "Hit enter when this is done: " prompt
    fi
}


check_dependencies

# Run sudo once at the beginning to get the necessary permissions.
echo "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

install_dotfiles
edit_system_config
clone_repos
# These need the repos to exist (e.g. khan-linter), so come after that.
install_git_hooks
install_deps
update_credentials


echo
echo "---------------------------------------------------------------------"

if [ -n "$warnings" ]; then
    echo "-- WARNINGS:"
    # echo is very inconsistent about whether it supports -e. :-(
    echo "$warnings" | sed 's/\\n/\n/g'
else
    echo "DONE!"
fi

echo
echo "To finish your setup, go to"
echo "   https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup"
