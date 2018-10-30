#!/bin/bash

# Bail on any errors
set -e

tty_bold=`tput bold`
tty_normal=`tput sgr0`

# The directory to which all repositories will be cloned.
ROOT=${1-$HOME}
REPOS_DIR="$ROOT/khan"

# Derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"

# Load shared setup functions.
. "$DEVTOOLS_DIR"/khan-dotfiles/shared-functions.sh

# for printing standard echoish messages
notice () {
    printf "         $1\n"
}

# for printing logging messages that *may* be replaced by
# a success/warn/error message
info () {
    printf "  [ \033[00;34m..\033[0m ] $1"
}

# for printing prompts that expect user input and will be
# replaced by a success/warn/error message
user () {
    printf "\r  [ \033[0;33m??\033[0m ] $1 "
}

# for replacing previous input prompts with success messages
success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

# for replacing previous input prompts with warnings
warn () {
    printf "\r\033[2K  [\033[0;33mWARN\033[0m] $1\n"
}

# for replacing previous prompts with errors
error () {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
}


update_path() {
    # We need /usr/local/bin to come before /usr/bin on the path, to
    # pick up brew files we install.  To do this, we just source
    # .profile.khan, which does this for us (and the new user).
    # (This assumes you're running mac-setup.sh from the khan-dotfiles
    # directory.)
    . .profile.khan
}

maybe_generate_ssh_keys () {
  # Create a public key if need be.
  info "Checking for ssh keys"
  mkdir -p ~/.ssh
  if [ -e ~/.ssh/id_[rd]sa ]
  then
    success "Found existing ssh keys"
  else
    ssh-keygen -q -N "" -t rsa -f ~/.ssh/id_rsa
    success "Generated an rsa ssh key at ~/.ssh/id_rsa"
  fi
  return 0
}

copy_ssh_key () {
  if [ -e ~/.ssh/id_rsa ]
  then
    pbcopy < ~/.ssh/id_rsa.pub
  elif [ -e ~/.ssh/id_dsa ]
  then
    pbcopy < ~/.ssh/id_dsa.pub
  else
    error "no ssh public keys found"
    exit
  fi
}

register_ssh_keys() {
    success "Registering your ssh keys with github\n"
    verify_ssh_auth
}

# checks to see that ssh keys are registered with github
# $1: "true"|"false" to end the auth cycle
verify_ssh_auth () {
    ssh_host="git@github.com"
    webpage_url="https://github.com/settings/ssh"
    instruction="Click 'Add SSH Key', paste into the box, and hit 'Add key'"

    info "Checking for GitHub ssh auth"
    if ! ssh -T -v $ssh_host 2>&1 >/dev/null | grep \
        -q -e "Authentication succeeded (publickey)"
    then
        if [ "$2" == "false" ]  # error if auth fails twice in a row
        then
            error "Still no luck with GitHub ssh auth. Ask a dev!"
            ssh_auth_loop $webpage_url "false"
        else
            # otherwise prompt to upload keys
            success "GitHub's ssh auth didn't seem to work\n"
            notice "Let's add your public key to GitHub"
            info "${tty_bold}${instruction}${tty_normal}\n"
            ssh_auth_loop $webpage_url "true"
        fi
    else
        success "GitHub ssh auth succeeded!"
    fi
}

ssh_auth_loop() {
    # a convenience function which lets you copy your public key to your clipboard
    # open the webpage for the site you're pasting the key into or just bailing
    # $1 = ssh key registration url
    service_url=$1
    first_run=$2
    if [ "$first_run" == "true" ]
    then
        notice "1. hit ${tty_bold}o${tty_normal} to open GitHub on the web"
        notice "2. hit ${tty_bold}c${tty_normal} to copy your public key to your clipboard"
        notice "3. hit ${tty_bold}t${tty_normal} to test ssh auth for GitHub"
        notice "☢. hit ${tty_bold}s${tty_normal} to skip ssh setup for GitHub"
        ssh_auth_loop $1 "false"
    else
        user "o|c|t|s) "
        read -n1 ssh_option
        case $ssh_option in
            o|O )
                success "opening GitHub's webpage to register your key!"
                open $service_url
                ssh_auth_loop $service_url "false"
                ;;
            c|C )
                success "copying your ssh key to your clipboard"
                copy_ssh_key
                ssh_auth_loop $service_url "false"
                ;;
            t|T )
                printf "\r"
                verify_ssh_auth "false"
                ;;
            s|S )
                warn "skipping GitHub ssh registration"
                ;;
        esac
    fi
}

