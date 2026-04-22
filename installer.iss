[Setup]
AppName=VRS Transport Manager
AppVersion=1.6.0
AppPublisher=VRS Enterprises
AppPublisherURL=https://vrs-enterprises.com
AppContact=Asfar
AppCopyright=Developed by Asfar
DefaultDirName={autopf}\VRS Transport Manager
DefaultGroupName=VRS Transport Manager
OutputDir=installer_output
OutputBaseFilename=VRS_Transport_Manager_Setup_1.6.0
Compression=lzma2
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\vrs_transport_manager.exe
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\VRS Transport Manager"; Filename: "{app}\vrs_transport_manager.exe"
Name: "{group}\Uninstall VRS Transport Manager"; Filename: "{uninstallexe}"
Name: "{autodesktop}\VRS Transport Manager"; Filename: "{app}\vrs_transport_manager.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\vrs_transport_manager.exe"; Description: "Launch VRS Transport Manager"; Flags: nowait postinstall skipifsilent
