#!/bin/bash

# Path management library functions
# This file contains all the reusable functions for path management

# Configuration
BASHRC_FILE="$HOME/.bashrc"
PATH_ARRAY_VAR="CUSTOM_PATHS"

# Function to expand tilde to home directory
expand_tilde() {
    local path="$1"
    
    # If path starts with ~/, replace with $HOME/
    if [[ "$path" == "~/"* ]]; then
        echo "${HOME}${path:1}"
    # If path is exactly ~, replace with $HOME
    elif [[ "$path" == "~" ]]; then
        echo "$HOME"
    # If path starts with ~username/, expand to that user's home
    elif [[ "$path" == "~"*/* ]]; then
        # This is more complex and may not work in all environments
        # For safety, we'll use eval (though generally discouraged)
        eval echo "$path"
    else
        # No tilde, return as-is (path is already expanded or doesn't contain ~)
        echo "$path"
    fi
}

# Function to normalize path separators (convert Windows to Unix style)
normalize_path() {
    local input_path="$1"
    
    # Convert Windows backslashes to forward slashes
    local normalized=$(echo "$input_path" | sed 's|\\|/|g')
    
    # Convert Windows drive letters (C:, D:, etc.) to Unix style (/c, /d, etc.)
    # Handle cases like "C:/path" or "C:\path"
    if [[ "$normalized" =~ ^[A-Za-z]: ]]; then
        local drive_letter=$(echo "$normalized" | cut -c1 | tr '[:upper:]' '[:lower:]')
        local remaining_path=$(echo "$normalized" | cut -c3-)
        normalized="/$drive_letter$remaining_path"
    fi
    
    echo "$normalized"
}

# Function to check if a directory exists
dir_exists() {
    local path="$1"
    local expanded_path=$(expand_tilde "$path")
    
    if [ -d "$expanded_path" ]; then
        return 0
    else
        return 1
    fi
}

# Function to read current custom paths from .bashrc
# This function normalizes each path by removing accidental leading/trailing
# whitespace inside the quotes so downstream joins don't introduce stray spaces.
read_custom_paths() {
    if [ ! -f "$BASHRC_FILE" ]; then
        return 0
    fi

    # Helper to clean a quoted string: remove surrounding quotes then trim whitespace
    _clean_quoted() {
        local q="$1"
        local inner=$(echo "$q" | sed 's/^"//;s/"$//')
        echo "$(echo "$inner" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    }

    # Check if we have a multiline CUSTOM_PATHS array
    if grep -q "^$PATH_ARRAY_VAR=($" "$BASHRC_FILE" 2>/dev/null; then
        local paths=""
        local in_array=false

        while IFS= read -r line; do
            if [[ "$line" =~ ^CUSTOM_PATHS=\($ ]]; then
                in_array=true
                continue
            elif [[ "$line" =~ ^[[:space:]]*\)$ ]] && [ "$in_array" = true ]; then
                break
            elif [ "$in_array" = true ] && [[ "$line" =~ ^[[:space:]]*\".*\"[[:space:]]*$ ]]; then
                # Extract the quoted token, clean it, then re-quote
                local raw=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                local cleaned=$(_clean_quoted "$raw")
                local quoted="\"$cleaned\""
                if [ -n "$paths" ]; then
                    paths="$paths $quoted"
                else
                    paths="$quoted"
                fi
            fi
        done < "$BASHRC_FILE"

        echo "$paths"
    elif grep -q "^$PATH_ARRAY_VAR=" "$BASHRC_FILE" 2>/dev/null; then
        # Fallback to single-line format (backward compatibility)
        # Extract quoted substrings, clean each, and re-assemble
        local line=$(grep "^$PATH_ARRAY_VAR=" "$BASHRC_FILE" | head -1)
        local quoted_list=$(echo "$line" | sed 's/^[^(]*(//' | sed 's/)$//' | grep -o '"[^"]*"')
        local out=""
        while IFS= read -r q; do
            if [ -n "$q" ]; then
                local cleaned=$(_clean_quoted "$q")
                local quoted="\"$cleaned\""
                if [ -n "$out" ]; then
                    out="$out $quoted"
                else
                    out="$quoted"
                fi
            fi
        done < <(echo "$quoted_list")
        echo "$out"
    fi
}

# Function to create a backup of .bashrc
backup_bashrc() {
    if [ -f "$BASHRC_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="${BASHRC_FILE}.backup_${timestamp}"
        
        if cp "$BASHRC_FILE" "$backup_file"; then
            echo "✓ Backup created: $backup_file"
            return 0
        else
            echo "✗ Failed to create backup: $backup_file"
            return 1
        fi
    else
        echo "✓ No .bashrc file to backup"
        return 0
    fi
}

# Function to restore .bashrc from backup
restore_bashrc() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        # Find the most recent backup
        backup_file=$(ls -t "${BASHRC_FILE}.backup_"* 2>/dev/null | head -1)
        if [ -z "$backup_file" ]; then
            echo "✗ No backup files found"
            return 1
        fi
    fi
    
    if [ -f "$backup_file" ]; then
        if cp "$backup_file" "$BASHRC_FILE"; then
            echo "✓ Restored .bashrc from: $backup_file"
            return 0
        else
            echo "✗ Failed to restore from: $backup_file"
            return 1
        fi
    else
        echo "✗ Backup file not found: $backup_file"
        return 1
    fi
}

# Function to list available backups
list_backups() {
    local backups=$(ls -t "${BASHRC_FILE}.backup_"* 2>/dev/null)
    
    if [ -z "$backups" ]; then
        echo "No backup files found"
        return 1
    fi
    
    echo "Available .bashrc backups:"
    echo "=========================="
    local count=1
    for backup in $backups; do
        local timestamp=$(basename "$backup" | sed 's/.*backup_//')
        # Format: 20250706_105720 -> 2025-07-06 10:57:20
        local date_part=$(echo "$timestamp" | cut -d'_' -f1)
        local time_part=$(echo "$timestamp" | cut -d'_' -f2)
        local formatted_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2}"
        local formatted_time="${time_part:0:2}:${time_part:2:2}:${time_part:4:2}"
        local size=$(ls -lh "$backup" | awk '{print $5}')
        echo "$count. $(basename "$backup") - $formatted_date $formatted_time ($size)"
        ((count++))
    done
}

# Function to clean old backups (keep only the 5 most recent)
cleanup_old_backups() {
    local backups=$(ls -t "${BASHRC_FILE}.backup_"* 2>/dev/null)
    local count=0
    local removed=0
    
    for backup in $backups; do
        ((count++))
        if [ $count -gt 5 ]; then
            if rm "$backup" 2>/dev/null; then
                echo "Removed old backup: $(basename "$backup")"
                ((removed++))
            fi
        fi
    done
    
    if [ $removed -gt 0 ]; then
        echo "Cleaned up $removed old backup(s), kept 5 most recent"
    fi
}

# Function to write custom paths array to .bashrc
write_custom_paths() {
    local paths_string="$1"
    
    # Create backup before making changes
    if ! backup_bashrc; then
        echo "⚠️  Failed to create backup - proceeding anyway"
        echo "⚠️  Consider manually backing up your .bashrc first"
    fi
    
    # Remove existing CUSTOM_PATHS block and related exports
    if [ -f "$BASHRC_FILE" ]; then
        # Use a more comprehensive approach to remove the entire block safely
        # This removes everything from the comment to the final export statement
        sed -i '/^# Custom PATH management - added by path script$/,/^export PATH=.*\$CUSTOM_PATHS_STR/d' "$BASHRC_FILE"
        
        # Also clean up any remaining individual lines that might be left over
        sed -i "/^$PATH_ARRAY_VAR=/d" "$BASHRC_FILE"
        sed -i "/^CUSTOM_PATHS_STR=/d" "$BASHRC_FILE"
        sed -i '/^CUSTOM_PATHS=(/,/^)/d' "$BASHRC_FILE"
        
        # Verify .bashrc syntax after modifications
        if ! bash -n "$BASHRC_FILE" 2>/dev/null; then
            echo "✗ .bashrc syntax error detected after modification!"
            echo "✗ Attempting to restore from backup..."
            if restore_bashrc; then
                echo "✓ .bashrc restored successfully"
                return 1
            else
                echo "✗ Failed to restore .bashrc - please check manually"
                return 1
            fi
        fi
    fi
    
    # Add new CUSTOM_PATHS array and export statement
    if [ -n "$paths_string" ]; then
        # Only add newline if the file doesn't end with one
        if [ -s "$BASHRC_FILE" ] && [ "$(tail -c 1 "$BASHRC_FILE" 2>/dev/null)" != "" ]; then
            echo "" >> "$BASHRC_FILE"
        fi
        echo "# Custom PATH management - added by path script" >> "$BASHRC_FILE"
        echo "# Store original PATH on first run to prevent duplicates" >> "$BASHRC_FILE"
        echo 'if [ -z "$ORIGINAL_PATH" ]; then' >> "$BASHRC_FILE"
        echo '    export ORIGINAL_PATH="$PATH"' >> "$BASHRC_FILE"
        echo 'fi' >> "$BASHRC_FILE"
        echo "" >> "$BASHRC_FILE"
        
        # Write multiline array format
        echo "$PATH_ARRAY_VAR=(" >> "$BASHRC_FILE"
        
        # Parse each quoted path and write it on a separate line with proper indentation.
        # Trim any accidental leading/trailing whitespace inside the quotes to avoid
        # introducing extra spaces into PATH when joining with ':' later.
        while IFS= read -r path; do
            if [ -n "$path" ]; then
                # Remove surrounding quotes, trim whitespace, then re-quote the value
                clean_path=$(echo "$path" | sed 's/^"//;s/"$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
                echo "    \"$clean_path\"" >> "$BASHRC_FILE"
            fi
        done < <(echo "$paths_string" | grep -o '"[^"]*"')
        
        echo ")" >> "$BASHRC_FILE"
        echo 'CUSTOM_PATHS_STR=$(IFS=":"; echo "${CUSTOM_PATHS[*]}")' >> "$BASHRC_FILE"
        echo 'export PATH="$ORIGINAL_PATH:$CUSTOM_PATHS_STR"' >> "$BASHRC_FILE"
    fi
}

# Function to check if path is already in PATH
is_path_in_current_path() {
    local path="$1"
    local expanded_path=$(expand_tilde "$path")
    
    if [[ ":$PATH:" == *":$expanded_path:"* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if path is already in custom paths
is_path_in_custom_paths() {
    local path="$1"
    local current_paths=$(read_custom_paths)
    
    if [[ "$current_paths" == *"\"$path\""* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to initialize or reset the original PATH
init_original_path() {
    if [ -z "$ORIGINAL_PATH" ]; then
        export ORIGINAL_PATH="$PATH"
        echo "Original PATH stored: $ORIGINAL_PATH"
    else
        echo "Original PATH already stored: $ORIGINAL_PATH"
    fi
}