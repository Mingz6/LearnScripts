@echo off
taskkill /f /im "Onedrive.exe"
timeout /t 2
if exist "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe" (
    Call "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
) else if exist "C:\Users\mingz\AppData\Local\Microsoft\OneDrive\OneDrive.exe" (
    Call "C:\Users\mingz\AppData\Local\Microsoft\OneDrive\OneDrive.exe"
)
timeout /t 5
exit 0