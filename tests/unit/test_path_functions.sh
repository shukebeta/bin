#!/bin/bash

set -euo pipefail

# Load the function library
source "$(dirname "$0")/../../lib/gs_functions.sh"

# Test counters
TESTS=0
PASSED=0

# Test assertion
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        ((PASSED++))
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual  : '$actual'"
    fi
}

# Test path normalization
test_normalize_path() {
    echo "Testing normalize_path function..."
    
    # Test backslash to forward slash conversion
    local result
    result=$(normalize_path "src\\file.txt")
    assert_equal "src/file.txt" "$result" "Convert backslashes to forward slashes"
    
    # Test already normalized path
    result=$(normalize_path "src/file.txt")
    assert_equal "src/file.txt" "$result" "Keep forward slashes unchanged"
    
    # Test mixed separators
    result=$(normalize_path "src\\sub/file.txt")
    assert_equal "src/sub/file.txt" "$result" "Convert mixed separators"
    
    # Test Windows absolute path
    result=$(normalize_path "C:\\Users\\Name\\file.txt")
    assert_equal "C:/Users/Name/file.txt" "$result" "Convert Windows absolute path"
    
    # Test empty path
    result=$(normalize_path "")
    assert_equal "" "$result" "Handle empty path"
    
    # Test single file
    result=$(normalize_path "file.txt")
    assert_equal "file.txt" "$result" "Handle single filename"
}

# Main test runner
main() {
    echo "========================================"
    echo "  Unit Tests: Path Functions"
    echo "========================================"
    echo
    
    test_normalize_path
    
    echo
    echo "========================================"
    echo "Results: $PASSED/$TESTS tests passed"
    echo "========================================"
    
    if [[ $PASSED -eq $TESTS ]]; then
        echo "All path function tests passed!"
        exit 0
    else
        echo "Some tests failed!"
        exit 1
    fi
}

main "$@"