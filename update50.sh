#!/bin/bash

# Check for gh and install it if not available (temporary)
if ! command -v gh &> /dev/null; then
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
fi

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
    
    # Trigger rebuild
    if command -v gh &> /dev/null; then
        
        # Use gh cli to rebuild if available
        gh cs rebuild --repo $GITHUB_REPOSITORY --full
        echo "Your codespace is now being rebuilt, please keep the browser window open and wait for it to reload.\nDo not perform any actions until the rebuild is complete."
    else
    
        # Fall back to command50
        command50 github.codespaces.rebuildEnvironment
    fi

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
    if command -v gh &> /dev/null; then
        
        # Use gh cli to rebuild if available
        gh cs rebuild --repo $GITHUB_REPOSITORY --full
        echo "Your codespace is now being rebuilt, please keep the browser window open and wait for it to reload.\nDo not perform any actions until the rebuild is complete."
    else
    
        # Fall back to command50
        command50 github.codespaces.rebuildEnvironment
    fi

else
    echo "Your codespace is already up-to-date!"
fi
