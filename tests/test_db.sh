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

test_db_creation
test_schema
echo "Database tests passed"
