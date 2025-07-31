## Your Tasks:

### 1. **Read and Analyze Documents**

- Read the PRD document from `[PRODUCT_REQS_VAULT_DIR]/documents/PRD.md`
- Read the Architecture document from `[PRODUCT_REQS_VAULT_DIR]/documents/ARCHITECTURE.md`
- Read the User Stories document from `[PRODUCT_REQS_VAULT_DIR]/documents/USER-STORIES.md`
- Extract and understand the specific requirements for story {{STORY_NUMBER}}

### 2. **Analyse Story**

   Read and understand and only implement {{STORY_NUMBER}}

### 3. **Create Feature Branch**

- Create a new git branch following the naming convention: `feature/{{STORY_NUMBER}}-<brief-description>`
- The brief description should be kebab-case and summarize the story's main functionality
- Example: `feature/F1S3-password-reset-flow`

### 4. **Implementation**

Use strict test-driven development.
Write the failing test first, then write code to make it pass.
Do not write any implementation code until I've reviewed the test.

Follow the Red-Green-Refactor cycle strictly:
1. RED: Write a failing test
2. GREEN: Minimal code to pass
3. REFACTOR: Improve while keeping tests green

Start with step 1 only

Write failing tests for the story. Show me:

1. The test code
2. Why it will fail
3. What error message we'd expect

Test-First Reasoning:
Before writing any implementation, walk me through:

- What behavior should this test verify?
- What would make this test pass?
- What assumptions am I making?

ONLY DO THE RED STAGE.
MAKE SURE THE TESTS RUN CLEANLY AND FAIL FOR THE CORRECT REASONS.
DO NOT CONTINUE TO THE GREEN STAGE.

