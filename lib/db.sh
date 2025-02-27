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

    CREATE TABLE IF NOT EXISTS workplan (
       id INTEGER PRIMARY KEY,
       workflow_id INTEGER,
       body TEXT,
       status TEXT DEFAULT 'todo',
       created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
       completed_at DATETIME,
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

update_workplan() {
    local column="$1"
    local update="$2"
    local workplan_id="$3"
    db_operation "UPDATE workplan SET $column='$update' where workflow_id=$workplan_id"
}

update_workplan_body() {
    update_workplan 'body' "$1" "$2"
}

sanitize_input() {
    sqlite3 :memory: "SELECT quote('$1');"
}

insert_assessment() {
    local workflow_id="$1"
    local assessment_report="$2"
    db_operation "INSERT INTO assessments (workflow_id, body) VALUES ('$workflow_id', '$assessment_report');"
}

latest_assessment() {
    local column=${1:-'body'}
    latest_record 'assessments' "$column"
}

latest_workplan() {
    local column=${1:-'body'}
    latest_record 'workplan' "$column"
}

latest_record() {
    local table=${1:-'assessments'}
    local column=${2:-'body'}
    db_operation "SELECT $column FROM $table ORDER BY created_at DESC LIMIT 1"
}

latest_workflow(){
    local column=${1:-'body'}
    db_operation "select $column from workflows w left join assessments a on a.workflow_id = w.id left join workplan wp on wp.workflow_id = w.id ORDER BY w.created_at DESC LIMIT 1;"
}

workflow_exists() {
    local id=${1:-0}
    sqlite3 "$LLMDEV_DB" "SELECT EXISTS(SELECT 1 FROM workflows WHERE id=$id);"
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
    sqlite3 "$LLMDEV_DB" "SELECT w.change_request, a.*
        FROM assessments a
        JOIN workflows w ON w.id = a.workflow_id
        WHERE workflow_id = $workflow_id;"
}

init_database() {
    if ! sqlite3 "$LLMDEV_DB" "$(create_schema)"; then
        echo "Error: Failed to initialize database"
        exit 1
    fi
}

insert_workplan(){
    local workflow_id="$1"
    local workplan="$2"
    db_operation "INSERT INTO workplan (workflow_id, body) VALUES ('$workflow_id', '$workplan');"
}

store_tasks_in_db() {
    local workflow_id=$1
    local tasks=$2
    
    echo "$tasks" | while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+\. ]]; then
        description=$(echo "$line" | sed 's/^[0-9]\. \(.*\) TODO$/\1/')
        sqlite3 "$DATABASE" "INSERT INTO tasks (workflow_id, description, status) VALUES ($workflow_id, '$description', 'todo')"
    fi
    done
}

init_database