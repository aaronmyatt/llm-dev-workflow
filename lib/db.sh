LLMDEV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
LLMDEV_DB="$LLMDEV_DIR/llmdev.db"

mkdir -p "$LLMDEV_DIR"

create_schema() {
       cat <<EOF
   CREATE TABLE IF NOT EXISTS workflows (
       id INTEGER PRIMARY KEY,
       change_request TEXT,
       created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
       status TEXT DEFAULT 'active'
   );

   CREATE TABLE IF NOT EXISTS assessments (
       id INTEGER PRIMARY KEY,
       workflow_id INTEGER,
       body TEXT,
       created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
       FOREIGN KEY(workflow_id) REFERENCES workflows(id)
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
}

insert_workflow() {
    local change_request="$1"
    sqlite3 "$LLMDEV_DB" "INSERT INTO workflows (change_request) VALUES ('$change_request') RETURNING id;"
}

insert_assessment() {
    local workflow_id="$1"
    local assessment_report="$2"
    db_operation "INSERT INTO assessments (workflow_id, body) VALUES ('$workflow_id', '$assessment_report');"
}

latest_assessment() {
    local workflow_id="$1"
    db_operation "SELECT body FROM assessments ORDER BY created_at DESC LIMIT 1"
}

insert_metrics() {
    local workflow_id=$1
    local total_files=$2
    local total_lines=$3

    sqlite3 "$LLMDEV_DB" "INSERT INTO metrics
        (workflow_id, total_files, total_lines)
        VALUES ($workflow_id, $total_files, $total_lines);"
}

db_operation() {
    if ! sqlite3 "$LLMDEV_DB" "$1"; then
    echo "Database operation failed: $1" >&2
    return 1
    fi
}

get_assessments() {
    local workflow_id=$1
    sqlite3 "$LLMDEV_DB" "SELECT w.change_request, m.*
        FROM metrics m
        JOIN workflows w ON w.id = m.workflow_id
        WHERE workflow_id = $workflow_id;"
}

init_database() {
    if ! sqlite3 "$LLMDEV_DB" "$(create_schema)"; then
        echo "Error: Failed to initialize database"
        exit 1
    fi
}