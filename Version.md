# Version & Changelog History

## Project: Brave-Origin-Unlocker-Windows
**Created:** 2026-09-25 22:20:00 IST
**Architecture:** PowerShell (Windows Automation)
**Target Platform:** Windows 10 / 11 (x64)
**Repository:** https://github.com/mrdarksidetm/Brave-Origin-Unlocker-Windows

---

### [Initial Release] - 2026-09-25 22:20:00 IST
- **Status:** Initialized (100%)
- **Target Channels:**
  - Brave-Origin
  - Brave-Origin-Beta
  - Brave-Origin-Nightly
- **Libraries & Tools:**
  - PowerShell: 5.1+ / 7.0+
  - PSScriptAnalyzer: Latest
  - GitHub Actions: actions/checkout@v4
- **Modules & Files Created:**
  - `README.md` — Project documentation, abstract, one-line PowerShell execution, direct download, and disclaimer.
  - `LICENSE` — MIT License for open-source distribution.
  - `.gitignore` — Windows, PowerShell, IDE, and temporary build artifact ignore rules.
  - `scripts/unlocker.ps1` — Automated installer download, execution, and native JSON Local State patcher.
  - `assests/images/Brave-origin-Unlocker-Dark.svg` — Dark mode banner logo asset.
  - `assests/images/Brave-origin-Unlocker-Light.svg` — Light mode banner logo asset.
  - `assests/images/Download-File.svg` — Download badge asset.
  - `.github/workflows/validate.yml` — CI workflow for PowerShell syntax parsing and PSScriptAnalyzer validation.
  - `.github/ISSUE_TEMPLATE/bug_report.md` — Issue template for user bug reports.
  - `.github/ISSUE_TEMPLATE/feature_request.md` — Issue template for feature proposals.
  - `.github/pull_request_template.md` — PR checklist and review guidelines.
  - `Version.md` — Version history and project evolution tracker.


### [2026-09-26 01:25:00 IST] - GitHub Pages Documentation & Landing Site Launch
- **Author**: mrdarksidetm
- **Status**: Completed & Deployed
- **Architectural & Design Enhancements**:
  - Built official GitHub Pages documentation and one-click quick launch site in `docs/index.html`.
  - Implemented Vector-Drawable dark theme design system with interactive PowerShell snippet copy button.
  - Added multi-channel patching specifications, 3-step setup guide, and SVG branding assets.
  - Established cross-navigation linking directly back to the Atelier central hub.
- **Files Created / Modified**:
  - `docs/index.html` (Created)
  - `docs/logo.svg` (Created)
  - `Version.md` (Appended)
- **Verification**: Verified HTML semantic structure, CSS styling, clipboard copy function, and responsive layout.


### [2026-09-27 10:10:00 IST] - Script Modernization & Human-Grade Refactoring
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Channels**:
  - Brave-Origin
  - Brave-Origin-Beta
  - Brave-Origin-Nightly
  - Portable / Custom User Data Paths
- **Root Cause Analysis (Reddit Failure Reports)**:
  - Script unconditionally forced download of `BraveOriginSetup.exe` from rate-limited endpoint (`https://laptop-updates.brave.com/...`) even when browser was already installed.
  - Script defaulted temporary installer path to `C:\Windows\Temp`, causing Access Denied fatal errors for non-elevated user execution.
  - `[System.Text.Encoding]::UTF8` in .NET Framework / PowerShell 5.1 emitted UTF-8 Byte Order Marks (BOM, 0xEF 0xBB 0xBF), which Chromium's JSON parser explicitly rejects as invalid syntax.
  - `ConvertTo-Json -Depth 10` truncated deep Chromium profile structures beyond depth 10 into string type names (`System.Management.Automation.PSCustomObject`), corrupting user settings.
  - Script created phantom directories with invalid skeletal `Local State` files for channels not installed on the system.
  - Script killed running processes asynchronously without waiting for file lock release, throwing I/O sharing violations.
- **Architectural & Design Enhancements**:
  - Redesigned `scripts/unlocker.ps1` with senior sysadmin/human-grade conventions: proper comment-based help, clear status tags (`[+]`, `[*]`, `[!]`, `[-]`), and non-destructive execution.
  - Eliminated redundant downloads: checks for existing installations first and patches immediately.
  - Added CLI parameters: `-Channel` ('Release', 'Beta', 'Nightly', 'All'), `-UserDataPath`, `-Install`, `-Force`, `-Restore`, and `-NoBackup`.
  - Implemented automatic `.bak` backups with a dedicated `-Restore` rollback mechanism.
  - Switched to `New-Object System.Text.UTF8Encoding $false` to enforce raw UTF-8 without BOM.
  - Set `-Depth 100` on `ConvertTo-Json` to guarantee complete retention of Chromium profile trees.
  - Refined installation detection logic to prevent creating dummy ghost folders for uninstalled channels.
  - Updated `README.md` with revised abstract, parameter documentation, and clean instructions.
- **Files Created / Modified**:
  - `scripts/unlocker.ps1` (Refactored)
  - `README.md` (Updated)
  - `Version.md` (Appended)
