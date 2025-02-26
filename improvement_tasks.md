## Implementation Sequence

1. Add assessment database test helper TODO
   - What: Create test helper to setup/teardown test database and check assessment records
   - Where: test/db_test.sh +0
   - ```bash
   #!/usr/bin/env bash
   setup() {
     export LLMDEV_DB=":memory:"
     . lib/db.sh
     init_database
   }
   
   test_store_assessment() {
     store_assessment 1 "test body"
     result=$(latest_assessment 1)
     assert_equals "test body" "$result"
   }
   ```

2. Implement store_assessment function TODO
   - What: Add function to store assessment report in database
   - Where: lib/db.sh +25 
   - ```bash
   store_assessment() {
     local workflow_id="$1"
     local body="$2"
     db_operation "INSERT INTO assessments (workflow_id, body) VALUES ($workflow_id, '$body')"
   }
   ```

3. Add DB_STORAGE environment flag TODO
   - What: Add flag to toggle between file and DB storage
   - Where: lib/config.sh +0
   - ```bash 
   # Default to file storage
   export DB_STORAGE="${DB_STORAGE:-0}"
   ```

4. Update assess.sh to optionally store in DB TODO
   - What: Store assessment in DB when flag enabled while maintaining file output
   - Where: assess.sh +45
   - ```bash
   if [[ "$DB_STORAGE" == "1" ]]; then
     store_assessment "$WORKFLOW_ID" "$assessment"
   fi
   echo "$assessment" > "$ASSESSMENT_REPORT"
   ```

5. Add read_assessment database function TODO
   - What: Create function to read assessment from DB
   - Where: lib/db.sh +32
   - ```bash
   read_assessment() {
     local workflow_id="$1"
     latest_assessment "$workflow_id"
   }
   ```

6. Update plan.sh to read from DB TODO
   - What: Use DB storage when flag enabled
   - Where: plan.sh +13
   - ```bash
   if [[ "$DB_STORAGE" == "1" ]]; then
     assessment=$(read_assessment "$WORKFLOW_ID")
   else
     assessment=$(cat "$ASSESSMENT_REPORT")
   fi
   ```

7. Update iterate.sh to read from DB TODO
   - What: Use DB storage when flag enabled
   - Where: iterate.sh +12
   - ```bash
   if [[ "$DB_STORAGE" == "1" ]]; then
     assessment=$(read_assessment "$WORKFLOW_ID")
     if [[ -z "$assessment" ]]; then
       echo "Error: No assessment found for workflow $WORKFLOW_ID"
       exit 1
     fi
   else
     # Existing file check code
   fi
   ```

8. Update documentation TODO
   - What: Document DB storage option and migration steps
   - Where: README.md +50
   - ```markdown
   ## Database Storage
   Set DB_STORAGE=1 to store assessments in SQLite database instead of files.
   This is the recommended approach for new installations.
   ```
