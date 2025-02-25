# General Code Improvement Workflow Implementation

## Overview
Create a set of bash scripts to facilitate an llm assisted code iteration workflow. These scripts and this workflow is to be used by a single developer so may not require all the communication points and documentation produced when working within team.

Eventually combining them into a unified CLI tool.

## Phase 1: Individual Script Development

### Assessment Script (assess.sh)
- [x] Throw error if files-to-prompt command is not available
- [x] Throw error if llm command is not available
- [x] Accept change request prompt as input
- [x] Accept codebase path as input
- [x] Generate basic codebase metrics and key info (files, lines, etc.)
- [x] Create snapshot of current state
- [x] Output assessment report in markdown

Questions to consider:
* What metrics are most important for your specific codebase?
  * Generally lines and files, but it would be ideal if we can identify key programming structures, like function, module and class names
* Are there any existing tools youre using for code analysis?
  * No, but I think there is value in adding a cross step concept like "research" to capture any of these ideas and spend time between each step reviewing and building a knowledge base
* What format would be most useful for storing the assessment data?
  * Lets use sqlite3 via sqlite-utils for saving all data
* How will this integrate with your current development workflow?
  * For now it will be used alongside the workflow in a bash session
* What would make the assessment output most actionable?
  * Along with the markdown assessment, or part of it, please generate an llm prompt for the next step, "planning", and json format output so we can experiment with what works best in th subsequent steps

### Planning Script (`plan.sh`)
- [x] Read assessment data
- [x] Create/manage improvement task list
- [x] ~~Prioritization helpers ~~
- [x] ~~Generate sprint/iteration boundaries~~
- [x] ~~Output planning document in markdown~~

Questions to consider:
* How do you currently prioritize technical improvements?
  * At the early stages, we mostly go through creative incremental improvements. This works best for my brain. Later on it is combination of dog fooding to find issues, responding to user feedback and imaging new features
* What time frame do you typically work with for iterations?
  * Ideally hours, rather than days, smaller the better.
* Who are the stakeholders that need to see the planning output?
  * Only the one developer being collaborated with.
* How do you measure the success of an improvement cycle?
  * Tests!
* What metadata should be tracked for each task?
  * None yet.

### Iteration Script (`iterate.sh`)
- [x] Create feature branch for change request, if not already
- [x] Load current task from plan
- [x] ~~Track time spent on task~~
- [x] ~~Save conversation context~~
- [x] ~~Mark tasks as complete~~
- [x] Allow dev to mark complete
- [x] Proceed to next task
- [x] ~~Output progress report at the end of tasks or on exit~~

Questions to consider:
* What's your branching strategy?
  * Github Flow
* How do you want to track time spent on improvements?
  * Not necessary
* What information should be captured during the iteration?
  * A checklist of what steps have been completed
* How can we make the iteration process more efficient?
  * Keep it simple. Iterate through the tasks, limiting display to the appropriate assessment and planning information
* What would help maintain momentum during implementation?
  * Keep it simple. Iterate through the tasks, limiting display to the appropriate assessment and planning information

### Adjustment Script (`adjust.sh`)
- [x] Based on git diff and markdown outputs
  - [x] Recommend tests
  - [x] Recommend refactoring and other improvements

### Documentation Script (`document.sh`)
- [x] Based on git diff and markdown outputs
- [x] ~~Generate changelog entries~~
  - [x] Recommend code comments
  - [x] Generate manual usage instructions that exercise the latest changes
- [x] ~~Create progress summary~~
- [x] ~~Archive conversation context~~

Questions to consider:
* Who needs to read this documentation?
* What documentation format works best for your team?
* How can we automate documentation updates?
* What context needs to be preserved long-term?
* How can we make documentation maintenance sustainable?

## Phase 2: Integration

### Unified CLI Tool
- [x] Create main program structure
- [x] Combine individual scripts
- [x] ~~Add configuration system~

Questions to consider:
* What's the ideal command structure for your workflow?
  * llmdev <change-request>
    * start a new workflow/change request
  * Rerun specific workflow steps
    * llmdev assess <change-request>
      * Reproduce assessment report
    * llmdev plan/p
      * Reproduce tasks
    * llmdev iterate/i
      * iterate on current assessment/tasks
    * llmdev adjust/a
      * Reproduce adjustment suggestions
    * llmdev document/d
      * Reproduce documentation suggestions
* What configuration options need to be customizable?
  * files-to-prompt arguments
    * -e extensions
  * llm commands arguments
    * -m model
    * logs
* How should errors be handled and reported?
  * Log to stdout and exit
* What would make this tool enjoyable to use daily?
  * It could remember the last workflow and task
* How can we ensure the tool remains maintainable?
  * Prioritise breaking the code into small, functional, reusable pieces

## Enhancements
- [x] Reviewing git diff anytime
- [x] Committing changes anytime
  - [ ] Generate commit messages
- [x] Editing files with `$EDITOR` (at the +linenum if provided)
- [ ] Capturing notes/learnings/research ideas that arise during each step
- [ ] How can we enable passing any of the sub command arguments?
- [ ] Should we enable overriding the default command usage? Let the user provide a command + arguments override? fzf style
- [ ] Create consistent UI/UX
- [ ] Add logging and error handling
- [ ] Add interactive mode
- [ ] Implement conversation context management
- [ ] Create visualization options
- [ ] Add export capabilities
- [ ] Implement backup/restore
- [ ] Allow tasks to be "skipped"

Questions to consider:
* What visualizations would be most helpful?
* How interactive should the tool be?
* What export formats would be useful?
* How can we make the tool extensible?
* What backup strategy makes sense for your workflow?