- **Verification**:
  - Verified 0 AST syntax errors via `[System.Management.Automation.Language.Parser]::ParseFile` on both Windows PowerShell 5.1 and PowerShell 7.
  - Verified clean JSON roundtrip and BOM absence via Node.js binary buffer inspections.
  - Successfully executed full unlock, backup creation, and `-Restore` rollback tests on the local test environment.

### [2026-09-27 10:16:00 IST] - Reddit Community Bugfix: Split-Path Null Binding on Invoke-Expression (iex)
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Channels**:
  - All Windows PowerShell & PowerShell Core execution environments
- **Reddit Community Investigation (Thread r/brave/comments/1wq5wg3)**:
  - Users reported: `Invoke-Expression: Cannot bind argument to parameter 'Path' because it is null.`
  - Direct Root Cause: When running `iex (iwr ...).Content`, the script runs in memory without an on-disk script path. The previous code called `Split-Path -Parent $MyInvocation.MyCommand.Path` unconditionally. Because `$MyInvocation.MyCommand.Path` is `$null` during in-memory expression evaluation, PowerShell threw a fatal ParameterArgumentValidationErrorNullNotAllowed exception under `$ErrorActionPreference = 'Stop'`, aborting execution before doing anything.
  - Secondary Feedback: Reddit users called out marketing buzzwords ("software forge", "precision forge") and unnecessary elevation requirements on the landing page.
- **Fixes Applied**:
  - Implemented safe path resolution: checks `if (-not $scriptDir -and $MyInvocation.MyCommand.Path)` before attempting `Split-Path`. Defaults cleanly to `$tempDir = [System.IO.Path]::GetTempPath()` when run in memory via `iex`.
  - Tested and verified execution of `iex (Get-Content -Raw ./scripts/unlocker.ps1)` and web-streamed string blocks.
  - Updated `docs/index.html` to remove confusing "Admin Privileges Required" badge (since `%LOCALAPPDATA%` patching works without elevation) and replaced pretentious buzzwords with direct, human-written open-source copy.
- **Files Modified**:
  - `scripts/unlocker.ps1` (Verified iex compatibility)
  - `docs/index.html` (Copy & badge updates)
  - `Version.md` (Appended)
- **Verification**:
  - Confirmed `iex (Get-Content -Raw ./scripts/unlocker.ps1)` executes without error and completes full unlock sequence.

### [2026-09-27 10:21:00 IST] - README Overhaul: Parameter Documentation & Anti-Slop Voice
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Files**:
  - `README.md`
- **Architectural & Editorial Updates**:
  - Completely purged generic AI-style abstract and boilerplate corporate disclaimers.
  - Documented the full suite of CLI parameters (`-Channel`, `-Force`, `-Install`, `-UserDataPath`, `-Restore`, `-NoBackup`) in a clean, structured table specifying parameter types, defaults, and exact behaviors.
  - Added copy-pasteable real-world examples covering standard run, forced execution, portable builds, and rollback.
  - Adopted an aggressive, witty, and razor-sharp developer voice addressing the $60 local JSON flag paywall and Linux disparity.
- **Verification**:
  - Inspected formatting, table rendering, code block syntax, and relative asset paths.

### [2026-09-27 10:41:00 IST] - Legal Hardening & Statutory Loophole Implementation
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Files**:
  - `LEGAL.md` (Created)
  - `README.md` (Updated)
  - `docs/index.html` (Updated)
  - `Version.md` (Appended)
- **Implemented Legal Safeguards**:
  - **Nominative Fair Use**: Added explicit disclaimers under 15 U.S.C. § 1125 clarifying that all modified logo badges, silhouettes, and brand references are strictly nominative identifiers and do not imply endorsement or affiliation.
  - **Dual-Use Doctrine (*Sony Betamax*)**: Reframed the tool's core identity as an offline profile state and local configuration utility for enterprise deployment, offline developer testing, and portable environments.
  - **DMCA Section 1201(f) Interoperability**: Citing statutory protection for reverse engineering and configuration modification to achieve software interoperability.
  - **Plaintext Configuration Precedent (*Lexmark v. Static Control*)**: Formally documented that unencrypted, plaintext JSON files on a user's local disk do not meet the legal threshold of an "effective technological protection measure" (TPM).
  - **MPL 2.0 Open-Source Provenance**: Documented Brave's underlying open-source codebase and the statutory right to compile from source.
  - **Anti-Censorship & Mirroring Guide**: Added Git bundle creation instructions and Codeberg/decentralized host recommendations.

### [2026-09-27 20:51:00 IST] - Project Rebranding: Migration from "Unlocker" to "Profile" & Multi-Remote Hosting
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Files**:
  - `scripts/profile.ps1` (Renamed from `scripts/unlocker.ps1` and updated)
  - `assests/images/Brave-origin-Profile-Dark.svg` (Renamed from `assests/images/Brave-origin-Unlocker-Dark.svg`)
  - `assests/images/Brave-origin-Profile-Light.svg` (Renamed from `assests/images/Brave-origin-Unlocker-Light.svg`)
  - `.github/ISSUE_TEMPLATE/bug_report.md` (Updated)
  - `.github/workflows/validate.yml` (Updated)
  - `README.md` (Updated)
  - `docs/index.html` (Updated)
  - `Version.md` (Appended)
