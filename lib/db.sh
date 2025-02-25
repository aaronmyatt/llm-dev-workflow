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

init_database() {
    if ! sqlite3 "$LLMDEV_DB" "$(create_schema)"; then
        echo "Error: Failed to initialize database"
        exit 1
    fi
}