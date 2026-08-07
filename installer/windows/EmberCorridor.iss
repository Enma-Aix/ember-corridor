#define MyAppName "Ember Corridor"
#define MyAppVersion "0.1.0 M1 Preview"
#define MyAppPublisher "Enma-Aix"
#define MyAppExeName "EmberCorridor.exe"

[Setup]
AppId={{5E08DCE9-20B5-4F60-8C7D-66E2469C1E87}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion=0.1.0.0
DefaultDirName={localappdata}\Programs\Ember Corridor
DefaultGroupName=Ember Corridor
DisableProgramGroupPage=yes
OutputDir=..\..\build\release
OutputBaseFilename=EmberCorridor-M1-Preview-Setup-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupLogging=yes

[Files]
Source: "..\..\build\windows\EmberCorridor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\licenses\GODOT-ENGINE-LICENSE.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\docs\ASSET-LICENSE-REGISTER.csv"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Ember Corridor"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Ember Corridor"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Ember Corridor"; Flags: nowait postinstall skipifsilent

