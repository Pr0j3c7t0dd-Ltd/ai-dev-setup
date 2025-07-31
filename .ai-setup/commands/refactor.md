## Your Tasks:

### 1. **Read and Analyze Documents**

- Read the PRD document from `[PRODUCT_REQS_VAULT_DIR]documents/PRD.md`
- Read the Architecture document from `[PRODUCT_REQS_VAULT_DIR]/documents/ARCHITECTURE.md`
- Read the User Stories document from `[PRODUCT_REQS_VAULT_DIR]/documents/USER-STORIES.md`
- Extract and understand the specific requirements for story {{STORY_NUMBER}}

### 2. **Digest all rules**
- You are reviewing all aspects of the codebase so all LLM rules apply
- Read and understand all rules in the directory `[PRODUCT_REQS_VAULT_DIR]/rules`

### 3. **Evaluate Changes**

- Diff the current branch from main
- Evaluate the differences that have been introduced
- Understand how these changes apply to story {{STORY_NUMBER}}


### 4. **Review the changes**
Review both the functional code and the tests in the files related to this story.
Here are some examples of refactor topics, but be expansive:

- Are all the rule files being followed correctly?
- Is the code properly modularized with clear separation of concerns?
- Are there any magic numbers or hardcoded values that should be constants?
- Are sensitive data and credentials properly protected?
- Are there clear deployment and setup instructions?
- Is there any duplication or redundancy of the code?
- Is there any duplication or redundancy of tests?
- Can some tests be removed because they are superseded by new functionality?
- Is it optimized for human readability?
- Could the test setup code be more reusable?
- Are cryptographic methods suitably secure?
- Has this solution gone out of scope for the boundaries of this story?
- Does it follow SOLID principles?

### 4. **Suggest refactor**

- Do not make any changes to the codebase
- Propose suggestions to be refactored
- Pause to get my confirmation
