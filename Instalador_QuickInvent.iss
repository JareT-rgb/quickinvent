; Script de instalación para QuickInvent
; Generado para Windows x64

[Setup]
AppId={{D3B3A5A1-9F2B-4A1E-B1A1-8E2B2A2B2A2B}
AppName=QuickInvent
AppVersion=1.0.0
AppPublisher=JareT-rgb
DefaultDirName={autopf}\QuickInvent
DefaultGroupName=QuickInvent
AllowNoIcons=yes
; El archivo del instalador se guardará en tu escritorio
OutputDir=userdocs:..\Desktop
OutputBaseFilename=Instalador_QuickInvent_v1
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; IMPORTANTE: Verifica que esta ruta sea la correcta en tu PC
Source: "c:\Users\DELL\OneDrive\Escritorio\quickinvent\build\windows\x64\runner\Release\quickinvent.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\Users\DELL\OneDrive\Escritorio\quickinvent\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTA: La línea anterior copia el EXE y todas las carpetas (data, flutter_assets, etc.)

[Icons]
Name: "{group}\QuickInvent"; Filename: "{app}\quickinvent.exe"
Name: "{autodesktop}\QuickInvent"; Filename: "{app}\quickinvent.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\quickinvent.exe"; Description: "{cm:LaunchProgram,QuickInvent}"; Flags: nowait postinstall skipifsilent
