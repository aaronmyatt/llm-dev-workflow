# if in a git directory
# if git rev-parse --git-dir > /dev/null 2>&1; then
#     # Convert change request to branch name (lowercase, replace spaces with dashes, remove special chars)
#     BRANCH_NAME="feature/$(echo "$CHANGE_REQUEST" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')"

#     # Check if branch exists
#     if ! git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
#         echo "Creating feature branch: $BRANCH_NAME"
#         git checkout -b "$BRANCH_NAME"
#     else
#         echo "Using existing branch: $BRANCH_NAME"
#         git checkout "$BRANCH_NAME"
#     fi
# fi

#!/usr/bin/env bash

set -e

. ./lib/db.sh

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

check_dependencies "files-to-prompt" "llm" "lazygit" "git" "micro"

# Function to check if there are any remaining tasks
has_remaining_tasks() {
    latest_workflow 'wp.body' | grep -q "TODO"
    return $?
}

# Function to display current task
function display_current_task() {
    local WORKPLAN=$(latest_workflow 'wp.body')

    NEXT_TASK_NUM=$(echo "$WORKPLAN" | grep "^[0-9]\." | grep -v "DONE" | head -n 1 | cut -d'.' -f1)
    if [[ -n "$NEXT_TASK_NUM" ]]; then
        echo "Current task:"
        # Find the start line of the current task
        START_LINE=$(echo "$WORKPLAN" | grep -n "^$NEXT_TASK_NUM\." | cut -d':' -f1)


        # Find the start line of the next task or end of file
        NEXT_START=$((NEXT_TASK_NUM + 1))
        END_LINE=$(echo "$WORKPLAN" | grep -n "^$NEXT_START\.[[:space:]]" | head -n 1 | cut -d':' -f1)

        if [[ -z "$END_LINE" ]]; then
            # If there's no next task, display to the end of file
            echo "$WORKPLAN" | sed -n "${START_LINE},\$" | bat -l markdown --style=plain
        else
            # Display from current task to line before next task
            END_LINE=$((END_LINE - 1))
            echo "$WORKPLAN" | sed -n "${START_LINE},${END_LINE}" | bat -l markdown --style=plain
        fi
        return 0
    else
        return 1
    fi
}

# Save current terminal settings
old_tty_settings=$(stty -g)

# Restore terminal settings on script exit
trap 'stty "$old_tty_settings"' EXIT

# Configure terminal for immediate character reading
stty -echo -icanon min 1

# Main loop
WORKPLAN=$(latest_workflow 'wp.body')
WORKFLOW_ID=$(latest_workflow 'w.id')
while has_remaining_tasks; do
    if ! display_current_task; then
        echo "All tasks completed!"
        exit 0
    fi

    echo "Mark this task complete? (y/N | q: quit, d: diff, c: commit, e: edit, l: til): "
    while true; do
        read -n 1 confirm
        case "$confirm" in
            [Yy])
                echo # New line after keystroke
                NEXT_TASK_NUM=$(mark_next_task_done "$WORKPLAN" "$WORKFLOW_ID")

                echo "Task $NEXT_TASK_NUM marked as complete"
                echo
                break
                ;;
            [Dd])
                git diff
                break
                ;;
            [Cc])
                git diff | llm -m son "Please create a commit message, and an explanatory paragraph for these code changes" | pbcopy
                lazygit
                break
                ;;
            [Ee])
                display_current_task | grep -i 'where' | head -n 1 | cut -d":" -f2 | xargs $EDITOR
                break
                ;;
            [Qq])
                echo # New line after keystroke
                echo "Exiting iteration..."
                exit 0
                ;;
            [Nn])
                echo # New line after keystroke
                echo "Task remains in progress"
                echo "Exiting iteration..."
                exit 0
                ;;
        esac
    done
done

echo "All tasks completed!"