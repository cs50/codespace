_prompt_command() {

    # Exit status of last command
    exit_status=$?

    # Append to history right away
    history -a

    # If no typescript yet
    if [ -z "$SCRIPT" ]; then

        # Use this shell's PID as typescript's name, exporting so that subshells know script is already running
        export SCRIPT="/tmp/typescript/$$"

        # Ensure parent directory exists
        mkdir --parents $(dirname "$SCRIPT")

        # Make a typescript of everything displayed in terminal
        ## Write \r first so that `script` outputs "Script started..." immediately so we can truncate it
        script --append --command "echo -e -n '\r' && bash --login" --flush --quiet "$SCRIPT"

        # Remove typescript before exiting this shell
        rm --force "$SCRIPT"

        # Try to remove parent directory before exiting this shell
        rmdir --ignore-fail-on-non-empty $(dirname "$SCRIPT")

        # Now exit this shell too
        exit
    fi

    # Ignore duplicates but not commands that begin with spaces
    export HISTCONTROL="ignoredups"

    # Read typescript from disk
    local typescript=$(cat "$SCRIPT")

    # Typescript's command (unused for now)
    local command=$(history 1 | cut -c 8-)

    # Command's PWD (unused for now)
    local pwd="$PWD"

    # File tree (unused for now)
    local tree=$(find "$CODESPACE_VSCODE_FOLDER" -not -path '*/\.*' \( -type d -printf '%P/    \n' , -type f -printf '%P\n' \))

    # Typescript as text
    local text=$(echo "$typescript" | ansi2txt)

    # Typescript as HTML (unused for now)
    local html=$(echo "$typescript" | ansi2html)

    # Truncate typescript before next command
    echo -n > "$SCRIPT"

    # Ask duck for help if exit status non-0 and not ctl-c or ctl-z
    # https://tldp.org/LDP/abs/html/exitcodes.html
    if [ $exit_status -ne 0 ] && [ $exit_status -ne 130 ] && [ $exit_status -ne 148 ]; then
        prompt=$(echo -e "Explain this error:\n\n$text")
        command50 ddb50.ask "$prompt" &
    fi
}

export PROMPT_COMMAND=_prompt_command
