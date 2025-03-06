#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e

. ./lib/db.sh

PROMPT=""
CODEBASE_PATH="."
EXTENSIONS=""
CONTINUE=0

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
        -d|--dir)
            shift
            CODEBASE_PATH="$1"
            shift
            ;;
        -c|--continue)
            shift
            CONTINUE=1
            shift
            ;;
        *)
            PROMPT="$1"
            shift
            ;;
    esac
done

# Show the change request if provided
if [[ -n "$PROMPT" ]]; then
    echo "Change request: $PROMPT"
fi


WORKFLOW_ID=$(insert_workflow "$PROMPT")

# if [[ -n "$WORKFLOW_ID" ]] && ! workflow_exists "$WORKFLOW_ID"; then
#     echo "Error: Invalid workflow ID provided"
#     exit 1
# fi

# Convert to absolute path
CODEBASE_PATH=$(cd "$CODEBASE_PATH" && pwd)

# Generate sequential task list based on the assessment
echo "=== Generating Task List ==="

CODE_FOR_PROMPT=$(files-to-prompt -n -e "$EXTENSIONS" "$CODEBASE_PATH")
FULL_PROMPT='Act as an expert architect engineer and provide direction to your editor engineer.
Study the change request and the current code.
Describe how to modify the code to complete the request.
The editor engineer will rely solely on your instructions, so make them unambiguous and complete.
Explain all needed code changes clearly and completely, but concisely.
Just show the changes needed.

DO NOT show the entire updated function/file/etc!

CHANGE REQUEST: '"$PROMPT"'

CURRENT CODE:
'"$CODE_FOR_PROMPT"''

if [[ $CONTINUE -eq 1 ]]; then 

fi

# Create task list using llm with assessment context
WORKPLAN=$(llm -m son  |
tr "'" '"')
# Always reply to the user in {language}

insert_workplan "$WORKFLOW_ID" "$WORKPLAN"