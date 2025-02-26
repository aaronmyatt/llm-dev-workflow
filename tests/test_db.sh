#!/usr/bin/env bash
set -e

# Source the main script to get constants
. ./llmdev

# Test database creation
test_db_creation() {
    rm -f "$LLMDEV_DB"
    ./llmdev --help
    if [ ! -f "$LLMDEV_DB" ]; then
        echo "Database was not created"
        exit 1
    fi
}

# Test schema existence
test_schema() {
    tables=$(sqlite3 "$LLMDEV_DB" ".tables")
    for table in workflows tasks metrics; do
        if [[ ! $tables =~ $table ]]; then
            echo "Missing table: $table"
            exit 1
        fi
    done
}

test_insert_workflow() {
    local change_request="test request"
    local result=$(insert_workflow "$change_request")
    assert_not_null "$result" "Should return workflow id"
}

test_workflows_table_exists() {
    local result=$(sqlite3 "$TEST_DB" ".tables workflows")
    assert_equals "workflows" "$result" "Workflows table should exist"
}

test_db_setup() {
    rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
    assert_dir_not_exists "${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
    ./llmdev --help
    assert_dir_exists "${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
}

test_insert_metrics() {
    workflow_id=1
    total_files=118
    total_lines=2751
    insert_metrics "$workflow_id" "$total_files" "$total_lines"
    result=$(sqlite3 "$TEST_DB" "SELECT * FROM metrics WHERE workflow_id=$workflow_id;")
    assert_not_empty "$result"
}

test_create_workflow() {
    change_request="write assessment report to database"
    workflow_id=$(create_workflow "$change_request")
    result=$(sqlite3 "$TEST_DB" "SELECT change_request FROM workflows WHERE id=$workflow_id;")
    assert_equals "$change_request" "$result"
}

test_read_assessment() {
    # Setup test db
    workflow_id=$(create_test_workflow)
    test_assessment="Test assessment content"
    db_operation "INSERT INTO assessments (workflow_id, body) VALUES ($workflow_id, '$test_assessment')"

    # Test reading
    result=$(latest_assessment $workflow_id)
    assert_equals "$test_assessment" "$result"
}

test_db_creation
test_schema
echo "Database tests passed"
