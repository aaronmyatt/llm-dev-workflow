#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e

REPORT_FILE="assessment_report.md"
CHANGE_REQUEST=""
CODEBASE_PATH="."
EXTENSIONS=""
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
SAVE_CHANGE_REQUESTS=${SAVE_CHANGE_REQUESTS:-true}

. lib/db.sh

check_dependencies() {
    local missing=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: '$cmd' command is not available"
            echo "Please install it before running this script"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        exit 1
    fi
}

check_dependencies "files-to-prompt" "llm" "sqlite3"

# Help function
show_help() {
    echo "Usage: assess.sh [OPTIONS] <change-request-prompt> -c <context dir> -e <file-extensions>"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo
    echo "Arguments:"
    echo "  change-request    Specify the change request prompt"
    echo "  -c, --context     Path to the codebase to assess"
    echo "  -e, --extensions  file extensions to limit the context to (see files-to-prompt for more details)"
    echo
}

generate_metrics() {
    local dir=$1
    echo "=== Codebase Metrics ==="
    echo "Analyzing directory: $dir"

    # Total number of files
    local total_files=$(find "$dir" -type f | wc -l)
    echo "Total files: $total_files"

    # Total lines of code
    local total_lines=$(find "$dir" -type f -exec cat {} + | wc -l)
    echo "Total lines: $total_lines"

    # If extensions were specified, show filtered metrics
    if [[ -n "$EXTENSIONS" ]]; then
        echo "=== Filtered by extension(s): $EXTENSIONS ==="
        local filtered_files=$(find "$dir" -type f -name "$EXTENSIONS" | wc -l)
        local filtered_lines=$(find "$dir" -type f -name "$EXTENSIONS" -exec cat {} + | wc -l)
        echo "Filtered files: $filtered_files"
        echo "Filtered lines: $filtered_lines"
    fi
}

create_snapshot() {
    local dir=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_dir=".code_snapshot"

    echo "=== Creating Codebase Snapshot ==="
    echo "=== Manifest ===" > "${snapshot_dir}_manifest.txt"

    # Create git status if in a git repo
    if [ -d "$dir/.git" ]; then
        echo "Git Status:" >> "${snapshot_dir}_git.txt"
        (cd "$dir" && git status >> "${snapshot_dir}_git.txt" 2>&1)
        (cd "$dir" && git rev-parse HEAD >> "${snapshot_dir}_git.txt" 2>&1)
    fi

    # Create list of files with hashes
    echo "=== Files ===" >> "${snapshot_dir}_manifest.txt"
    find "$dir" -type f -exec md5 {} \; >> "${snapshot_dir}_manifest.txt" 2>/dev/null || true

    echo "Snapshot created at: ${timestamp}"
}

generate_code_analysis() {
    local dir=$1
    local CHANGE_REQUEST=$2
    local REPORT_FILE=$3

    # Create the analysis using files-to-prompt and llm
    echo "## Code Analysis"
    echo "Analysis of code sections relevant to: $CHANGE_REQUEST"
    echo '```'
    files-to-prompt "$dir" | llm -m son 'Please analyze the provided code and list important sections relevant to the user provided request wrapped in ---:
    ---
    '"$CHANGE_REQUEST"'
    ---
    
    Please limit the output to and format as:

    ### filename
    - filename \+LINENUMBER
    - Why this section matters
    ```
    relevant code snippet
    ```

    Focus on code that handles argument parsing, error checking, metrics generation and status reporting. Provide the tightest relevant line ranges possible.'
    echo '```'
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--extensions)
            shift
            EXTENSIONS="$1"
            shift
            ;;
        -c|--context)
            shift
            CODEBASE_PATH="$1"
            shift
            ;;
        *)
            CHANGE_REQUEST="$1"
            shift
            ;;
    esac
done

# Validate codebase path
if [[ ! -d "$CODEBASE_PATH" ]]; then
    echo "Error: '$CODEBASE_PATH' is not a valid directory"
    exit 1
fi

# Add validation for required arguments
if [[ -z "$CHANGE_REQUEST" ]]; then
    echo "Error: Change request is required"
    show_help
    exit 1
fi

# Show the change request if provided
if [[ -n "$CHANGE_REQUEST" ]]; then
    echo "Change request: $CHANGE_REQUEST"
fi

if [[ "$SAVE_CHANGE_REQUESTS" == "true" ]]; then
    WORKFLOW_ID=$(insert_workflow "$CHANGE_REQUEST")
    echo "Created workflow #$WORKFLOW_ID"
fi

# Convert to absolute path
CODEBASE_PATH=$(cd "$CODEBASE_PATH" && pwd)

echo "Starting assessment of codebase at: $CODEBASE_PATH"
generate_metrics "$CODEBASE_PATH"
create_snapshot "$CODEBASE_PATH"

# Create markdown report
    cat << EOF > "$REPORT_FILE"
# Assessment Report

## Overview
- **Date:** $timestamp
- **Change Request:** 
$CHANGE_REQUEST
- **Directory:** $CODEBASE_PATH

## Metrics
$(generate_metrics "$CODEBASE_PATH" | sed 's/^/- /')

## Snapshot Information
- Snapshot manifest: \`.code_snapshot_manifest.txt\`
$([ -f ".code_snapshot_git.txt" ] && echo "- Git status: \`.code_snapshot_git.txt\`")

## Scope
$(generate_code_analysis "$CODEBASE_PATH" "$CHANGE_REQUEST" "$REPORT_FILE")
EOF

echo "Assessment report generated: assessment_report.md"