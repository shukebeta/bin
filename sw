#!/bin/bash

# Source common git functions
source "$(dirname "${BASH_SOURCE[0]}")/git-common.sh"

find_worktree_for_branch() {
    local branch="$1"
    git worktree list --porcelain | awk -v b="refs/heads/$branch" '
        /^worktree / { wt=$2 }
        $0 == "branch " b { print wt }
    '
}

# Switch to a branch, or cd into its worktree if it is checked out in another one.
# Returns 0 on success, 1 on failure.
checkout_or_cd_worktree() {
    local branch="$1"
    local wt_path cur_top
    wt_path=$(find_worktree_for_branch "$branch")
    cur_top=$(git rev-parse --show-toplevel 2>/dev/null)

    if [ -n "$wt_path" ] && [ "$wt_path" != "$cur_top" ]; then
        echo "Branch '$branch' is in worktree: $wt_path"
        cd "$wt_path" || return 1
        return 0
    fi

    if git co "$branch"; then
        echo "Switched to branch '$branch'"
        return 0
    fi
    return 1
}

show_usage() {
    echo "Usage:"
    echo "  sw <ticket_number> [suffix]    # switches to feature/mt-<number>-axo[suffix] or feature/mt-<number>-[suffix]"
    echo "  gsw <branch-name>              # Switches to specified branch"
    echo "  sw|gsw -                       # Switches to previous branch"
    return 1
}

# Function to switch to a branch with proper error handling
switch_branch() {
    local branch_name="$1"

    # Skip uncommitted changes check when switching to previous branch
    if [ "$branch_name" != "-" ]; then
        check_uncommitted_changes
    fi

    git fetch

    # "-" (previous branch) can't be resolved to a worktree path; check it out directly.
    if [ "$branch_name" = "-" ]; then
        if git co "$branch_name"; then
            echo "Switched to branch '$branch_name'"
        else
            echo "Failed to switch to branch '$branch_name'"
            return 1
        fi
        return
    fi

    if ! checkout_or_cd_worktree "$branch_name"; then
        echo "Failed to switch to branch '$branch_name'"
        return 1
    fi
}

# Function to handle branch name construction and switching
handle_branch_switch() {
    local prefix="$1"
    shift  # Remove first argument (prefix) so $1 becomes the ticket number

    # Check if at least one argument is provided
    if [ -z "$1" ]; then
        show_usage
        return 1
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
        checkout_or_cd_worktree "$branch_name_axo"
        return
    elif git show-ref --verify --quiet "refs/heads/$branch_name"; then
        checkout_or_cd_worktree "$branch_name"
        return
    fi

    # No local branches found, fetch and check remote branches
    echo "Local branches not found, fetching..."
    git fetch

    # Check remote branches (try -axo first, then regular)
    if git show-ref --verify --quiet "refs/remotes/origin/$branch_name_axo"; then
        checkout_or_cd_worktree "$branch_name_axo"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        checkout_or_cd_worktree "$branch_name"
    else
        echo "Neither branch '$branch_name_axo' nor '$branch_name' found. Attempting to switch to '$1' directly."
        if ! checkout_or_cd_worktree "$1"; then
            echo "Failed to switch to branch '$1'"
            return 1
        fi
    fi
}

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    return 1
fi

# Get the script name
script_name=$(basename "${BASH_SOURCE[0]}")

case "$script_name" in
    sw)
        handle_branch_switch "mt" "$@"
        ;;

    gsw)
        # Check if exactly one argument is provided
        if [ -z "$1" ]; then
            show_usage
            return 1
        fi

        switch_branch "$1"
        ;;

    *)
        echo "Error: Script must be named 'sw' or 'gsw'"
        return 1
        ;;
esac
