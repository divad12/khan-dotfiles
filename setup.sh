#!/bin/bash

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

# the directory all repositories will be cloned to
REPOS_DIR="$ROOT/khan"

# derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"
KACLONE_BIN="$DEVTOOLS_DIR/ka-clone/bin/ka-clone"

# the directory this script exists in, regardless of where it is called from
#
# TODO(mroth): some of the historical parts of this script assume the user is
# running this from within the directory (and they are in fact instructed to do
# so), but it may be worth auditing and removing all CWD requirements in the
# future.
DIR=$(dirname "$0")

# should we install webapp? (disable for mobile devs or to make testing faster)
WEBAPP="${WEBAPP:-true}"

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
    # (But we ignore .git/.arc*/etc which are actually part of the repo!)
    #
    # TODO(mroth): for organization, we should keep all dotfiles in a
    # subdirectory, but to make that change will require repairing old symlinks
    # so they don't break when the target moves.
    for file in .*.khan .*.khan-xtra .git_template/commit_template .vim/ftplugin/*.vim; do
        mkdir -p "$ROOT/$(dirname "$file")"
        source=$(pwd)/"$file"
        dest="$ROOT/$file"
        # if dest is already a symlink pointing to correct source, skip it
        if [ -h "$dest" -a "$(readlink "$dest")" = "$source" ]; then
            :
        # else if dest already exists, warn user and skip dotfile
        elif [ -e "$dest" ]; then
            add_warning "Not symlinking to $dest because it already exists."
        # otherwise, verbosely symlink the file (with --force)
        else
            ln -sfvn "$source" "$dest"
        fi
    done

    # A few dotfiles are copied so the user can change them.  They all
    # have names like bashrc.default, which is installed as .bashrc.
    # They all have the property they 'include' khan-specific code.
    for file in *.default; do
        dest="$ROOT/.$(echo "$file" | sed s/.default$//)"  # foo.default -> .foo
        ka_version=.$(echo "$file" | sed s/default/khan/)  # .bashrc.khan, etc.
        if [ ! -e "$dest" ]; then
            cp -f "$file" "$dest"
        elif ! fgrep -q "$ka_version" "$dest"; then
            add_fatal_error "$dest does not 'include' $ka_version;" \
                            "see $(pwd)/$file and add the contents to $dest"
        fi
    done

    # *.template files are also copied so the user can change them.  Unlike the
    # "default" files above, these do not include KA code, they are merely
    # useful defaults we want to install if the user doesnt have anything
    # already.
    #
    # We should avoid installing anything absolutely not necessary in this
    # category, so for now, this is just a global .gitignore
    for file in *.template; do
        dest="$ROOT/.$(echo "$file" | sed s/.template$//)"  # foo.default -> .foo
        if [ ! -e "$dest" ]; then
            cp -f "$file" "$dest"
        fi
    done
}

edit_system_config() {
    echo "Modifying system configs"

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

    # if the user does not have a global gitignore file configured, reference
    # ours (or whatever is in the default location
    if ! git config --global core.excludesfile > /dev/null; then
      git config --global core.excludesfile ~/.gitignore
    fi
    # cleanup from previous versions: remove ~/.gitignore.khan symlink if exists
    rm -f ~/.gitignore.khan
}

# clone a repository without any special sauce. should only be used in order to
# bootstrap ka-clone, or if you are certain you don't want a khanified repo.
# $1: url of the repository to clone.  $2: directory to put repo
clone_repo() {
    (
        mkdir -p "$2"
        cd "$2"
        dirname=$(basename "$1")
        if [ ! -d "$dirname" ]; then
            git clone "$1"
            cd "$dirname"
            git submodule update --init --recursive
        fi
    )
}

# replacement for clone_repo() function using ka-clone tool for local config
# if run on an existing repository, will *update* and do --repair
# $1: url of the repository to clone.  $2: directory to put repo
# $3 onwards: any arguments to pass along to kaclone
kaclone_repo() {
    local src="$1"
    shift
    local dst="$1"
    shift

    (
        mkdir -p "$dst"
        cd "$dst"
        dirname=$(basename "$src")
        if [ ! -d "$dirname" ]; then
            "$KACLONE_BIN" "$src" "$dirname" "$@"
            cd "$dirname"
            git submodule update --init --recursive
        else
            cd "$dirname"
            # This 'ka-clone --repair' installs any new settings
            "$KACLONE_BIN" --repair --quiet "$@"
        fi
    )
}

clone_kaclone() {
    echo "Installing ka-clone tool"
    clone_repo git@github.com:Khan/ka-clone "$DEVTOOLS_DIR"
}

clone_webapp() {
    echo "Cloning main webapp repository"
    kaclone_repo git@github.com:Khan/webapp "$REPOS_DIR/" -p --email="$gitmail"
}

# clones a specific devtool
clone_devtool() {
    kaclone_repo "$1" "$DEVTOOLS_DIR" --email="$gitmail"
    # TODO(mroth): for devtools only, we should try to do:
    #   git pull --quiet --ff-only
    # but need to make sure we do it in master only!
}

# clones all devtools
clone_devtools() {
    echo "Installing devtools"
    clone_devtool git@github.com:Khan/ka-clone    # already cloned, so will --repair the first time
    clone_devtool git@github.com:Khan/khan-linter
    clone_devtool git@github.com:Khan/libphutil
    clone_devtool git@github.com:Khan/arcanist
    clone_devtool git@github.com:Khan/git-bigfile
    clone_devtool git@github.com:Khan/git-workflow
}

# khan-dotfiles is also a KA repository...
# thus, use kaclone --repair on current dir to khanify it as well!
kaclone_repair_self() {
    (cd "$DIR" && "$KACLONE_BIN" --repair --quiet)
}

clone_repos() {
    clone_kaclone
    clone_devtools
    if [ "$WEBAPP" = true ]; then
        clone_webapp
    fi
    kaclone_repair_self
}

# Must have cloned the repos first.
install_deps() {
    echo "Installing virtualenv and any global dependencies"
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
        if [ "$(uname -s)" = Darwin ]; then
            virtualenv -q --python="$(which python2.7)" --system-site-packages \
                "$ROOT/.virtualenv/khan27"
        else
            virtualenv -q --python="$(which python2.7)" --no-site-packages \
                "$ROOT/.virtualenv/khan27"
        fi
    fi
    # Activate the virtualenv.
    . ~/.virtualenv/khan27/bin/activate

    # Install all the requirements for khan, khan-exercises.
    # This also installs npm deps.
    if [ "$WEBAPP" = true ]; then
        echo "Installing webapp dependencies"
        ( cd "$REPOS_DIR/webapp" && make install_deps )
        ( cd "$REPOS_DIR/webapp/khan-exercises" && pip install -r requirements.txt )
    fi
}

# Make sure we store userinfo so we can pass appropriately when ka-cloning.
update_userinfo() {
    echo "Updating your git user info"

    # check if git user.name exists anywhere, if not, set that globally
    set +e
    gitname=$(git config user.name)
    set -e
    if [ -z "$gitname" ]; then
        read -p "Enter your full name (First Last): " name
        git config --global user.name "$name"
        gitname=$(git config user.name)
    fi

    # Set a "sticky" KA email address in the global kaclone.email gitconfig
    # ka-clone will check for this as the default to use when cloning
    # (we still pass --email to ka-clone in this script for redundancy, but
    #  this setting will apply to any future CLI usage of ka-clone.)
    set +e
    gitmail=$(git config kaclone.email)
    set -e
    if [ -z "$gitmail" ]; then
        read -p "Enter your KA email, without the @khanacademy.org (e.g. $USER): " emailuser
        git config --global kaclone.email "$emailuser"@khanacademy.org
        gitmail=$(git config kaclone.email)
    fi
}

update_credentials() {
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

# the order of these individually doesn't matter but they should come first
update_userinfo
install_dotfiles
edit_system_config
# the order for these is (mostly!) important, beware
clone_repos
install_deps        # pre-req: clone_repos
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
