#!/bin/bash
echo protocol=https
echo host=github.com
echo path=
echo username=PersonalAccessToken
if [[ ! -z "$CS50_TOKEN" ]]; then
    echo password="$CS50_TOKEN"
else
    echo password="$GITHUB_TOKEN"
fi
