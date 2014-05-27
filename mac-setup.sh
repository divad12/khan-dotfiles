#!/bin/sh

# Bail on any errors
set -e

tty_bold=`tput bold`
tty_normal=`tput sgr0`

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
    # We need /usr/local/bin to come before /usr/bin on the path,
    # to pick up brew files we install.
    if ! echo "$PATH" | egrep -q '(:|^)/usr/local/bin/?:(.*:)?/usr/bin/?(:|$)'
    then
        # This replaces /usr/bin with /usr/local/bin:/usr/bin
        PATH=`echo $PATH | sed -E 's,(^|:)(/usr/bin/?(:|$)),\1/usr/local/bin:\2,'`
        # Make this path update work in the future too.
        path_update=`cat<<'EOF'
echo $PATH | sed -E 's,(^|:)(/usr/bin/?(:|$)),\1/usr/local/bin:\2,'
EOF`
    else
        path_update=''
    fi

    # Ideally we'd put /usr/local/sbin right before /usr/sbin, but
    # there's so little in it we figure it's ok to put it first.
    export PATH=/usr/local/sbin:$PATH

    # Put these in shell config file too.
    # Test whether it's already in a config file (sorry zsh users who
    # aren't using .profile).  We follow the same order bash does:
    if [ -f ~/.bash_profile ]; then
        PROFILE_FILE="$HOME/.bash_profile"
    elif [ -f ~/.bash_login ]; then
        PROFILE_FILE="$HOME/.bash_login"
    else
        PROFILE_FILE="$HOME/.profile"
    fi
    if ! grep -q "export PATH=.*/usr/local/sbin" \
        ~/.bash_profile ~/.bash_login ~/.profile; then
        echo 'export PATH=/usr/local/sbin:$PATH' >> "$PROFILE_FILE"
    fi
    # Numpy/etc use flags clang doesn't know about.  This is only
    # needed for mavericks.
    if expr "`sw_vers -productVersion`" : 10.9 >/dev/null && \
       ! grep -q "-Qunused-arguments" \
        ~/.bash_profile ~/.bash_login ~/.profile; then
        echo 'export CPPFLAGS="-Qunused-arguments $CPPFLAGS" >> "$PROFILE_FILE"
        echo 'export CFLAGS="-Qunused-arguments $CFLAGS" >> "$PROFILE_FILE"
    fi
    if [ -n "$path_update" ]; then
        echo "# Put /usr/local/bin right before /usr/bin" >> "$PROFILE_FILE"
        echo 'PATH=`'"$path_update"'`' >> "$PROFILE_FILE"
    fi
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
    # Have the user copy it into kiln and github.
    success "Registering your ssh keys with kiln and github"

    success "Registering with github\n"
    verify_ssh_auth "Github"

    success "Registering with kiln\n"
    verify_ssh_auth "Kiln"
}

# checks to see that ssh keys are registered with kiln
# $1 service name $2 "true"|"false" to end the auth cycle
verify_ssh_auth () {
    ssh_host=false
    case "$1" in
        Github )
            ssh_host="git@github.com"
            service_name="Github"
            webpage_url="https://github.com/settings/ssh"
            instruction="Click 'Add SSH Key', paste into the box, and hit 'Add key'"
            ;;
        Kiln )
            ssh_host="khanacademy@khanacademy.kilnhg.com"
            service_name="Kiln"
            webpage_url="https://khanacademy.kilnhg.com/Keys"
            instruction="Click 'Add a New Key', paste into the box, and hit 'Save key'"
            ;;
        * )
            error "Tried to register ssh keys with unknown service: ${1}"
            exit 1
            ;;
    esac

    info "Checking for $service_name ssh auth"
    if ! ssh -T -v $ssh_host 2>&1 >/dev/null | grep \
        -q -e "Authentication succeeded (publickey)"
    then
        if [ "$2" == "false" ]  # error if auth fails twice in a row
        then
            error "Still no luck with $service_name ssh auth. Ask a dev!"
            ssh_auth_loop $service_name $webpage_url "false"
        else
            # otherwise prompt to upload keys
            success "${service_name}'s ssh auth didn't seem to work\n"
            notice "Let's add your public key to ${service_name}'s webpage"
            info "${tty_bold}${instruction}${tty_normal}\n"
            ssh_auth_loop $service_name $webpage_url "true"
        fi
    else
        success "${service_name} ssh auth succeeded!"
    fi
}

