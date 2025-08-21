#!/bin/bash

set -euo pipefail

# Load the function library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/gs_functions.sh"

# Test counters
TESTS=0
PASSED=0

# Test assertion
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS=$((TESTS + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual  : '$actual'"
    fi
}

# Setup test environment
setup_test() {
    TEST_DIR="/tmp/rg_test_$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    echo "hello world" > "test1.txt"
    echo "function test() {}" > "test2.js"
    echo "no match here" > "test3.txt"
}

# Cleanup test environment
cleanup_test() {
    rm -rf "$TEST_DIR"
}

# Test rg_search function
test_rg_search() {
    echo "Testing rg_search function..."
    
    setup_test
    
    # Test successful search
    local output
    if output=$(rg_search "hello" "." 2>/dev/null); then
        if echo "$output" | grep -q "test1.txt"; then
            echo "✓ PASS: rg_search finds pattern"
            PASSED=$((PASSED + 1))
        else
            echo "✗ FAIL: rg_search didn't find expected file"
            echo "Output: $output"
        fi
    else
        echo "✗ FAIL: rg_search failed to execute"
    fi
    TESTS=$((TESTS + 1))
    
    # Test no matches - this should fail and we should handle it
    local no_match_exit
    rg_search "nonexistent" "." >/dev/null 2>&1 && no_match_exit=0 || no_match_exit=$?
    
    if [[ $no_match_exit -eq 1 ]]; then
        echo "✓ PASS: rg_search returns exit code 1 for no matches"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: rg_search should return exit code 1 for no matches, got $no_match_exit"
    fi
    TESTS=$((TESTS + 1))
    
    cleanup_test
}

# Test rg_find_files function
test_rg_find_files() {
    echo "Testing rg_find_files function..."
    
    setup_test
    
    # Test finding files
    local files
    if files=$(rg_find_files "hello" "." 2>/dev/null); then
        if echo "$files" | grep -q "test1.txt"; then
            echo "✓ PASS: rg_find_files finds correct file"
            PASSED=$((PASSED + 1))
        else
            echo "✗ FAIL: rg_find_files didn't find expected file"
            echo "Files: $files"
        fi
    else
        echo "✗ FAIL: rg_find_files failed to execute"
    fi
    TESTS=$((TESTS + 1))
    
    cleanup_test
}

# Test handle_rg_exit_code function
test_handle_rg_exit_code() {
    echo "Testing handle_rg_exit_code function..."
    
    # Test success case
    local output
    output=$(handle_rg_exit_code 0 "test" "search" 2>&1) && local exit_success=0 || local exit_success=$?
    
    if [[ $exit_success -eq 0 ]]; then
        echo "✓ PASS: handle_rg_exit_code handles success (0)"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: handle_rg_exit_code should return 0 for success"
    fi
    TESTS=$((TESTS + 1))
    
    # Test no matches case
    output=$(handle_rg_exit_code 1 "test" "search" 2>&1) && local exit_no_match=0 || local exit_no_match=$?
    
    if [[ $exit_no_match -eq 1 ]] && echo "$output" | grep -q "No matches found"; then
        echo "✓ PASS: handle_rg_exit_code handles no matches (1)"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: handle_rg_exit_code should return 1 and show message for no matches"
        echo "Exit: $exit_no_match, Output: $output"
    fi
    TESTS=$((TESTS + 1))
    
    # Test error case
    output=$(handle_rg_exit_code 2 "test" "search" 2>&1) && local exit_error=0 || local exit_error=$?
    
    if [[ $exit_error -eq 2 ]] && echo "$output" | grep -q "Error running ripgrep"; then
        echo "✓ PASS: handle_rg_exit_code handles error (2)"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: handle_rg_exit_code should return 2 and show error for ripgrep error"
        echo "Exit: $exit_error, Output: $output"
    fi
    TESTS=$((TESTS + 1))
}

# Main test runner
main() {
    echo "========================================"
    echo "  Unit Tests: Ripgrep Functions"
    echo "========================================"
    echo
    
    test_rg_search
    echo
    test_rg_find_files
    echo
    test_handle_rg_exit_code
    
    echo
    echo "========================================"
    echo "Results: $PASSED/$TESTS tests passed"
    echo "========================================"
    
    if [[ $PASSED -eq $TESTS ]]; then
        echo "All ripgrep function tests passed!"
        exit 0
    else
        echo "Some tests failed!"
        exit 1
    fi
}

main "$@"