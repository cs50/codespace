# If not root
if [ `id -u` -ne 0 ]; then

    # Library (from cs50/cli; absent in images built before help50 landed there)
    if [ -f /opt/cs50/lib/cli ]; then
        . /opt/cs50/lib/cli
    fi

    # Check if running locally and set $RepositoryName if not already set
    if [[ "$CODESPACES" != "true" && -z "$RepositoryName" ]]; then
        export RepositoryName=$(ls -1t --color=never /workspaces | tail -1 | sed 's:/*$::')
        export LOCAL_WORKSPACE_FOLDER="/workspaces/$RepositoryName"
    fi

    # Where help50's helpers look for misplaced files (cs50/cli defaults this to $HOME)
    export WORKDIR="/workspaces/$RepositoryName"

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

    # Configure cd to default to workspace
    alias cd="HOME=\"/workspaces/$RepositoryName\" cd"

    # Rewrite URL in stderr
    # https://stackoverflow.com/a/52575087/5156190
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
    # https://stackoverflow.com/a/64868901
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

    # help50 hooks, called by _help50 in /etc/profile.d/help50.sh after each command.
    # When no local helper has advice, these relay the failed command's output to the
    # help50 VS Code extension via command50, which shows a "help50" button in the
    # terminal's title bar; clicking it asks the CS50 Duck to explain the error.
    # command50 runs detached with output discarded so the prompt isn't delayed and a
    # missing extension server degrades silently.
    _help50_button() {
        ( command50 help50.showButton "$1" "$2" > /dev/null 2>&1 & )
        _HELP50_BUTTON=1
    }
    _help50_hide() {
        if [[ -n "$_HELP50_BUTTON" ]]; then
            ( command50 help50.hideButton > /dev/null 2>&1 & )
            unset _HELP50_BUTTON
        fi
    }

    # A helper had advice: show it here, as in cs50/cli. No button, since the advice is
    # already on screen; a button still showing is about an earlier command.
    _helpful() {
        for name in n no y yes; do
            alias $name=_rhetorical # Intercept answers to the rhetorical question
        done
        _alert "$(_ansi "$1")"
        _help50_hide
    }

    # No helper matched: offer the duck the failed command's output to explain.
    # If there's no output (e.g., grep with no match, or a program exiting 1), there's
    # nothing to explain, and any button still showing is about an earlier command.
    _helpless() {
        if [[ -z "${1//[[:space:]]/}" ]]; then
            _help50_hide
            return
        fi
        _alert "$(_ansi "🦆 Click \`help50\` above for help with that error.")"
        _help50_button ask "$1"
    }

    # Command succeeded: hide the button, if showing
    _helped() {
        _help50_hide
    }
fi
