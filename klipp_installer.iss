[Setup]
AppId={{51A8BC22-E59B-4D11-A54D-996611FFAC99}
AppName=Klipp
AppVersion=1.0.0
AppPublisher=Xander
AppPublisherURL=https://github.com/xanderelsmith/klipp
AppSupportURL=https://github.com/xanderelsmith/klipp
AppUpdatesURL=https://github.com/xanderelsmith/klipp
DefaultDirName={autopf}\Klipp
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=.\
OutputBaseFilename=Klipp_Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\klipp.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Klipp"; Filename: "{app}\klipp.exe"
Name: "{autodesktop}\Klipp"; Filename: "{app}\klipp.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\klipp.exe"; Description: "{cm:LaunchProgram,Klipp}"; Flags: nowait postinstall skipifsilent
