Set oShell = CreateObject ("Wscript.Shell")
Dim strArgs
strArgs = "cmd /c OneDrive.bat"
oShell.Run strArgs, 0, false

'cd
'dir
'navigate to onedrive first then 
'mklink TestFolder C:\Users\ming.Z\projects\TestFolder /J
'Then turn on Sync
'
'
'MyHomePC
'Create a folder under P Drive
'then CD to One Drive
'Lastly, run the following command.
'mklink FolderName D:\FolderName /D