#!/bin/bash

# Common git utility functions for bin scripts

# Function to check for uncommitted changes and exit if found
check_uncommitted_changes() {
    # Check if there are any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Warning: You have uncommitted changes. Operation cancelled."
        echo "Files with changes:"
        git status --porcelain | sed 's/^/  /'
        echo
        echo "Please commit or stash your changes before switching branches."
        exit 1
    fi
}