install_gcc() {
    info "\nChecking for apple command line developer tools..."
    if ! gcc --version >/dev/null 2>&1 || [ ! -s /usr/include/stdio.h ]; then
        if sw_vers -productVersion | grep -e '^10\.[0-8]$' -e '^10\.[0-8]\.'; then
            warn "Command line tools are *probably available* for your Mac's OS, but..."
            info "why not upgrade your OS right now?\n"
            info "Otherwise, you can always visit developer.apple.com and grab 'em there.\n"
            exit 1
        else
            success "Installing command line developer tools"
            # Also, how did you get this dotfiles repo in 10.9 without
            # git auto-triggering the command line tools install process??
            xcode-select --install
            warn "The dotfile setup is stopping now."
            warn "When the install finishes, rerun ${tty_bold}make${tty_normal} to continue. (sorry)"
            exit 1
        fi
        # If this doesn't work for you, you can find the most recent
        # version here: https://developer.apple.com/downloads
    else
        success "Great, found gcc! (assuming we also have other recent devtools)"
    fi
}

install_slack() {
    info "Checking for Slack..."
    if ! open -R -g -a Slack > /dev/null; then
        success "Didn't find Slack."
        info "Installing Slack to ~/Applications\n"
        brew cask install slack
    else
        success "Great! Slack already installed!"
    fi
}

install_homebrew() {
    info "Checking for mac homebrew"
    # If homebrew is already installed, don't do it again.
    if ! brew --help >/dev/null 2>&1; then
        success "Brew not found. Installing!"
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        success "Great! Mac homebrew already installed!"
        info "Verifying homebrew is in a good state...\n"
        if ! brew doctor; then
            warn "Oh no! 'brew doctor' reported some warnings."
            info "These warnings may cause you trouble, but they are likely harmless.\n"
            read -r -p "Onward? [Y/n] " response
            case "$response" in
                [nN][oO]|[nN])
                    exit 1
                    ;;
            esac
        fi
    fi
    success "Updating (but not upgrading) Homebrew"
    brew update > /dev/null

    # Install homebrew-cask, so we can use it manage installing binary/GUI apps
    brew tap caskroom/cask

    # Likely need an alternate versions of Casks in order to install chrome-canary
    brew tap caskroom/versions

    # Make sure everything is ok.  We don't care if we're using an
    # obsolete gcc, so instead of looking at the exit code for 'brew
    # doctor', we look at its output.  The last 'grep', combined with
    # the ! at the beginning of this command, causes the overall
    # command to fail -- and thus the script to exit -- if brew doctor
    # has any errors or warnings after we grep out the stuff we don't
    # care about.
    ## Commented out for now: too many legit setups have warnings (cf chris).
    ## ! brew doctor 2>&1 \
    ##     | grep -v -e 'A newer Command Line Tools' \
    ##     | grep -v -e 'Your Homebrew is not installed to /usr/local' \
    ##     | grep -C1000 -e ^Error -e ^Warning
}

update_git() {
    if ! git --version | grep -q -e 'version 1.[89]' \
                                 -e 'version 2'; then
        echo "Installing an updated version of git using Homebrew"
        echo "Current version is `git --version`"

        if brew ls git >/dev/null 2>&1; then
            # If git is already installed via brew, update it
            brew upgrade git || true
        else
            # Otherwise, install via brew
            brew install git || true
        fi

        # Check git version again
        if ! git --version | grep -q -e 'version 1.[89]' \
                                     -e 'version 2'; then
            echo "Error installing git via brew; download and install manually via http://git-scm.com/download/mac. "
            read -p "Press enter to continue..."
        fi
    fi
    # Some code, such as tools/diagnose_js_packages.py, uses pcre-grep.
    # (Search for `perl_regexp` in webapp to see a complete list.)
    if ! git grep -P -l . >/dev/null; then
        echo "Updating git to be able to use PCRE."
        brew reinstall --with-pcre2 git
    fi
}

install_node() {
    if ! brew ls node >/dev/null 2>&1; then
        # Install node 8: webapp doesn't (yet!) work with node 10.
        # (Node 8 is LTS.)
        brew install node@8
        # We need this because brew doesn't link /usr/local/bin/node
        # by default when installing non-latest node.
        brew link --force node@8
    fi
}

