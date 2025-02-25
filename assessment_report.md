# Assessment Report

## Overview
- **Date:** 2025-02-25 15:46:48
- **Change Request:** 
please create an sqlite3 instance in a globally shared directory when ./llmdev is run for the first time
- **Directory:** /Users/aaronmyatt/Development/llm-workflow

## Metrics
- === Codebase Metrics ===
- Analyzing directory: /Users/aaronmyatt/Development/llm-workflow
- Total files:       65
- Total lines:     2403

## Snapshot Information
- Snapshot manifest: `.code_snapshot_manifest.txt`
- Git status: `.code_snapshot_git.txt`

## Scope
## Code Analysis
Analysis of code sections relevant to: please create an sqlite3 instance in a globally shared directory when ./llmdev is run for the first time
```
Based on the provided code and the request to create an SQLite3 instance in a global directory, here are the relevant sections:

### llmdev
- llmdev +1-36
- Main program structure and command parsing location where database initialization should be added
```bash
#!/usr/bin/env bash

# Exit on error
set -e

function show_help() {
    cat << EOF
Usage: llmdev <change-request>|<command> [options]

Commands:
  <change-request>   Start a new workflow with the specified change request
  assess, a          Reproduce assessment report
  plan, p            Reproduce tasks
  iterate, i         Iterate on current assessment/tasks
  adjust, j          Reproduce adjustment suggestions
  document, d        Reproduce documentation suggestions

Options:
  -h, --help       Show this help message
EOF
}

function start_workflow() {
    # start a new iteration based on the produced assessment+plan 
    # for the current <change-request>

    # Add error handling around script execution
    if ! ./assess.sh "$@"; then
        echo "Error during assessment phase"
        exit 1
    fi
}
```

### assess.sh
- assess.sh +19-31
- Contains dependency checking function that should be modified to include sqlite3
```bash
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
```

To implement the SQLite3 database:

1. Add to llmdev main script, after the `set -e`:
```bash
# Global directory for llmdev data
LLMDEV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
LLMDEV_DB="$LLMDEV_DIR/llmdev.db"

# Create directory if it doesn't exist
mkdir -p "$LLMDEV_DIR"

# Initialize database if it doesn't exist
if [ ! -f "$LLMDEV_DB" ]; then
    sqlite3 "$LLMDEV_DB" <<EOF
CREATE TABLE IF NOT EXISTS workflows (
    id INTEGER PRIMARY KEY,
    change_request TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY,
    workflow_id INTEGER,
    description TEXT,
    status TEXT DEFAULT 'todo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY(workflow_id) REFERENCES workflows(id)
);

CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY,
    workflow_id INTEGER,
    total_files INTEGER,
    total_lines INTEGER,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(workflow_id) REFERENCES workflows(id)
);
EOF
fi
```

2. Add sqlite3 to dependency check in assess.sh:
```bash
check_dependencies "files-to-prompt" "llm" "sqlite3"
```

This will:
- Create a standardized directory for llmdev data
- Initialize SQLite3 database with tables for workflows, tasks, and metrics
- Check for sqlite3 availability
- Use XDG base directory specification for data location
```
