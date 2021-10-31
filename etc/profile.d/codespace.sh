# If interactive
if [ "$PS1" ]; then

    # If not root
    if [ "$(whoami)" != "root" ]; then

        # Rewrites URLs of the form http://HOST:PORT as https://$CODESPACE_NAME.githubpreview.dev:PORT
        _hostname() {

            # If in cloud
            if [[ "$CODESPACES" == "true" ]]; then
                local url="http://[^:]+:(\x1b\[[0-9;]*m)?([0-9]+)(\x1b\[[0-9;]*m)?"
                while read; do
                    echo "$REPLY" | sed -E "s#${url}#https://${CODESPACE_NAME}-\2.githubpreview.dev#"
                done

            # Else if local
            else
                tee
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

        # Configure cd to default to workspace
        alias cd="HOME=\"$CODESPACE_VSCODE_FOLDER\" cd"

        # Ensure files created with `code` are autosaved too
        code() {

            # Check whether run with any options
            local options=false
            for arg in "$@"; do
                if [[ "$arg" =~ ^- ]]; then
                    options=true
                    break
                fi
            done

            # If not, assume less comfortable
            if [ "$options" = false ]; then

                # For each file
                for arg in "$@"; do

                    # If file doesn't exist
                    if [ ! -f "$arg" ]; then

                        # If first letter is capitalized but one of these languages
                        if [[ "$arg" =~ ^[A-Z].*\.(c|css|html|js|py)$ ]]; then
                            read -p "Are you sure you want to create $(tput bold)$arg$(tput sgr0)? Filenames aren't usually capitalized. [y/N] " -r
                            if [[ ! "${REPLY,,}" =~ ^y|yes$ ]]; then
                                return
                            fi
                        fi

                        # If first letter is lowercase but Java
                        if [[ "$arg" =~ ^[a-z].*\.java$ ]]; then
                            read -p "Are you sure you want to create $(tput bold)$arg$(tput sgr0)? Filenames are usually capitalized. [y/N] " -r
                            if [[ ! "${REPLY,,}" =~ ^y|yes$ ]]; then
                                return
                            fi
                        fi

                        # If file extension is capitalized
                        if [[ "$arg" =~ \.[A-Z]+$ ]]; then
                            read -p "Are you sure you want to create $(tput bold)$arg$(tput sgr0)? File extensions aren't usually capitalized. [y/N] " -r
                            if [[ ! "${REPLY,,}" =~ ^y|yes$ ]]; then
                                return
                            fi
                        fi

                        # Touch access time instead of modification time, so that `make` doesn't think file has changed
                        touch -a "$arg" 2> /dev/null
                    fi
                done
            fi
            command code "$@"
        }

        # Rewrite URLs in stdout and stderr
        flask() {
            command flask "$@" |& _hostname
        }

        # Discourage use of git in repository
        git() {
            if [[ "$PWD/" =~ ^/workspaces/"$RepositoryName"/ ]]; then
                echo "You are in a repository managed by CS50. Git is disabled."
            else
                command git "$@"
            fi
        }

        # Rewrite URLs in stdout
        http-server() {
            command http-server "$@" | _hostname | uniq
        }
    fi
fi
