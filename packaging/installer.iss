; AgeniusNote Lite installer (Inno Setup)
;
; Compile:
;     iscc packaging/installer.iss
;
; Expects PyInstaller output at: dist/AgeniusNoteLite/
; Reads version from: packaging/VERSION (override via /DAppVersion=x.y.z)

#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

#ifndef SrcDir
  #define SrcDir "..\dist-build\AgeniusNoteLite"
#endif

#ifndef OutDir
  #define OutDir "..\dist-build\installer"
#endif

#define AppName       "AgeniusNote Lite"
#define AppPublisher  "Agenius AI Labs"
#define AppURL        "https://ageniusailabs.com"
#define AppExeName    "AgeniusNoteLite.exe"

[Setup]
; AppId is an opaque string used by Inno Setup to identify this product for
; upgrade-in-place. Do NOT change it — existing v1.0.x installs key off this
; exact value, and changing it would leave users with two parallel installs
; in Add/Remove Programs. (The literal value isn't a hex-valid GUID; Inno
; treats it as a string and doesn't care.)
AppId={{B9F1A2E0-7B5C-4F4F-9E2D-AGENIUSNOTELITE}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
AppCopyright=Copyright (C) Agenius AI Labs. MIT licensed.
DefaultDirName={autopf}\AgeniusNote Lite
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutDir}
OutputBaseFilename=AgeniusNoteLite-Setup-{#AppVersion}
SetupIconFile=..\assets\icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline

; Prevent two installer instances from running concurrently on the same
; machine — without this, double-clicking the .exe twice can race and
; leave a broken partial install.
SetupMutex={#AppName}SetupMutex

; Windows file-properties metadata. Populates the "Details" tab on the
; built installer .exe so SmartScreen and AV engines see richer trust
; signals than a blank-properties unsigned exe.
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} installer
VersionInfoCopyright=Copyright (C) Agenius AI Labs. MIT licensed.
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

; --- Code signing (off until a signing cert is available) ---
; To enable: in the Inno Setup IDE, open Tools > Configure Sign Tools,
; add a tool named 'mycert' whose command invokes signtool.exe against
; your certificate (e.g. a SignTool=mycert sign /f cert.pfx /p pass /fd
; sha256 /tr <timestamp-url> /td sha256 $f). Then uncomment both lines
; below. Once signed, SmartScreen warnings clear instantly with an EV
; cert, or gradually as download reputation accrues with an OV cert.
;SignTool=mycert sign /fd sha256 /tr http://timestamp.digicert.com /td sha256 $f
;SignedUninstaller=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart"; Description: "Launch {#AppName} when Windows starts"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "{#SrcDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: autostart

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
