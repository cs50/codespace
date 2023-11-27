DEPENDENCIES=(ansi2txt col)
STDOUT="/tmp/ddb50.$$"
ARGV="${STDOUT}.argv"

# Check for dependencies
for cmd in ${DEPENDENCIES[@]}; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing $cmd"
        exit 1
    fi
done

duck() {

    # duck on
    if [[ $1 == on ]]; then
        if [[ -z $RUBBERDUCKING ]]; then
            exec 3>&1 4>&2 # Duplicate file descriptors
            exec > >(tee -a /tmp/ddb50.$$) 2>&1
            export RUBBERDUCKING=1
        fi
        return 0

    # duck off
    elif [[ $1 == off ]]; then
        if [[ ! -z $RUBBERDUCKING ]]; then
            exec 1>&3 2>&4 # Restore file descriptors
            exec 3>&- 4>&- # Close file descriptors
        fi
        rm --force "$STDOUT" "$ARGV"
        unset RUBBERDUCKING
        return 0

    # duck status
    elif [[ $1 == status ]]; then
        if [[ -z $RUBBERDUCKING ]]; then
            echo off
            return 1
        else
            echo on
            return 0
        fi

    # duck -h
    else
        echo "Usage: duck [off|on|status]"
        return 1
    fi
}

_prompt_command() {

    # Last command's exit status
    local exit_status=$?

    # If rubberducking
    if duck status > /dev/null; then

        # If last command erred
        if [[ $exit_status -ne 0 ]]; then

            # Get command
            HISTFILE="$ARGV" history -a
            local argv=$(tail -n 1 "$ARGV")

            # Get command's output
            local txt=$(cat "$STDOUT" 2> /dev/null) # Redirect stderr in case file doesn't exit somehow

            # Remove any ANSI codes
            txt=$(echo "$txt" | ansi2txt | col -b)

            # Remove any line continuations in command
            txt=$(echo "$txt" | awk '!f && /\\$/ { sub(/\\$/, ""); getline t; $0 = $0 t; } !/\\$/ { f=1 } 1')

            # Remove command itself from output
            txt=$(echo "$txt" | tail -n +2)

            # TODO: call help50 with these values
            if [[ ! -z "$txt" ]]; then
                echo "$txt" > /tmp/log
                echo "$argv" > /tmp/log.argv
                echo "$PWD" > /tmp/log.pwd
            fi
        fi

        # Flush logs
        truncate -s 0 "$STDOUT" "$ARGV"
    fi
}
export PROMPT_COMMAND=_prompt_command

# Turn duck off when shell exits
trap 'duck off' EXIT

# Turn duck on by default
duck on
