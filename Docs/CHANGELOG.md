# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT license file

### Changed
- Removed empty `Source\Providers\` directory (providers are in `Source\Bibliotecas\Providers\`)

## [0.1.0] - 2026-06-06

### Added
- Initial project structure with ORM core, extensions, migrator, and test projects
- DelphiArch agent skill for AI-assisted Delphi development

### CI Pipeline
- Self-hosted runner workflow for RAD Studio 13.1 (Athens)
- MSBuild-based build with DUnitX test execution and XML output
- GitHub test reporter integration
- Build artifact publishing (BPL, DCP, CLI)
- Pre-checkout cleanup to handle file locks on Windows
- Retry logic for file deletion and process termination
- Manual checkout fallback (replaces `actions/checkout@v4`)
- Diagnostic output for MSBuild steps
- License detection and fallback between `dcc32.exe` and `bds.exe`
- Use `Start-Process -Wait` for GUI IDE build process

### Fixed
- Heap corruption caused by `Stop-Process` killing `conhost.exe`
- Unicode character parsing errors in PowerShell runner scripts
- Test executable path resolution (dprojs without `DCC_ExeOutput`)
- MSBuild argument parsing for PowerShell
- Silent build failures with proper exit code checks
- EPERM errors during directory cleanup
- `actions/checkout@v4` temp directory cleanup failures
- .dproj files excluded from git tracking

### Removed
- CI workflow disabled due to RAD Studio licensing restrictions
  (Community/Trial does not support command-line compilation)
