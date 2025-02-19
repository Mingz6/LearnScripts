# LearnGit

This document provides useful Git commands and workflows for managing branches, renaming folders, and merging branches.

## Replace Dev with Latest Prod

To replace the `dev` branch with the latest `main` branch:

```sh
git checkout main; git fetch origin; git reset --hard origin/main; git pull; git branch -d dev;
git switch --orphan dev; git commit --allow-empty -m "Initial commit on orphan branch";
git push -f -u origin dev; git checkout main; git branch -d dev;
git checkout -b dev main; git push -f -u origin dev;
```

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

```zsh
{
  old_name="<feature/ming#0000-npupgrade20-prod>"
  new_name="<feature/ming#0000-nxupgrade21-prod>"
  remote="origin"

  # Rename the local branch
  git branch -m "$old_name" "$new_name" &&

  # Delete the old branch on remote
  git push "$remote" --delete "$old_name" &&

  # Prevent git from using the old name when pushing
  git branch --unset-upstream "$new_name" &&

  # Push the new branch to remote
  git push "$remote" "$new_name" &&

  # Reset the upstream branch for the new local branch
  git push "$remote" -u "$new_name"
}
```