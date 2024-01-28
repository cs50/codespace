#!/bin/bash

# Initialize variables
URL="https://cs50.dev/devcontainer.json"
DEVELOP_MODE=false

# Check for flags
if [ "$1" == "--develop" ]; then
    URL="https://raw.githubusercontent.com/cs50/codespace/develop/devcontainer.json"
    DEVELOP_MODE=true
fi

# Get remote JSON
remote=$(curl --fail --header "Cache-Control: no-cache" --silent --location $URL)
if [ $? -ne 0 ]; then
    echo "Could not update codespace. Try again later."
    exit 1
fi

if $DEVELOP_MODE; then
    remote=$(echo "$remote" | sed 's|/\*[^*]*\*/||g')
    tmpfile=$(mktemp)
    echo "$remote" | jq 'del(.build, .features) | .image="ghcr.io/cs50/codespace:develop"' > "$tmpfile"
    mv "$tmpfile" "/workspaces/$RepositoryName/.devcontainer.json"
    command50 github.codespaces.fullRebuildEnvironment
    exit 0
else
    # Parse remote JSON to get the image tag
    image=$(echo $remote | jq .image 2> /dev/null)
    regex='"ghcr.io/cs50/codespace:([0-9a-z]*)"'
    if [[ "$image" =~ $regex ]]; then
        tag="${BASH_REMATCH[1]}"
    else
        echo "Could not determine latest version. Try again later."
        exit 1
    fi
fi

# Get local version
issue=$(tail -1 /etc/issue 2> /dev/null)

# Get local JSON
local=$(cat "/workspaces/$RepositoryName/.devcontainer.json" 2> /dev/null)

# If versions differ (or forcibly updating)
if [ "$remote" != "$local" ] || [ "$tag" != "$issue" ] || [ "$1" == "-f" ] || [ "$1" == "--force" ]; then

    # Update JSON
    echo "$remote" > "/workspaces/$RepositoryName/.devcontainer.json"

    # Trigger rebuild
    command50 github.codespaces.fullRebuildEnvironment

else
    echo "Your codespace is already up-to-date!"
fi
