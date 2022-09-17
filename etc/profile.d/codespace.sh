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

    # Alias BFG
    alias bfg="java -jar /opt/share/bfg-1.14.0.jar"

    # Configure cd to default to workspace
    alias cd="HOME=\"$CODESPACE_VSCODE_FOLDER\" cd"

    # Rewrite URL in stderr
    # https://stackoverflow.com/a/52575087/5156190
    flask() {
        command flask "$@" 2> >(_hostname >&2)
    }

    # Discourage use of git in repository
    git() {
        if [[ "$PWD/" =~ ^/workspaces/"$RepositoryName"/ ]]; then
            echo "You are in a repository managed by CS50. Git is disabled. See https://cs50.ly/git."
        else
            command git "$@"
        fi
    }

    # Rewrite URLs in stdout
    http-server() {
        command http-server "$@" | _hostname | uniq
    }

    # Manual sections to search
    export MANSECT=3,2,1
fi
