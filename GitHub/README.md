# LearnGit

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
git remote prune origin\
git reset -hard origin/main\
