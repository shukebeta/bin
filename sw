#!/bin/bash

# Source common git functions
source "$(dirname "$0")/git-common.sh"

show_usage() {
    echo "Usage:"
    echo "  sw <ticket_number> [suffix]    # switches to feature/mt-<number>-axo[suffix] or feature/mt-<number>-[suffix]"
    echo "  gsw <branch-name>              # Switches to specified branch"
    echo "  sw|gsw -                       # Switches to previous branch"
    exit 1
}

# Function to switch to a branch with proper error handling
switch_branch() {
    local branch_name="$1"

    # Skip uncommitted changes check when switching to previous branch
    if [ "$branch_name" != "-" ]; then
        check_uncommitted_changes
    fi

    if git fetch && git co "$branch_name"; then
        echo "Switched to branch '$branch_name'"
    else
        echo "Failed to switch to branch '$branch_name'"
        exit 1
    fi
}

# Function to handle branch name construction and switching
handle_branch_switch() {
    local prefix="$1"
    shift  # Remove first argument (prefix) so $1 becomes the ticket number

    # Check if at least one argument is provided
    if [ -z "$1" ]; then
        show_usage
        exit 1
    fi


    # Special case for "-"
    if [ "$1" = "-" ]; then
        switch_branch "-"
        return
    fi

    # Skip uncommitted changes check
    check_uncommitted_changes

    # Construct possible branch names
    local base_name="feature/$prefix-$1"
    local branch_name_axo="${base_name}-axo"
    local branch_name="${base_name}"
    # Add suffix if provided
    if [ -n "$2" ]; then
        branch_name_axo="${branch_name_axo}$2"      # Keep no dash for -axo branches
        branch_name="${branch_name}-$2"             # Add dash for regular branches
    fi

    # Check local branches first (try -axo first, then regular)
    if git show-ref --verify --quiet "refs/heads/$branch_name_axo"; then
        git co "$branch_name_axo"
        echo "Switched to branch '$branch_name_axo'"
        return
    elif git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git co "$branch_name"
        echo "Switched to branch '$branch_name'"
        return
    fi

    # No local branches found, fetch and check remote branches
    echo "Local branches not found, fetching..."
    git fetch

    # Check remote branches (try -axo first, then regular)
    if git show-ref --verify --quiet "refs/remotes/origin/$branch_name_axo"; then
        git co "$branch_name_axo"
        echo "Switched to branch '$branch_name_axo'"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        git co "$branch_name"
        echo "Switched to branch '$branch_name'"
    else
        echo "Neither branch '$branch_name_axo' nor '$branch_name' found. Attempting to switch to '$branch_name_axo' anyway."
        if git co "$branch_name_axo"; then
            echo "Switched to branch '$branch_name_axo'"
        else
            echo "Failed to switch to branch '$branch_name_axo'"
            exit 1
        fi
    fi
}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Get the script name
script_name=$(basename "$0")

case "$script_name" in
    sw)
        handle_branch_switch "mt" "$@"
        ;;


    gsw)
        # Check if exactly one argument is provided
        if [ -z "$1" ]; then
            show_usage
            exit 1
        fi

        switch_branch "$1"
        ;;

    *)
        echo "Error: Script must be named 'sw' or 'gsw'"
        exit 1
        ;;
esac
