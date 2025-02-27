#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e


total_files() { 
    echo $(find "$1" -type f | wc -l) 
}
total_lines() { 
    echo $(find "$1" -type f -exec cat {} + | wc -l) 
}

REPORT=''
REPORT_PATH="assessment_report.md"
CHANGE_REQUEST=""
CODEBASE_PATH="."
EXTENSIONS=""
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
WORKFLOW_ID=0
TOTAL_FILES=0
TOTAL_LINES=0

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

echo_metrics() {
    local dir=$1
    local total_files=$2
    local total_lines=$3
    echo 'Analyzing directory: '"$dir"'
Total files: '"$total_files"'
Total lines: '"$total_lines"''
    # If extensions were specified, show filtered metrics
    # if [[ -n "$EXTENSIONS" ]]; then
    #     echo "=== Filtered by extension(s): $EXTENSIONS ==="
    #     local filtered_files=$(find "$dir" -type f -name "$EXTENSIONS" | wc -l)
    #     local filtered_lines=$(find "$dir" -type f -name "$EXTENSIONS" -exec cat {} + | wc -l)
    #     echo "Filtered files: $filtered_files"
    #     echo "Filtered lines: $filtered_lines"
    # fi
}

generate_code_analysis() {
    local dir=$1
    local CHANGE_REQUEST=$2

    # Create the analysis using files-to-prompt and llm
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
        # -wid|--workflow_id)
        #     shift
        #     WORKFLOW_ID="$1"
        #     shift
        #     ;;
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

TOTAL_FILES=$(total_files "$CODEBASE_PATH")
TOTAL_LINES=$(total_lines "$CODEBASE_PATH")

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


WORKFLOW_ID=$(insert_workflow "$CHANGE_REQUEST")

# if [[ -n "$WORKFLOW_ID" ]] && ! workflow_exists "$WORKFLOW_ID"; then
#     echo "Error: Invalid workflow ID provided"
#     exit 1
# fi

# Convert to absolute path
CODEBASE_PATH=$(cd "$CODEBASE_PATH" && pwd)

echo "Starting assessment of codebase at: $CODEBASE_PATH"
echo_metrics "$CODEBASE_PATH" "$TOTAL_FILES" "$TOTAL_LINES"
insert_metrics "$WORKFLOW_ID" "$TOTAL_FILES" "$TOTAL_LINES"

# Create markdown report
REPORT='# Assessment Report

## Overview
- **Date:** '"$timestamp"'
- **Change Request:** 
'"$CHANGE_REQUEST"'
- **Directory:** '"$CODEBASE_PATH"'

## Metrics
'"$(echo_metrics "$CODEBASE_PATH" "$TOTAL_FILES" "$TOTAL_LINES" | sed 's/^/- /')"'

## Scope
'"$(generate_code_analysis "$CODEBASE_PATH" "$CHANGE_REQUEST" | tr "'" '"')"'
'

echo "$REPORT"

insert_assessment "$WORKFLOW_ID" "$REPORT"