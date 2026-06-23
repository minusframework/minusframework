;==============================================================================
; MinusFramework Installer
; Copyright (c) 2026 MinusFramework
; https://minusframework.com.br
;
; Build: rode .\build-installer.ps1 para preparar o staging e compilar
;==============================================================================

#define AppName "MinusFramework"
#define AppVersion "0.1.0"
#define AppPublisher "MinusFramework"
#define AppURL "https://minusframework.com.br"
#define AppSupportURL "https://minusframework.com.br/suporte"

[Setup]
AppId={{B4F2A3D1-7C8E-4F9A-B2D3-E5F6A7B8C9D0}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppSupportURL}
DefaultDirName={code:GetDefaultInstallDir}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=Staging\Docs\LICENSE
OutputDir=..\Dist
OutputBaseFilename=MinusFramework-{#AppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
DisableWelcomePage=no
PrivilegesRequired=admin

;----------------------------------------------------------------------------
; Delphi Version Selection
;----------------------------------------------------------------------------
[Types]
Name: "full";    Description: "Instalacao completa (todos os componentes)"
Name: "custom";  Description: "Instalacao customizada"; Flags: iscustom

[Components]
Name: "d23"; Description: "RAD Studio 12 Athens (BDS 23.0)"; Types: full; Check: IsDelphiInstalled('23.0')
Name: "d22"; Description: "RAD Studio 11 Alexandria (BDS 22.0)"; Types: full; Check: IsDelphiInstalled('22.0')
Name: "d21"; Description: "RAD Studio 10.4 Sydney (BDS 21.0)"; Types: full; Check: IsDelphiInstalled('21.0')
Name: "runtime"; Description: "Runtime (BPLs e DCPs)"; Types: full custom; Flags: fixed
Name: "sources"; Description: "Codigo fonte (Source\*.pas)"; Types: full
Name: "ide";     Description: "Componentes de Design-Time (IDE)"; Types: full
Name: "docs";    Description: "Documentacao e exemplos"; Types: full
Name: "cli";     Description: "Ferramentas de linha de comando (CLI)"; Types: full

;----------------------------------------------------------------------------
; Files — source paths relative to this script (staged by build-installer.ps1)
;----------------------------------------------------------------------------
[Files]

; --- BPLs ---
Source: "Staging\Bpl\MinusTelemetry_Runtime.bpl";  DestDir: "{code:GetBplDir|23.0}"; Components: runtime and d23; Flags: ignoreversion
Source: "Staging\Bpl\MinusMessaging_Runtime.bpl";  DestDir: "{code:GetBplDir|23.0}"; Components: runtime and d23; Flags: ignoreversion
Source: "Staging\Bpl\MinusFramework_Runtime.bpl";  DestDir: "{code:GetBplDir|23.0}"; Components: runtime and d23; Flags: ignoreversion

; --- DCPs ---
Source: "Staging\Dcp\MinusTelemetry_Runtime.dcp";  DestDir: "{code:GetDcpDir|23.0}"; Components: runtime and d23; Flags: ignoreversion
Source: "Staging\Dcp\MinusMessaging_Runtime.dcp";  DestDir: "{code:GetDcpDir|23.0}"; Components: runtime and d23; Flags: ignoreversion
Source: "Staging\Dcp\MinusFramework_Runtime.dcp";  DestDir: "{code:GetDcpDir|23.0}"; Components: runtime and d23; Flags: ignoreversion

; --- Design-Time BPLs (IDE) ---
Source: "Staging\Bpl\MinusFramework_Design.bpl";   DestDir: "{code:GetBplDir|23.0}"; Components: ide and d23; Flags: ignoreversion
Source: "Staging\Bpl\MinusMessaging_Design.bpl";   DestDir: "{code:GetBplDir|23.0}"; Components: ide and d23; Flags: ignoreversion

; --- Source files ---
Source: "Staging\Source\*";     DestDir: "{app}\Source"; Components: sources; Flags: ignoreversion recursesubdirs createallsubdirs

; --- CLI tools ---
Source: "Staging\Bin\*";        DestDir: "{app}\Bin";    Components: cli; Flags: ignoreversion skipifsourcedoesntexist

; --- Documentation ---
Source: "Staging\Docs\*";       DestDir: "{app}\Docs";   Components: docs; Flags: ignoreversion recursesubdirs createallsubdirs

; --- Samples ---
Source: "Staging\Samples\*";    DestDir: "{app}\Samples"; Components: docs; Flags: ignoreversion recursesubdirs createallsubdirs

;----------------------------------------------------------------------------
; Delphi version detection and path helpers
;----------------------------------------------------------------------------
[Code]

function IsDelphiInstalled(const Version: string): Boolean;
var
  RegKey: string;
begin
  RegKey := 'Software\Embarcadero\BDS\' + Version;
  Result := RegKeyExists(HKLM, RegKey) or RegKeyExists(HKLM32, RegKey);
end;

function GetDelphiRootDir(const Version: string): string;
var
  RegKey: string;
begin
  RegKey := 'Software\Embarcadero\BDS\' + Version;
  if not RegQueryStringValue(HKLM, RegKey, 'RootDir', Result) then
    if not RegQueryStringValue(HKLM32, RegKey, 'RootDir', Result) then
      Result := '';
end;

function GetBplDir(Param: string): string;
begin
  Result := GetDelphiRootDir(Param);
  if Result <> '' then
    Result := Result + '\Bpl';
end;

function GetDcpDir(Param: string): string;
begin
  Result := GetDelphiRootDir(Param);
  if Result <> '' then
    Result := Result + '\Dcp';
end;

function GetDefaultInstallDir(Param: string): string;
begin
  Result := ExpandConstant('{pf}\MinusFramework');
end;

//----------------------------------------------------------------------------
// Post-install: register IDE packages
//----------------------------------------------------------------------------
procedure RegisterIDEPackage(const BDSVersion: string; const PackageName: string);
var
  BDSDir: string;
  PackagePath: string;
  Description: string;
begin
  BDSDir := GetDelphiRootDir(BDSVersion);
  if BDSDir = '' then Exit;

  PackagePath := BDSDir + '\Bpl\' + PackageName;
  Description := 'MinusFramework Design Package';

  if RegKeyExists(HKLM, 'Software\Embarcadero\BDS\' + BDSVersion + '\Known Packages') then
    RegWriteStringValue(HKLM, 'Software\Embarcadero\BDS\' + BDSVersion + '\Known Packages', PackagePath, Description)
  else
    RegWriteStringValue(HKCU, 'Software\Embarcadero\BDS\' + BDSVersion + '\Known Packages', PackagePath, Description);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsComponentSelected('ide') then
    begin
      if WizardIsComponentSelected('d23') then
      begin
        RegisterIDEPackage('23.0', 'MinusFramework_Design.bpl');
        RegisterIDEPackage('23.0', 'MinusMessaging_Design.bpl');
      end;
      if WizardIsComponentSelected('d22') then
      begin
        RegisterIDEPackage('22.0', 'MinusFramework_Design.bpl');
        RegisterIDEPackage('22.0', 'MinusMessaging_Design.bpl');
      end;
      if WizardIsComponentSelected('d21') then
      begin
        RegisterIDEPackage('21.0', 'MinusFramework_Design.bpl');
        RegisterIDEPackage('21.0', 'MinusMessaging_Design.bpl');
      end;
    end;
  end;
end;

[Icons]
Name: "{group}\Documentacao";      Filename: "{app}\Docs"
Name: "{group}\Site do Produto";   Filename: "{#AppURL}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
