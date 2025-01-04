# GitHub Workflow Guide

This guide outlines the steps for efficiently handling backlog task list in development process.

## Workflow Overview

### 1. Starting with a New task
- **Action:** Select a new task from the backlog task list.

### 2. Branch Creation
- **Action:** Create a new branch from `main`.
- **Naming Convention:** Use `feature-123-username-branchName` for features and `bugfix-123-username-branchName` for bug fix.
- **Procedure:** Begin the development phase on this branch. (Happy Coding💻)

### 3. Synchronizing with Main
- **Action:** Regularly merge the latest `main` branch updates. 
   - `git fetch`
   - `git merge origin/main`
- **Conflict Resolution:** Address any conflicts that arise to maintain branch compatibility.

### 4. Pull Request(PR) to `test` Branch
- **Scenario 1 - No Conflicts:** Proceed if GitHub indicates no conflicts.
- **Scenario 2 - Conflicts:**
  - GitHub flags conflicts and halts processes.
  - Create a backup branch: `feature-123-username-branchName-prod`.
  - Merge `test` into local feature branch and resolve conflicts.
  - **TODO:** Explore an efficient conflict resolution methods for test environments.

### 5. Automated GitHub Actions (in progress)
Upon successful PR creation, the following actions are triggered:
- PR title verification. GitHub Action workflow stops the action flow if title not match pattern.
![Screenshot](Screenshot1.png)

- Project code build on Windows:
  - Code change analysis.
  - Azure resource (ARM) deployment.
  - Code build.
  - Code deployment.
- Testing and code coverage report build on Linux:
  - Code change analysis.
  - Code compilation.
  - Test execution.
  - Coverage report generation.

- GitHub Action Bot posts comments if previous steps failed:
  - Title validation fail.
  - Build fail.
  - Coverage doesn't meet the threshold.

- Microsoft Teams Notifications:
![Screenshot](Screenshot2.png)

GitHub Action flows:
![Screenshot](Screenshot3.png)

### 6. Build Team Review
- **Action:** Request a review and approval from the other developers.
- **Post-Approval:** Verify the implementation in the `test` environment.

### 7. Stakeholder Review
- **Workflow trigger:** Automate notification via a GitHub Action workflow.

### 8. Addressing stakeholder Feedback
#### If Not Approved:
- **No Conflicts:** Back to step 2 for coding.
- **Conflicts/Two Branches:** Use the branch (`feature-123-username-branchName` or `feature-123-username-branchName-prod`) based on the scale of changes. Cherry-pick & Git Merge is useful.
Back to step 2 for coding.

#### If Approved:
- **No Conflicts:** Merge the feature branch into `main`.
- **Conflicts:** Merge the *-prod branch into `main`.

### Completion
- **Final Step:** Move the completed backlog task list to the "Done" column.