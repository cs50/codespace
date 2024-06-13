#!/bin/bash

# Check for -t flag for develop mode
if [ "$1" == "-t" ]; then
    # Use the specified tag to build the URL
    tag=$2
    url="https://cs50.dev/devcontainer.json?tag=$tag"

    # Fetch and save the JSON
    curl --fail --header "Cache-Control: no-cache" --silent --location "$url" > "/workspaces/$RepositoryName/.devcontainer.json"
    if [ $? -ne 0 ]; then
        echo "Could not update codespace with tag $tag. Try again later."
        exit 1
    fi
    command50 github.codespaces.rebuildEnvironment
    exit 0
fi

# Get remote JSON
remote=$(curl --fail --header "Cache-Control: no-cache" --silent --location https://cs50.dev/devcontainer.json)
if [ $? -ne 0 ]; then
    echo "Could not update codespace. Try again later."
    exit 1
fi

# Parse remote JSON
image=$(echo $remote | jq .image 2> /dev/null)
regex='"ghcr.io/cs50/codespace:([0-9a-z]*)"'
if [[ "$image" =~ $regex ]]; then
    tag="${BASH_REMATCH[1]}"
else
  echo "Could not determine latest version. Try again later."
  exit 1
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
    command50 github.codespaces.rebuildEnvironment

else
    echo "Your codespace is already up-to-date!"
fi
