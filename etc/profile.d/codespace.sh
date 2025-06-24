# If not root
if [ "$(whoami)" != "root" ]; then

    # Check if running locally and set $RepositoryName if not already set
    if [[ "$CODESPACES" != "true" && -z "$RepositoryName" ]]; then
        export RepositoryName=$(ls -1t --color=never /workspaces | tail -1 | sed 's:/*$::')
        export LOCAL_WORKSPACE_FOLDER="/workspaces/$RepositoryName"
    fi

    # Rewrites URLs of the form http://HOST:PORT as https://$CODESPACE_NAME.app.github.dev:PORT
    _hostname() {
        # If in cloud
        if [[ "$CODESPACES" == "true" ]]; then
            local url="http://[^:]+:(\x1b\[[0-9;]*m)?([0-9]+)(\x1b\[[0-9;]*m)?"
            while read; do
                echo "$REPLY" | sed -E "s#${url}#https://${CODESPACE_NAME}-\2.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}#"
            done
        # Else if local
        else
            tee
        fi
    }

    # Filter out the http-server version information
    _version() {
        local version="http-server version:"
        while read; do
            if [[ ! $REPLY =~ ${version} ]]; then
                echo "$REPLY"
            fi
        done
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
    alias cd="HOME=\"/workspaces/$RepositoryName\" cd"

    # Rewrite URL in stderr
    flask() {
        command flask "$@" --host=127.0.0.1 2> >(_hostname >&2)
    }

    # Generate a diagnostic report for troubleshooting
    diagnose() {
        code /workspaces/$RepositoryName/diagnose.log && \
        cat /etc/issue > diagnose.log && \
        code --list-extensions >> diagnose.log && \
        pip3 show CS50-VSIX-Client >> diagnose.log 2>> diagnose.log
    }

    # Override --system credential.helper to use $CS50_TOKEN instead of $GITHUB_TOKEN
    command git config --global --replace-all credential.helper ""
    command git config --global --add credential.helper /opt/cs50/bin/gitcredential_github.sh

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
        command http-server "$@" | _hostname | _version | uniq
    }

    # ✅ Fix for Issue #145: Append to .gitignore without overwriting
    GITIGNORE_PATH="/workspaces/$RepositoryName/.gitignore"

    touch "$GITIGNORE_PATH"

    append_if_missing() {
        grep -qxF "$1" "$GITIGNORE_PATH" || echo "$1" >> "$GITIGNORE_PATH"
    }

    append_if_missing "*"
    append_if_missing "!.gitignore"
    append_if_missing "!/.github/"
    append_if_missing "node_modules/"

fi
