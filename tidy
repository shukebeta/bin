#!/bin/bash

cleanup_file() {
    local file="$1"
    if file "$file" | grep -q "text"; then
        sed -i 's/[[:space:]]*$//' "$file"
        echo "Cleaned: $file"
    fi
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <file|directory>"
    exit 1
fi

target="$1"

if [[ -f "$target" ]]; then
    cleanup_file "$target"
elif [[ -d "$target" ]]; then
    find "$target" -type f | while read -r file; do
        cleanup_file "$file"
    done
else
    echo "Error: $target is not a valid file or directory"
    exit 1
fi