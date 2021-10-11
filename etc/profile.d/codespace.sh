# If interactive
if [ "$PS1" ]; then

    # If not root
    if [ "$(whoami)" != "root" ]; then

        # Configure cd to default to workspace
        alias cd="HOME=\"$CODESPACE_VSCODE_FOLDER\" cd"

        # Ensure files created with `code` are autosaved too
        code() {
            local options=false
            for arg in "$@"; do
                if [[ "$arg" =~ ^- ]]; then
                    options=true
                    break
                fi
            done
            if [ "$options" = false ]; then
                for arg in "$@"; do
                    if [ ! -f "$arg" ]; then
                        touch "$arg" 2> /dev/null
                    fi
                done
            fi
            command code "$@"
        }

        # Discourage use of git in repository
        git() {
            if [[ "$PWD" =~ "^/workspaces/$RepositoryName" ]]; then
                echo "You are in a repository managed by CS50. Git is disabled."
            else
                command git "$@"
            fi
        }

        # Configure prompt
        _prompt() {
            local dir="$(dirs +0)" # CWD with ~ for home
            dir="${dir%/}/" # Remove trailing slash (in case in /) and then re-append
            dir=${dir#"/workspaces/$RepositoryName/"} # Left-trim workspace
            dir="${dir} $ " # Add prompt
            dir=${dir#" "} # Trim leading whitespace (in case in workspace)
            echo -n "${dir}"
        }
        PS1='$(_prompt)'
    fi
fi
