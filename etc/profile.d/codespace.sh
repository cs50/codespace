if [ "$PS1" ]; then
    if [ "$(whoami)" != "root" ]; then
        alias cd="HOME=/workspaces/$RepositoryName cd"
        PS1='$ '
    fi
fi
