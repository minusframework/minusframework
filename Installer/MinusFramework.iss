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

[Types]
Name: "full";    Description: "Instalacao completa (todos os componentes)"
Name: "custom";  Description: "Instalacao customizada"; Flags: iscustom

[Components]
Name: "runtime"; Description: "Runtime (BPLs e DCPs)"; Types: full custom; Flags: fixed
Name: "sources"; Description: "Codigo fonte (Source\*.pas)"; Types: full
Name: "ide";     Description: "Componentes de Design-Time (IDE)"; Types: full
Name: "docs";    Description: "Documentacao e exemplos"; Types: full
Name: "cli";     Description: "Ferramentas de linha de comando (CLI)"; Types: full

[Files]

; --- Runtime BPLs ---
Source: "Staging\Bpl\*_Runtime.bpl";   DestDir: "{code:GetBplDir|23.0}"; Components: runtime; Flags: ignoreversion skipifsourcedoesntexist

; --- Design BPLs ---
Source: "Staging\Bpl\*_Design.bpl";    DestDir: "{code:GetBplDir|23.0}"; Components: ide; Flags: ignoreversion skipifsourcedoesntexist

; --- DCPs ---
Source: "Staging\Dcp\*.dcp";           DestDir: "{code:GetDcpDir|23.0}"; Components: runtime; Flags: ignoreversion skipifsourcedoesntexist

; --- Source files ---
Source: "Staging\Source\*";            DestDir: "{app}\Source"; Components: sources; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

; --- CLI tools ---
Source: "Staging\Bin\*";               DestDir: "{app}\Bin";    Components: cli; Flags: ignoreversion skipifsourcedoesntexist

; --- Documentation ---
Source: "Staging\Docs\*";              DestDir: "{app}\Docs";   Components: docs; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

; --- Samples ---
Source: "Staging\Samples\*";           DestDir: "{app}\Samples"; Components: docs; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

[Code]

function GetDefaultInstallDir(Param: string): string;
begin
  Result := ExpandConstant('{pf}\MinusFramework');
end;

[Icons]
Name: "{group}\Documentacao";      Filename: "{app}\Docs"
Name: "{group}\Site do Produto";   Filename: "{#AppURL}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
