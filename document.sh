#!/usr/bin/env bash

# Exit on error
set -e

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

check_dependencies "llm" "files-to-prompt"

# Check for assessment report
if [[ ! -f "assessment_report.md" ]]; then
    echo "Error: assessment_report.md not found"
    echo "Please run assess.sh first"
    exit 1
fi

# Check for tasks
if [[ ! -f "improvement_tasks.md" ]]; then
    echo "Error: improvement_tasks.md not found"
    echo "Please run plan.sh first"
    exit 1
fi

# Generate recommendations use previous step outputs
echo "Generating adjustment recommendations..."
{ 
    cat assessment_report.md
    cat improvement_tasks.md
    git diff --no-color
} | cat | llm -m son "Based on the provided context, please:

1. Suggest code comments
2. Provide manual usage instructions/commands that showcase the latest changes

Focus on generating output that:
- Improves understandability of the code
- Enables the developer to test and get feedback quickly
- Documents current functionality with usage examples

Please limit the output to an explanatory note with the suggested code changes."