#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e

. ./lib/db.sh

ASSESSMENT_REPORT=$(latest_assessment)
WORKFLOW_ID=$(latest_workflow 'w.id')
CHANGE_REQUEST=$(latest_workflow 'w.change_request')

# Check if assessment report exists
if [[ -z "$ASSESSMENT_REPORT" ]]; then
    echo "Error: Assessment report not found: $ASSESSMENT_REPORT"
    echo "Please run assess.sh first to generate the assessment"
    exit 1
fi

# Read and parse the assessment report
echo "Reading assessment data from db..."

WORKPLAN=""
# Extract key information from the assessment report
CHANGE_REQUEST=$(echo "$ASSESSMENT_REPORT" | sed -n '/Change Request:/,/Directory:/p'| grep -v "Change Request:" | grep -v "Directory:" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
DIRECTORY=$(echo "$ASSESSMENT_REPORT" | grep "Directory:" | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
METRICS=$(echo "$ASSESSMENT_REPORT" | sed -n '/## Metrics/,/## Snapshot/p')
SCOPE=$(echo "$ASSESSMENT_REPORT" | sed -n '/## Scope/,//p')

# Display extracted information
echo "=== Assessment Summary ==="
echo "Change Request: $CHANGE_REQUEST"
echo "Directory: $DIRECTORY"
echo
echo "=== Metrics ==="
echo "$METRICS"
echo
echo "=== Scope ==="
echo "$SCOPE"

# Generate sequential task list based on the assessment
echo "=== Generating Task List ==="

# Create task list using llm with assessment context
WORKPLAN=$(llm -m son 'You are helping a software developer plan their work. Please read the assessment report below wrapped in: ===

===
'"$ASSESSMENT_REPORT"'
===

Please propose a sequence of small tasks for a software developer to implement the following change request: '"$CHANGE_REQUEST"'.

Review the assessment report provided and break down the work into a small set of tasks that:
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

echo "Task sequence saved to: $TASKS_FILE"

insert_workplan "$WORKFLOW_ID" "$WORKPLAN"