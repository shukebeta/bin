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
    TEST_DIR="/tmp/file_test_$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
}

# Cleanup test environment
cleanup_test() {
    rm -rf "$TEST_DIR"
}

# Test safe_replace_file function
test_safe_replace_file() {
    echo "Testing safe_replace_file function..."
    
    setup_test
    
    # Test successful replacement
    echo "hello world" > test1.txt
    local output
    output=$(safe_replace_file "test1.txt" "hello" "hi" 2>&1) && local exit_code=0 || local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ "$(cat test1.txt)" == "hi world" ]]; then
        echo "✓ PASS: safe_replace_file successfully replaces content"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: safe_replace_file didn't replace content correctly"
        echo "Exit code: $exit_code"
        echo "File content: $(cat test1.txt)"
        echo "Output: $output"
    fi
    TESTS=$((TESTS + 1))
    
    # Test no matches case
    echo "no matches here" > test2.txt
    output=$(safe_replace_file "test2.txt" "hello" "hi" 2>&1) && exit_code=0 || exit_code=$?
    
    if [[ $exit_code -eq 1 ]] && [[ "$(cat test2.txt)" == "no matches here" ]]; then
        echo "✓ PASS: safe_replace_file handles no matches correctly"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: safe_replace_file should return 1 for no matches"
        echo "Exit code: $exit_code"
        echo "File content: $(cat test2.txt)"
        echo "Output: $output"
    fi
    TESTS=$((TESTS + 1))
    
    # Test backup cleanup - no .bak files should remain after successful operation
    echo "test content" > test3.txt
    safe_replace_file "test3.txt" "test" "example" >/dev/null 2>&1
    
    if [[ ! -f "test3.txt.bak" ]]; then
        echo "✓ PASS: safe_replace_file cleans up backup files"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: safe_replace_file left backup file"
    fi
    TESTS=$((TESTS + 1))
    
    cleanup_test
}

# Test count_results function
test_count_results() {
    echo "Testing count_results function..."
    
    # Test mixed results
    local result
    result=$(count_results 0 0 1 2 0 1)
    
    if [[ "$result" == "3 3" ]]; then
        echo "✓ PASS: count_results correctly counts successes and failures"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: count_results didn't count correctly"
        echo "Expected: '3 3', Got: '$result'"
    fi
    TESTS=$((TESTS + 1))
    
    # Test all successes
    result=$(count_results 0 0 0)
    
    if [[ "$result" == "3 0" ]]; then
        echo "✓ PASS: count_results handles all successes"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: count_results didn't handle all successes"
        echo "Expected: '3 0', Got: '$result'"
    fi
    TESTS=$((TESTS + 1))
    
    # Test all failures
    result=$(count_results 1 2 1)
    
    if [[ "$result" == "0 3" ]]; then
        echo "✓ PASS: count_results handles all failures"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: count_results didn't handle all failures"
        echo "Expected: '0 3', Got: '$result'"
    fi
    TESTS=$((TESTS + 1))
    
    # Test empty input
    result=$(count_results)
    
    if [[ "$result" == "0 0" ]]; then
        echo "✓ PASS: count_results handles empty input"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: count_results didn't handle empty input"
        echo "Expected: '0 0', Got: '$result'"
    fi
    TESTS=$((TESTS + 1))
}

# Main test runner
main() {
    echo "========================================"
    echo "  Unit Tests: File Functions"
    echo "========================================"
    echo
    
    test_safe_replace_file
    echo
    test_count_results
    
    echo
    echo "========================================"
    echo "Results: $PASSED/$TESTS tests passed"
    echo "========================================"
    
    if [[ $PASSED -eq $TESTS ]]; then
        echo "All file function tests passed!"
        exit 0
    else
        echo "Some tests failed!"
        exit 1
    fi
}

main "$@"