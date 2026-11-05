#ifndef AppVersion
  #define AppVersion "1.3.2"
#endif
[Setup]
AppId={{7254F69A-5B0A-4CA9-981C-ECE7600C38AB}
AppName=Avisos y Promedios
AppVersion={#AppVersion}
AppPublisher=A&P
DefaultDirName={localappdata}\Programs\Avisos y Promedios
DefaultGroupName=Avisos y Promedios
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\..\build\instalador_windows
OutputBaseFilename=AP-Windows-Setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\AvisosYPromedios.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.lib,*.exp,*.pdb"; Flags: ignoreversion recursesubdirs createallsubdirs
[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; Flags: unchecked
[Icons]
Name: "{group}\Avisos y Promedios"; Filename: "{app}\AvisosYPromedios.exe"
Name: "{autodesktop}\Avisos y Promedios"; Filename: "{app}\AvisosYPromedios.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\AvisosYPromedios.exe"; Description: "Abrir Avisos y Promedios"; Flags: nowait postinstall skipifsilent
; Los datos en LocalAppData\Avisos y Promedios\datos no se eliminan al desinstalar.
