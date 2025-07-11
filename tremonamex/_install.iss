[Setup]
AppName=TremoNameX
AppVersion=1.0.0
AppPublisher=Tremoman
AppPublisherURL=https://github.com/tremoman
AppSupportURL=https://github.com/tremoman
AppUpdatesURL=https://github.com/tremoman
DefaultDirName={autopf}\TremoNameX
DefaultGroupName=TremoNameX
AllowNoIcons=yes
LicenseFile=
InfoAfterFile=
OutputDir=installer
OutputBaseFilename=TremoNameX_Setup_v1.0.0
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\tremonamex.exe
UninstallDisplayName=TremoNameX - Đổi tên file hàng loạt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "H:\This\This\My APP\TremoName\tremonamex\build\windows\x64\runner\Release\tremonamex.exe"; DestDir: "{app}"; Flags: ignoreversion

; Flutter Windows DLL
Source: "H:\This\This\My APP\TremoName\tremonamex\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data files
Source: "H:\This\This\My APP\TremoName\tremonamex\build\windows\x64\runner\Release\data\app.so"; DestDir: "{app}\data"; Flags: ignoreversion
Source: "H:\This\This\My APP\TremoName\tremonamex\build\windows\x64\runner\Release\data\icudtl.dat"; DestDir: "{app}\data"; Flags: ignoreversion

; Flutter assets
Source: "H:\This\This\My APP\TremoName\tremonamex\build\windows\x64\runner\Release\data\flutter_assets\*"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\TremoNameX"; Filename: "{app}\tremonamex.exe"; WorkingDir: "{app}"; Comment: "Đổi tên file hàng loạt với giao diện hiện đại"
Name: "{group}\{cm:UninstallProgram,TremoNameX}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\TremoNameX"; Filename: "{app}\tremonamex.exe"; WorkingDir: "{app}"; Tasks: desktopicon; Comment: "Đổi tên file hàng loạt với giao diện hiện đại"


[Run]
Filename: "{app}\tremonamex.exe"; Description: "{cm:LaunchProgram,TremoNameX}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\TremoNameX_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;

function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
  Result := 0;
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) then
  begin
    if (IsUpgrade()) then
    begin
      UnInstallOldVersion();
    end;
  end;
end; 