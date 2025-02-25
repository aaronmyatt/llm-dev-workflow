#!/usr/bin/env bash

# This script needs to be made executable with: chmod +x script_name.sh
# The chmod +x command adds execute permissions, allowing the script to be run directly
# Without execute permissions, you'd need to run it with: bash script_name.sh
# You can check if it's executable with: ls -l script_name.sh (look for the x in permissions)

# Exit on error
set -e

ASSESSMENT_REPORT="assessment_report.md"

# Check if assessment report exists
if [[ ! -f "$ASSESSMENT_REPORT" ]]; then
    echo "Error: Assessment report not found: $ASSESSMENT_REPORT"
    echo "Please run assess.sh first to generate the assessment"
    exit 1
fi

# Read and parse the assessment report
echo "Reading assessment data from $ASSESSMENT_REPORT..."

# Extract key information from the assessment report
CHANGE_REQUEST=$(sed -n '/Change Request:/,/Directory:/p' "$ASSESSMENT_REPORT" | grep -v "Change Request:" | grep -v "Directory:" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
DIRECTORY=$(grep "Directory:" "$ASSESSMENT_REPORT" | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
METRICS=$(sed -n '/## Metrics/,/## Snapshot/p' "$ASSESSMENT_REPORT")
SCOPE=$(sed -n '/## Scope/,//p' "$ASSESSMENT_REPORT")

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
TASKS_FILE="improvement_tasks.md"

# Create task list using llm with assessment context
cat "$ASSESSMENT_REPORT" | llm -m son "You are helping plan a sequence of small tasks for a single developer to implement the requested changes.

Review the assessment report and break down the work into a linear sequence of small tasks that:
- Should follow a red,green,refactor sequence, starting with a minimal failing unit test
- Build upon each other logically
- Include specific files/areas to modify
- Should minimally affect the existing code, please rely on techniques like:
    - environment variable flags to toggle new code
    - separate single function modules/files that introduce the change
    - code generation
    - or, as a last resort, duplicate files with the changes introduced

Please limit the output to and format as:

## Implementation Sequence

1. Task name
   - What:  Brief description of the specific change
   - Where: filename \+LINENUMBER
   - \`\`\`
   relevant or improved code from the assessment_report
   \`\`\`

Each task should be concrete and actionable. The sequence should flow naturally from start to finish." > "$TASKS_FILE"

sed -i "" '/[0-9]\./s/$/ TODO/g' $TASKS_FILE

echo "Task sequence saved to: $TASKS_FILE"