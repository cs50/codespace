#!/bin/bash

set -e

export HOME=/home/ubuntu

args=( $INPUT_CHECK50_ARGS )

autograde() {
    # Run check50 and map JSON results to autograding.json format for GitHub Classroom
    jq_filter='if .error != null then
        [
            {
                "name": .error.value,
                "run": "false",
                "points": 1
            }
        ]
    else
        .results | map({
            "name": .description,
            "run": .passed | not | not | tostring,
            "points": 1
        })
    end | {"tests": .}'

    results="$(check50 --local --output=json "${args[@]}" | jq -c "$jq_filter")"
    echo "::set-output name=results::$results"
}

autograde
