   #!/bin/bash
   source ../llmdev
   
   test_workflow_sequence() {
     # Test that scripts execute in correct order
     local output=$(start_workflow "test")
     assert_contains "$output" "assessment phase"
     assert_contains "$output" "planning phase" 
     assert_contains "$output" "iteration phase"
   }