ssh_auth_loop() {
    # a convenience function which lets you copy your public key to your clipboard
    # open the webpage for the site you're pasting the key into or just bailing
    # $1 = service_name
    # $2 = ssh key registration url
    service_name=$1
    service_url=$2
    first_run=$3
    if [ "$first_run" == "true" ]
    then
        notice "1. hit ${tty_bold}o${tty_normal} to open ${service_name} on the web"
        notice "2. hit ${tty_bold}c${tty_normal} to copy your public key to your clipboard"
        notice "3. hit ${tty_bold}t${tty_normal} to test ssh auth for ${service_name}"
        notice "☢. hit ${tty_bold}s${tty_normal} to skip ssh setup for ${service_name}"
        ssh_auth_loop $1 $2 "false"
    else
        user "o|c|t|s) "
        read -n1 ssh_option
        case $ssh_option in
            o|O )
                success "opening ${service_name}'s webpage to register your key!"
                open $service_url
                ssh_auth_loop $service_name $service_url "false"
                ;;
            c|C )
                success "copying your ssh key to your clipboard"
                copy_ssh_key
                ssh_auth_loop $service_name $service_url "false"
                ;;
            t|T )
                printf "\r"
                verify_ssh_auth $service_name "false"
                ;;
            s|S )
                warn "skipping ${service_name} ssh registration"
                ;;
        esac
    fi
}

install_gcc() {
    info "\nChecking for apple command line developer tools..."
    if ! gcc --version >/dev/null 2>&1; then
        if sw_vers | grep ProductVersion | grep -o 10.9; then
            success "Installing command line developer tools"
            # Also, how did you get this dotfiles repo in 10.9 without
            # git auto-triggering the command line tools install process??
            xcode-select --install
            warn "The dotfile setup is stopping now."
            warn "When the install finishes, rerun ${tty_bold}make${tty_normal} to continue. (sorry)"
            exit 1
        else
            warn "Command line tools are *probably available* for your Mac's OS, but..."
            info "Kayla or Kamens or your mentor will gladly upgrade your OS right now\n"
            info "Otherwise, you can always visit developer.apple.com and grab 'em there.\n"
            exit 1
        fi
        # If this doesn't work for you, you can find the most recent
        # version here: https://developer.apple.com/downloads
    else
        success "Great, found gcc! (assuming we also have other recent devtools)"
    fi
}

install_hipchat() {
    info "Checking for HipChat..."
    if ! open -R -g -a HipChat > /dev/null; then
        success "Didn't find HipChat."
        info "Installing HipChat to ~/Applications and opening\n"
        mkdir -p ~/Applications
        hipchat_app_url="http://downloads.hipchat.com.s3.amazonaws.com/osx/HipChat-2.5.6-87.zip"
        curl -o ~/Downloads/HipChat-2.5.6-87.zip $hipchat_app_url
        unzip ~/Downloads/HipChat-2.5.6-87.zip -d ~/Applications > /dev/null
        open -a ~/Applications/HipChat.app
    else
        success "Great! HipChat already installed!"
    fi
}

install_homebrew() {
    info "Checking for mac homebrew"
    # If homebrew is already installed, don't do it again.
    if ! brew --help >/dev/null 2>&1; then
        success "Brew not found. Installing!"
        ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
    else
        success "Great! Mac homebrew already installed!"
    fi
    success "Updating (but not upgrading) Homebrew"
    brew update > /dev/null

    # Make the cellar.
    mkdir -p /usr/local/Cellar
    
    # TODO(marcos) check for other versions of osx perhaps and do some
    # sanity checking and other goodness here. SO VERY SORRY EVERYONE.
    brew tap homebrew/dupes
    brew install apple-gcc42

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
}

