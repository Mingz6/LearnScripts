@ECHO OFF
net localgroup "Remote Desktop Users" <Domain>\ming.z /add
net localgroup "Remote Desktop Users" <Domain>\ming.z.<admin> /add