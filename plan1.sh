#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e

. ./lib/db.sh

CHANGE_REQUEST=""
CODEBASE_PATH="."
EXTENSIONS=""

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

# Generate sequential task list based on the assessment
echo "=== Generating Task List ==="

# Create task list using llm with assessment context
WORKPLAN=$(files-to-prompt -n -e "$EXTENSIONS" "$CODEBASE_PATH" |
llm -m son 'You are helping a software developer plan their work. 
Please read the code and propose a sequence of small tasks for a software developer to implement the following change request: '"$CHANGE_REQUEST"'.

Review the code provided and break down the work into a small set of tasks that:
- Make the smallest possible change in each task
- Build upon each other logically
- Focus on small, composite, functional changes
- Aim to build out a library of reusable, composable functions

Please include specific files/areas to modify, limit the output to and format as:

## Implementation Sequence

1. Task name
   - What:  Brief description of the specific change
   - Where: filename \+LINENUMBER
   - ```
   relevant or improved code from the assessment_report
   ```' | 
sed '/[0-9]\./s/$/ TODO/g' | 
tr "'" '"')

insert_workplan "$WORKFLOW_ID" "$WORKPLAN"