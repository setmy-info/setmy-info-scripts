[Setup]
AppName=setmy.info scripts
AppVersion=0.102.0
DefaultDirName=C:\pub\setmy.info
DefaultGroupName=setmy.info scripts
UninstallDisplayIcon={app}\bin\smi-location.cmd
Compression=lzma2
SolidCompression=yes
OutputDir=.
OutputBaseFilename=setup-setmy.info
ArchitecturesInstallIn64BitMode=x64os
PrivilegesRequired=admin

[Files]
Source: "target\Release\build\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs
Source: "target\Release\build\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs

[Registry]
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts"; ValueType: string; ValueName: "DisplayName"; ValueData: "setmy.info scripts"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts"; ValueType: string; ValueName: "UninstallString"; ValueData: """{app}\unins000.exe"""; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts"; ValueType: string; ValueName: "InstallLocation"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\setmy.info scripts"; ValueType: string; ValueName: "Publisher"; ValueData: "setmy.info"; Flags: uninsdeletekey