install_node() {
    if ! brew ls node >/dev/null 2>&1; then
        brew install node 2>&1
    fi
    if ! npm --version >/dev/null; then
        curl https://npmjs.org/install.sh | sh
    fi
}

install_appengine_launcher() {
    info "Checking for google appengine"
    # First check for the gui appbundle or dev_appserver, if neither are around
    # then install dylan's gae sdk via brew
    if [ ! -d /Applications/GoogleAppEngineLauncher.app ] && ! which dev_appserver.py >/dev/null 2>&1;
    then
        success "Couldn't find App Engine Launcher, installing via homebrew!\n"
        # does not install mac fs events
        brew tap dylanvee/gae_sdk
        brew install gae-sdk
        info "You'll also need to ${tty_bold}pip install pyobjc-framework-FSEvents${tty_normal}\n"
        notice "but ${tty_bold}make deps${tty_normal} in webapp will do this too."
    elif brew ls gae-sdk >/dev/null 2>&1;
    then
        # if dylan's fork is already installed, then update it
        success "Found dylan's frankenserver!"
        if brew outdated | grep -q -e 'gae-sdk'
        then
            success "Upgrading outdated gae-sdk"
            brew upgrade gae-sdk
        fi
    elif [ -d /Applications/GoogleAppEngineLauncher.app ] ||
        which dev_appserver.py >/dev/null 2>&1;
    then
        # if either of these pass, then you have a slower version of dev_appserver
        success "Found vanilla dev_appserver.py"
        warn "You should probably uninstall this and instead install dylan's"
        notice "frankenserver which makes good use of mac-fsevents"
        notice "c.f. ${tty_bold}https://github.com/dylanvee/homebrew-gae_sdk${tty_normal}"
    fi
}

install_phantomjs() {
    info "Checking for phantomjs..."
    if brew ls phantomjs >/dev/null 2>&1; then
        # If phantomjs is already installed via brew, check if it is outdated
        if brew outdated | grep -q -e 'phantomjs'; then
            # If phantomjs is outdated, update it
            success "phantomjs is being upgraded!"
            brew upgrade phantomjs 2>&1
        else
            success "phantomjs already installed and up to date!"
        fi
    else
        # Otherwise, install via brew
        success "phantomjs not found, installing!"
        brew install phantomjs 2>&1
    fi
}

install_helpful_tools() {
    # This is useful for profiling
    # cf. http://www.khanacademy.org/r/fun-with-miniprofiler
    info "Would you like to install qcachegrind to profile performance woes?"
    notice "c.f. ${tty_bold}http://www.khanacademy.org/r/fun-with-miniprofiler${tty_normal}"
    user "y | N) "
    read -n1 yepnope
    case $yepnope in
        y|Y )
            success "Great, installing qcachegrind!"
            if ! brew ls qcachegrind >/dev/null 2>&1; then
                brew install qcachegrind 2>&1
            else
                info "qcachegrind already installed!\n"
            fi
            ;;
        * )
            success "Not installing qcachegrind (you can always do it later!)"
        ;;
    esac
}


echo "\n"
success "Running Khan Installation Script 1.1\n"
warn "Warning: This is only tested on Mac OS 10.9 (Mavericks)\n"
notice "After each statement, either something will open for you to"
notice "interact with, or a script will run for you to use\n"
notice "Press enter when a download/install is completed to go to"
notice "the next step (including this one)"

read -p "Press enter to continue..."

# Run sudo once at the beginning to get the necessary permissions.
notice "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

update_path
maybe_generate_ssh_keys
register_ssh_keys
install_gcc
install_hipchat
install_homebrew
update_git
install_node
install_appengine_launcher
install_phantomjs
install_helpful_tools

notice "You might be done! \n\n \
You should open a new shell to pick up any changes."
