@echo off

set LocalDir=c:\Temp
set SharedDir=\\<Domain>\apps\<Folder>\DEV\
set LookForFile="C:\_LOCALdata\<Folder>\<Application.exe>"

echo "Started Downloading <Application.exe>"
start \\<Domain>\apps\UAT\<Application.exe>
TIMEOUT /T 10 >nul

:CheckForFile
IF EXIST %LookForFile% GOTO FoundIt
TIMEOUT /T 5 >nul
echo "Check File"
GOTO CheckForFile

:FoundIt
echo "File Found"
ren C:\<_LOCALdata>\<Folder>\<Application.exe>
echo "File Rename Success"

pause