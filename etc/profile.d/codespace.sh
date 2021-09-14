# If interactive
if [ "$PS1" ]; then

    # If not root
    if [ "$(whoami)" != "root" ]; then

        # Configure cd to default to workspace
        alias cd="HOME=/workspaces/$RepositoryName cd"

        # Configure prompt
        prompt() {
            local dir="$(dirs +0)" # CWD with ~ for home
            dir="${dir%/}/" # Remove trailing slash (in case in /) and then re-append
            dir=${dir#"/workspaces/$RepositoryName/"} # Left-trim workspace
            dir="${dir} $ " # Add prompt
            dir=${dir#" "} # Trim leading whitespace (in case in workspace)
            echo -n "${dir}"
            echo -en "\033]0;$PWD\a"
        }
        PS1='$(prompt)'
    fi
fi
