Unicode True
Name "setmy.info scripts"
OutFile "setup-setmy.info.exe"
InstallDir "C:\pub\setmy.info"
RequestExecutionLevel admin

Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "Main"
    SetOutPath "$INSTDIR\bin"
    File /r "src\main\cmd\bin\*"
    SetOutPath "$INSTDIR\lib"
    File /r "src\main\cmd\lib\*"
    File /r "src\main\python\lib\*"
    File /r "src\main\groovy\lib\*"
    
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Optional: Add registry keys for Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts" "DisplayName" "setmy.info scripts"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts" "Publisher" "setmy.info"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\uninstall.exe"
    RMDir /r "$INSTDIR\bin"
    RMDir /r "$INSTDIR\lib"
    RMDir "$INSTDIR"
    
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts"
SectionEnd
