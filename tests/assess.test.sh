#!/usr/bin/env bash

# Exit on error
set -e


test_workflow_id_from_stdin() {
    echo "123" | ./assess.sh "test request" -c ./testdir
    assertEquals "Workflow ID not properly read" "123" "$WORKFLOW_ID"
}

echo "=== Testing assess.sh ==="
echo

echo "Test 1: Show help (no arguments)"
./assess.sh "Update error handling"
echo

echo "Test 2: Show help (explicit -h)"
./assess.sh -h
echo

echo "Test 3: Show help (explicit --help)"
./assess.sh --help
echo

echo "Test 4: Invalid directory"
./assess.sh "Update error handling" -c /path/that/does/not/exist && echo "FAIL: Should have errored" || echo "PASS: Correctly detected invalid directory"
echo

echo "Test 5: Current directory"
./assess.sh "Update error handling" -c .
echo

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
echo "Test 6: Empty directory"
./assess.sh "Update error handling" -c "$TEST_DIR"
echo

echo "Test 7: Missing change request prompt"
./assess.sh -c . && echo "FAIL: Should require change request" || echo "PASS: Correctly required change request"
echo

echo "Test 8: Valid change request with context"
./assess.sh "Update error handling" -c . && echo "PASS: Accepted valid input" || echo "FAIL: Should accept valid input"
echo

echo "Test 9: Test with file extensions"
./assess.sh "Refactor JavaScript files" -c . -e "*.js" && echo "PASS: Accepted extensions" || echo "FAIL: Should accept extensions"
echo

echo "Test 10: Test with multiple paths"
mkdir -p "$TEST_DIR/src" "$TEST_DIR/tests"
./assess.sh "Check multiple directories" -c "$TEST_DIR/src,$TEST_DIR/tests" && echo "PASS: Handled multiple paths" || echo "FAIL: Should handle multiple paths"
echo

echo "Test 11: Test with missing required commands"
# Temporarily modify PATH to simulate missing command
OLD_PATH="$PATH"
PATH=""
./assess.sh "Test command check" -c . && echo "FAIL: Should detect missing commands" || echo "PASS: Correctly detected missing commands"
PATH="$OLD_PATH"
echo

echo "Test 12: Test with empty directory as context"
mkdir -p "$TEST_DIR/empty"
./assess.sh "Test empty context" -c "$TEST_DIR/empty" && echo "PASS: Handled empty directory" || echo "FAIL: Should handle empty directory"
echo

echo "Test 13: Test path normalization"
./assess.sh "Test relative path" -c ./. && echo "PASS: Normalized path" || echo "FAIL: Should normalize path"
echo

echo "Test 14: Test special characters in change request"
./assess.sh "Test * special & chars !" -c . && echo "PASS: Handled special characters" || echo "FAIL: Should handle special characters"
echo

echo "Test 15: Test metrics generation"
TEST_DIR=$(mktemp -d)
echo "test file" > "$TEST_DIR/test.txt"
./assess.sh "Test metrics" -c "$TEST_DIR" | grep "Total files:" && echo "PASS: Generated metrics" || echo "FAIL: Should generate metrics"
rm -rf "$TEST_DIR"

testSnapshotDisabled() {
    export ENABLE_SNAPSHOTS=0
    ./assess.sh .
    assertFileNotExists ".code_snapshot_manifest.txt"
    assertFileNotExists ".code_snapshot_git.txt"
    unset ENABLE_SNAPSHOTS
}

# Clean up
rm -rf "$TEST_DIR"
echo "Cleaned up temporary test directory"
echo

echo "=== Tests Complete ==="