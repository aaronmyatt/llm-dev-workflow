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