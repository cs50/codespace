#!/bin/bash

# Get remote JSON
REMOTE=$(curl https://code.cs50.io/.devcontainer.json 2> /dev/null)
if [ $? -ne 0 ]; then
    echo "Could not update codespace. Try again later."
    exit 1
fi

# Get local JSON
LOCAL=$(cat "/workspaces/$RepositoryName/.devcontainer.json" 2> /dev/null)

# If versions differ (or forcibly updating)
if [ "$REMOTE" != "$LOCAL" ] || [ "$1" == "-f" ] || [ "$1" == "--force" ]; then

    # Update JSON
    echo "$REMOTE" > "/workspaces/$RepositoryName/.devcontainer.json"

    # Prompt to rebuild
    prompt50 "Updating..." "To update your codespace, click \"Rebuild\" when prompted." github.codespaces.rebuildEnvironment
else
    echo "Your codespace is up-to-date!"
fi
