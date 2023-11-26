# Dependencies
if [[ ! $(which ansi2txt) ]]; then
    echo "Missing ansi2txt"
    exit 1
elif [[ ! $(which col) ]]; then
    echo "Missing col"
    exit 1
fi

duck () {
    if [[ "$1" == "on" ]]; then
        rm --force "/tmp/noduck"
    elif [[ "$1" == "off" ]]; then
        touch "/tmp/noduck"
        rm --force "/tmp/ddb50.$$" "/tmp/ddb50.$$.argv"
        unset RUBBERDUCKING
    elif [[ "$1" == "status" ]]; then
        if [[ -f "/tmp/noduck" ]]; then
            echo "off"
        else
            echo "on"
        fi
    else
        echo "Usage: duck [off|on|status]"
        exit 1
    fi
    exit 0
}

_prompt_command () {
    local exit_status=$?
    if [[ $(duck status) == "on" ]]; then
        if [[ $exit_status -ne 0 ]]; then
            HISTFILE=/tmp/ddb50.$$.argv history -a
            local argv=$(tail -n 1 /tmp/ddb50.$$.argv)
            local txt=$(cat "/tmp/ddb50.$$" 2> /dev/null | ansi2txt | col -b | awk '!f && /\\$/ { sub(/\\$/, ""); getline t; $0 = $0 t; } !/\\$/ { f=1 } 1' | tail -n +2)
            if [[ ! -z "$txt" ]]; then
                echo "$txt" > /tmp/log
                echo "$argv" > /tmp/log.argv
                echo "$PWD" > /tmp/log.pwd
            fi
        fi
        echo -n > "/tmp/ddb50.$$"
        echo -n > "/tmp/ddb50.$$.argv"
        echo -n > "/tmp/ddb50.$$.pwd"
    fi
}

if [[ $(duck status) == "on" ]]; then
    if [[ -z "$RUBBERDUCKING" ]]; then
        exec > >(tee -a "/tmp/ddb50.$$") 2>&1
        export RUBBERDUCKING="/tmp/ddb50.$$"
    fi
fi

export PROMPT_COMMAND=_prompt_command