- **Modifications & Migration Details**:
  - **Terminology Neutralization**: Systematically renamed all references from "Unlocker" to "Profile" across codebase, documentation, CI workflows, and website assets to align with utility-focused profile configuration semantics.
  - **Script Renaming & Verification**: Renamed `unlocker.ps1` to `profile.ps1`, updated AST syntax parsing and PSScriptAnalyzer validation tests, and verified zero syntax errors.
  - **Multi-Platform Hosting Migration**: Reconfigured documentation URLs and download links to target decentralized and independent Git hosting providers (Codeberg and GitLab) with verified SSH ed25519 signing keys.

### [2026-09-27 21:22:00 IST] - Dual-Host Documentation & GitLab CI Integration
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Files**:
  - `README.md` (Updated)
  - `docs/index.html` (Updated)
  - `.gitlab-ci.yml` (Created)
  - `Version.md` (Appended)
- **Architectural & Cross-Platform Updates**:
  - **Dual-Mirror Documentation**: Enhanced `README.md` with explicit, dedicated Quick Run one-liners, repository clone instructions, and issue tracker references for both primary (Codeberg) and secondary mirror (GitLab) hosts.
  - **Showcase Navigation & Footer**: Expanded navigation bar and footer in `docs/index.html` to link to both Codeberg and GitLab repositories and issue trackers.
  - **Automated GitLab CI Pipeline**: Created `.gitlab-ci.yml` using `mcr.microsoft.com/powershell` image to automatically execute AST parser validation on `scripts/profile.ps1` upon commit push.

### [2026-09-28 02:10:00 IST] - macOS Native Zero-Dependency Profile Engine & Cross-Platform CI
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Platform**: macOS (Darwin 10.15 Catalina through macOS 15 Sequoia / Apple Silicon & Intel)
- **Target Channels**:
  - Brave-Origin (Release)
  - Brave-Origin-Beta (Beta)
  - Brave-Origin-Nightly (Nightly)
- **Libraries & Tools**:
  - macOS Shell: `/bin/zsh`, `/bin/sh` (POSIX compliant)
  - JavaScript for Automation (JXA): `osascript -l JavaScript` (JavaScriptCore Foundation bindings)
  - macOS Subsystem Utilities: `sw_vers`, `hdiutil`, `ditto`, `plutil`, `curl`, `pkill`, `xattr`
  - CI Engines: GitLab CI (`alpine:latest`, `bash`), GitHub Actions (`macos-latest`)
- **Modules & Files Created/Updated**:
  - `scripts/profile.sh` — Native macOS zero-dependency configuration script supporting architecture auto-detection (`arm64`/`x86_64`), native DMG download and installation via `hdiutil` & `ditto`, safe atomic JSON state manipulation via `osascript` JXA, process lifecycle handling, and `.bak` backups.
  - `.gitlab-ci.yml` — Added `validate-macos-shell` pipeline stage to run automated syntax checks (`bash -n`) on `scripts/profile.sh`.
  - `.github/workflows/validate.yml` — Added `validate-macos-shell` job running on `macos-latest` to lint and validate shell script syntax across commits and pull requests.
  - `README.md` — Updated badges, overview, one-liners for Codeberg & GitLab mirrors, and CLI flag documentation for both Windows and macOS platforms.
  - `Version.md` — Appended changelog history according to project tracking mandates.
- **Architectural & Cross-Platform Implementation Details**:
  - **Zero-Dependency Mandate**: Replaced third-party runtime requirements (Deno, Node.js, Python, or Homebrew) with macOS pre-installed core components (`osascript` JXA and `plutil`), bypassing Apple's developer tools prompt on macOS Monterey+.
  - **Atomic Safe State Mutation**: Leveraged Apple's native Foundation framework (`ObjC.import('Foundation')` and `writeToFileAtomicallyEncodingError`) to read, patch `brave.origin` and `skus.state`, and serialize UTF-8 JSON atomically without BOM headers.
  - **Architecture-Aware CDN Routing**: Automated resolution of official Brave Origin `.dmg` installers for Apple Silicon (`arm64`) vs Intel (`x86_64`) with automated mount, Gatekeeper quarantine clearance (`xattr -cr`), and directory staging.

### [2026-09-28 02:11:00 IST] - Interactive Showcase Dual-OS Switcher
- **Author**: Antigravity Pair Programmer
- **Status**: Completed & Verified (100%)
- **Target Platform**: Web Showcase / Documentation Portal (`docs/index.html`)
- **Modules & Files Updated**:
  - `docs/index.html` — Integrated interactive OS platform switcher tab component (`switchPlatform`) allowing users to dynamically toggle between Windows (PowerShell) and macOS (Terminal / Zsh) one-liner commands, download targets, and platform metadata.
  - `Version.md` — Appended changelog entry tracking web showcase enhancements.
