## Implementation Sequence

1. Add Database Insert Test DONE
   - What: Create unit test for inserting change request into workflows table
   - Where: tests/test_db.sh
   - ```bash
   test_insert_workflow() {
     local change_request="test request"
     local result=$(insert_workflow "$change_request")
     assert_not_null "$result" "Should return workflow id"
   }
   ```

2. Create Database Insert Function DONE
   - What: Add function to insert change request and return id
   - Where: lib/db.sh +NEW
   - ```bash
   insert_workflow() {
     local change_request="$1"
     sqlite3 "$DB_PATH" "INSERT INTO workflows (change_request) VALUES ('$change_request') RETURNING id;"
   }
   ```

3. Add Save Flag Environment Variable DONE
   - What: Add env var to toggle saving behavior without breaking existing code
   - Where: assess.sh +20
   - ```bash 
   SAVE_CHANGE_REQUESTS=${SAVE_CHANGE_REQUESTS:-true}
   ```

4. Integrate DB Save Into Assessment Flow DONE
   - What: Call insert_workflow when flag enabled
   - Where: assess.sh +110
   - ```bash
   if [[ "$SAVE_CHANGE_REQUESTS" == "true" ]]; then
     WORKFLOW_ID=$(insert_workflow "$CHANGE_REQUEST")
     echo "Created workflow #$WORKFLOW_ID"
   fi
   ```

5. Add Database Migration Test DONE
   - What: Ensure workflows table exists on startup
   - Where: tests/test_db.sh
   - ```bash
   test_workflows_table_exists() {
     local result=$(sqlite3 "$TEST_DB" ".tables workflows")
     assert_equals "workflows" "$result" "Workflows table should exist"
   }
   ```

6. Refactor DB Initialization DONE
   - What: Move schema creation to separate function
   - Where: lib/db.sh
   - ```bash
   init_db() {
     sqlite3 "$DB_PATH" < lib/dbschema.sh
   }
   ```

7. Add Workflow ID to Assessment Report DONE
   - What: Include workflow ID in report header when available
   - Where: templates/assessment.md
   - ```markdown
   ## Overview
   - **Date:** {{date}}
   - **Workflow ID:** {{workflow_id}}
   - **Change Request:** {{change_request}}
   ```