install_phantomjs() {
    info "Checking for phantomjs\n"
    if ! type phantomjs >/dev/null 2>&1 || ! expr `phantomjs --version` : 2 >/dev/null; then
        brew uninstall --force phantomjs
        brew cask install phantomjs
    else
        success "phantomjs 2.x already installed"
    fi
}

install_nginx() {
    info "Checking for nginx\n"
    if ! type nginx >/dev/null 2>&1; then
        info "Installing nginx\n"
        brew install nginx
    else
        success "nginx already installed"
    fi
}

install_image_utils() {
    info "Checking for imagemagick\n"
    if ! brew ls imagemagick >/dev/null 2>&1; then
        info "Installing imagemagick\n"
        brew install imagemagick
    else
        success "imagemagick already installed"
    fi
}

install_helpful_tools() {
    # This installs gtimeout, among a ton of other tools, which we use
    # some in our deploy pipeline.
    if ! brew ls coreutils >/dev/null 2>&1; then
        info "Installing coreutils\n"
        brew install coreutils
    else
        success "coreutils already installed"
    fi
}

install_java() {
    # We use java for our google cloud dataflow jobs that live in webapp
    # (as well as in khan-linter for linting those jobs)
    brew cask install java8
}

install_protoc() {
    # We use protocol buffers in webapp's event log stream infrastructure. This
    # installs the protocol buffer compiler (which generates python & java code
    # from the protocol buffer definitions), as well as a go-based compiler
    # plugin that allows us to generate bigquery schemas as well.
    if ! brew ls protobuf >/dev/null 2>&1; then
        info "Installing protoc\n"
        brew install protobuf
    else
        success "protoc already installed"
    fi
    if ! brew ls go >/dev/null 2>&1; then
        info "Installing go\n"
        brew install go
    else
        success "go already installed"
    fi
    go get github.com/GoogleCloudPlatform/protoc-gen-bq-schema
}

# To install some useful mac apps.
install_mac_apps() {
  chosen_apps=() # When the user opts to install a package it will be added to this array.

  mac_apps=(
    # Browsers
    firefox firefox-developer-edition google-chrome google-chrome-canary
    # Tools
    dropbox google-drive-file-stream iterm2 virtualbox zoomus
    # Text Editors
    macvim sublime-text textmate atom
  )

  mac_apps_str="${mac_apps[@]}"
  info "We recommend installing the following apps: ${mac_apps_str}. \n\n"

  read -r -p "Would you like to install [a]ll, [n]one, or [s]ome of the apps? [a/n/s]: " input

  case "$input" in
      [aA][lL][lL] | [aA])
          chosen_apps=("${mac_apps[@]}")
          ;;
      [sS][oO][mM][eE] | [sS])
          for app in ${mac_apps[@]}; do
            if [ "$(get_yn_input "Would you like to install ${app}?" "y")" = "y" ]; then
              chosen_apps=("${chosen_apps[@]}" "${app}")
            fi
          done
          ;;
      [nN][oO][nN][eE] | [nN])
          ;;
      *)
          echo "Please choose [a]ll, [n]one, or [s]ome."
          exit 100
          ;;
  esac

  for app in ${chosen_apps[@]}; do
    if ! brew cask ls $app >/dev/null 2>&1; then
        info "$app is not installed, installing $app"
        brew cask install $app || warn "Failed to install $app, perhaps it is already installed."
    else
        success "$app already installed"
    fi
  done
}

echo
success "Running Khan Installation Script 1.1\n"

if ! sw_vers -productVersion 2>/dev/null | grep -q '10\.1[123]\.' ; then
    warn "Warning: This is only tested up to macOS 10.13 (High Sierra).\n"
    notice "If you find that this works on a newer version of macOS, "
    notice "please update this message.\n"
fi

notice "After each statement, either something will open for you to"
notice "interact with, or a script will run for you to use\n"
notice "Press enter when a download/install is completed to go to"
notice "the next step (including this one)"

if ! echo "$SHELL" | grep -q '/bash$' ; then
    echo
    warn "It looks like you're using a shell other than bash!"
    notice "Other shells are not officially supported.  Most things"
    notice "should work, but dev-support help is not guaranteed."
fi

read -p "Press enter to continue..."

# Run sudo once at the beginning to get the necessary permissions.
notice "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

update_path
maybe_generate_ssh_keys
register_ssh_keys
install_gcc
install_homebrew
install_slack
update_git
install_node
install_phantomjs
install_nginx
install_image_utils
install_helpful_tools
install_java
install_protoc
install_mac_apps
