## Implementation Sequence

1. Add SQLite3 Dependency Check DONE
   - What: Add sqlite3 to dependency checking in assess.sh
   - Where: assess.sh +20
   ```bash
   check_dependencies "files-to-prompt" "llm" "sqlite3"
   ```

2. Create Global Directory Constants DONE
   - What: Add constants for global directory and database paths
   - Where: llmdev +4
   ```bash
   # Global directory for llmdev data
   LLMDEV_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llmdev"
   LLMDEV_DB="$LLMDEV_DIR/llmdev.db"
   ```

3. Add Directory Creation Logic DONE
   - What: Create global directory if it doesn't exist
   - Where: llmdev +7
   ```bash
   # Create directory if it doesn't exist
   mkdir -p "$LLMDEV_DIR"
   ```

4. Create Database Schema Function DONE
   - What: Add function to define database schema creation SQL
   - Where: New file: lib/db_schema.sh
   ```bash
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
   ```

5. Add Database Initialization DONE
   - What: Initialize database if it doesn't exist
   - Where: llmdev +10
   ```bash
   # Source schema creation function
   . lib/db_schema.sh

   # Initialize database if it doesn't exist
   if [ ! -f "$LLMDEV_DB" ]; then
       sqlite3 "$LLMDEV_DB" "$(create_schema)"
   fi
   ```

6. Add Simple Database Test DONE
   - What: Create test to verify database creation and schema
   - Where: New file: tests/test_db.sh
   ```bash
   #!/usr/bin/env bash
   set -e

   # Source the main script to get constants
   . ./llmdev

   # Test database creation
   test_db_creation() {
       rm -f "$LLMDEV_DB"
       ./llmdev --help
       if [ ! -f "$LLMDEV_DB" ]; then
           echo "Database was not created"
           exit 1
       fi
   }

   # Test schema existence
   test_schema() {
       tables=$(sqlite3 "$LLMDEV_DB" ".tables")
       for table in workflows tasks metrics; do
           if [[ ! $tables =~ $table ]]; then
               echo "Missing table: $table"
               exit 1
           fi
       done
   }

   test_db_creation
   test_schema
   echo "Database tests passed"
   ```

7. Add Database Error Handling DONE
   - What: Add error handling for database operations
   - Where: llmdev +15
   ```bash
   init_database() {
       if ! sqlite3 "$LLMDEV_DB" "$(create_schema)"; then
           echo "Error: Failed to initialize database"
           exit 1
       fi
   }

   if [ ! -f "$LLMDEV_DB" ]; then
       init_database
   fi
   ```
