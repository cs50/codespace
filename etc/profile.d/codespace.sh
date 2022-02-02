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

    # Alias `code` to CS50's (which otherwise has lower priority in $PATH)
    alias code="/opt/cs50/bin/code"

    # Rewrite URL in stderr
    # https://stackoverflow.com/a/52575087/5156190
    flask() {
        echo "Launching flask server..."
        rm -rf /tmp/flask
        (command flask "$@" &> /tmp/flask & sleep 3) && tail -f /tmp/flask | _hostname
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
        echo "Launching http-server..."
        rm -rf /tmp/http-server
        (command http-server "$@" &> /tmp/http-server & sleep 3) && tail -f /tmp/http-server | _hostname | uniq
    }

    function teardown() {
        killall -9 flask
        killall -9 http-server
    }

    trap "teardown &> /dev/null" EXIT SIGINT SIGHUP ERR
fi
