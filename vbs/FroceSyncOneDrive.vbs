Dim oShell : Set oShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

oShell.Run "taskkill /f /im OneDrive.exe", , True

If (fso.FileExists("C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe")) Then 
oShell.Run """C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"" -p1 -c"
ElseIf (fso.FileExists("C:\Users\Surface\AppData\Local\Microsoft\OneDrive\OneDrive.exe")) Then 
oShell.Run """C:\Users\Surface\AppData\Local\Microsoft\OneDrive\OneDrive.exe"" -p1 -c"
Else 
oShell.Run """C:\Users\mingz\AppData\Local\Microsoft\OneDrive\OneDrive.exe"" -p1 -c"
end if

'How to Use
'in RemotePC:
'using cmd cd&dir to navigate to onedrive first  
'e.g. cd C:\Users\ming.z\OneDrive\Projects
'then mklink TestFolder C:\Users\ming.z\projects\TestFolder /J
'Then turn on Sync
'
'MyHomePC
'Create a folder under P Drive
'then CD to One Drive
'Lastly, run the following command.
'mklink FolderName P:\FolderName /D

' Option Explicit
' Dim objLocalGroup, objDomainUser, objNetwork

' ' Set objNetwork = CreateObject("Wscript.Network")
' ' strComputer = objNetwork.ComputerName

' ' Bind to local group object.
' Set objLocalGroup = GetObject("WinNT://<My-PC>/Remote Desktop Users,group")

' ' Bind to domain user object.
' Set objDomainUser = GetObject("WinNT://<Domain>/ming.z,user")

' ' Check if user already a member of group.
' If (objLocalGroup.IsMember(objDomainUser.ADsPath) = False) Then
    ' ' Add domain user to local group.
    ' objLocalGroup.Add(objDomainUser.ADsPath)
' End If
