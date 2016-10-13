bad_usage_get_yn_input=100

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

# Print update in blue.
# $1: update message
update() {
    printf "\e[0;34m$1\e[0m\n"
}

# Get yes or no input from the user. Return default value if the user does no
# enter a valid value (y, yes, n, or no with any captialization).
# $1: prompt
# $2: default value
get_yn_input() {
    if [ "$2" = "y" ]; then
        prompt="${1} [Y/n]: "
    elif [ "$2" = "n" ]; then
        prompt="${1} [y/N]: "
    else
        echo "Error: bad default value given to get_yn_input()" >&2
        exit $bad_usage_get_yn_input
    fi

    read -r -p "$prompt" input
    case "$input" in
        [yY][eE][sS] | [yY])
            echo "y"
            ;;
        [nN][oO] | [nN])
            echo "n"
            ;;
        *)
            echo $2
            ;;
    esac
}
