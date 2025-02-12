# LearnGit

This document provides useful Git commands and workflows for managing branches, renaming folders, and merging branches.

## Replace Dev with Latest Prod

To replace the `dev` branch with the latest `main` branch:

```sh
git branch -d dev; git checkout main; git reset --hard origin/main; git checkout -b dev main; git push -f -u origin dev;
···

To rename folder to capitalize
1. git config core.ignorecase false
2. git mv <project>.FuncApps tmp
3. git mv tmp <Project>.FuncApps
  
To merge prod to test:\
git fetch origin\
git checkout origin/main\
git checkout -b bugfix/mainToTest\
git merge origin/test

git cherry-pick <SHA>^..<SHA>\
git rebase origin/master\
git diff main\
git reset head~1\
git reset origin/bugfix/ming-000-<Description>\
git gc --prune=now\
### Prune remote branches
git remote prune origin\
### Hard reset to the main branch:
git reset -hard origin/main\

## Create an Orphan Branch
### To create a new orphan branch:
```sh
git switch --orphan <new branch>
git commit --allow-empty -m "Initial commit on orphan branch"
git push -u origin <new branch>
```