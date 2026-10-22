<#
.SYNOPSIS
    Brave Origin Profile Configuration Tool for Windows.

.DESCRIPTION
    Patches Brave Origin's local configuration ('Local State') to configure profile
    features offline without recurring subscription checks. Works across Release,
    Beta, and Nightly channels, supports portable installs, automatic backups,
    and rollback/restore.

.PARAMETER Channel
    Target channel to patch: 'Release', 'Beta', 'Nightly', or 'All'.
    Default: 'All' (auto-detects all installed channels).

.PARAMETER UserDataPath
    Custom path to a 'User Data' directory (useful for portable or non-standard installs).

.PARAMETER Install
    Download and launch the official Brave Origin installer if no installation is found.

.PARAMETER Force
    Automatically terminates running Brave processes without prompting.

.PARAMETER Restore
    Restores the previous 'Local State.bak' configuration backup.

.PARAMETER Uninstall
    Completely uninstalls Brave Origin applications, user profiles, caches, and shortcuts.

.PARAMETER NoBackup
    Skips creating a backup (.bak) of the original configuration file.

.EXAMPLE
    .\profile.ps1
    Auto-detects installed Brave Origin channels and applies the patch.

.EXAMPLE
    .\profile.ps1 -Force
    Closes running Brave instances and configures profile automatically.

.EXAMPLE
    .\profile.ps1 -Restore
    Restores the original Local State files from backup.

.EXAMPLE
    .\profile.ps1 -Uninstall
    Completely removes Brave Origin and restores a clean slate.

.EXAMPLE
    .\profile.ps1 -UserDataPath "D:\PortableApps\Brave-Origin\Data"
    Patches a specific portable installation.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet("Release", "Beta", "Nightly", "All")]
    [string]$Channel = "All",

    [string]$UserDataPath,

    [switch]$Install,

    [switch]$Force,

    [switch]$Restore,

    [switch]$Uninstall,

    [switch]$NoBackup
)

Set-StrictMode -Off

function Write-Log {
    param(
        [ValidateSet("INFO", "SUCCESS", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Message
    )

    switch ($Level) {
        "SUCCESS" { Write-Host "[+] $Message" -ForegroundColor Green }
        "INFO"    { Write-Host "[*] $Message" -ForegroundColor Cyan }
        "WARN"    { Write-Host "[!] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[-] $Message" -ForegroundColor Red }
        "DEBUG"   { Write-Host "    $Message" -ForegroundColor DarkGray }
    }
}

function Set-TlsSecurity {
    # Ensure modern TLS 1.2 and TLS 1.3 (if supported by the host .NET runtime)
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        if ([System.Enum]::IsDefined([System.Net.SecurityProtocolType], "Tls13")) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls13
        }
    } catch {
        # Fall back gracefully to runtime defaults
    }
}

function Stop-RunningBrave {
    param([switch]$ForceClose)

    $braveProcs = Get-Process -Name "brave" -ErrorAction SilentlyContinue
    if (-not $braveProcs) { return $true }

    if (-not $ForceClose) {
        if ([Environment]::UserInteractive) {
            Write-Log -Level WARN "Brave is currently running. It must be closed to safely update configuration."
            $answer = Read-Host "Close running Brave instances now? (y/N)"
            if ($answer -notmatch '^[Yy]') {
                Write-Log -Level ERROR "Aborted by user. Please close Brave and try again."
                return $false
            }
        } else {
            Write-Log -Level WARN "Non-interactive environment detected. Closing active Brave instances..."
        }
    }

    Write-Log -Level INFO "Stopping active Brave processes..."
    $braveProcs | Stop-Process -Force -ErrorAction SilentlyContinue

    # Wait up to 5 seconds for file locks to release
    for ($i = 0; $i -lt 50; $i++) {
        if (-not (Get-Process -Name "brave" -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
    }

    return $true
}

function Find-InstalledChannels {
    $localAppData = $env:LOCALAPPDATA
    $programFiles = $env:ProgramFiles
    $programFilesX86 = ${env:ProgramFiles(x86)}

    $definitions = @(
        @{ Name = "Release"; Folder = "Brave-Origin"; Label = "Brave Origin" },
        @{ Name = "Beta"; Folder = "Brave-Origin-Beta"; Label = "Brave Origin Beta" },
        @{ Name = "Nightly"; Folder = "Brave-Origin-Nightly"; Label = "Brave Origin Nightly" }
    )

    $found = @()

    foreach ($def in $definitions) {
        if ($Channel -ne "All" -and $Channel -ne $def.Name) {
            continue
        }

        $folder = $def.Folder
        $userData = Join-Path $localAppData "BraveSoftware\$folder\User Data"
        $localState = Join-Path $userData "Local State"

        # Check binary locations (64-bit Program Files, AppData per-user, 32-bit Program Files)
        $exeCandidates = @(
            (Join-Path $programFiles "BraveSoftware\$folder\Application\brave.exe"),
            (Join-Path $localAppData "BraveSoftware\$folder\Application\brave.exe")
        )
        if ($programFilesX86) {
            $exeCandidates += (Join-Path $programFilesX86 "BraveSoftware\$folder\Application\brave.exe")
        }

        $exeFound = $exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

        # Check if genuine user profile exists (or application binary exists)
        $hasValidUserData = (Test-Path $userData) -and (
            (Test-Path (Join-Path $userData "Default")) -or
            (Test-Path (Join-Path $userData "Preferences")) -or
            ((Test-Path $localState) -and ((Get-Item $localState).Length -gt 1000))
        )

        if ($exeFound -or $hasValidUserData) {
            $found += [PSCustomObject]@{
                Name           = $def.Name
                Label          = $def.Label
                UserDataDir    = $userData
                LocalStatePath = $localState
                ExecutablePath = $exeFound
            }
        }
    }

    return $found
}

function Install-BraveOrigin {
    Set-TlsSecurity

    $installerName = "BraveOriginSetup.exe"
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir -and $MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    # 1. Check if installer already exists locally (in current dir or script dir)
    $candidateLocal = @(
        (Join-Path (Get-Location) $installerName),
        $(if ($scriptDir) { Join-Path $scriptDir $installerName })
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

    $installerPath = $candidateLocal

    # 2. If not found locally, download to user's temp directory
    if (-not $installerPath) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $downloadTarget = Join-Path $tempDir $installerName

        # Direct CDN download link (avoids redirects and rate limiting)
        $downloadUrls = @(
            "https://referrals.brave.com/latest/BraveOriginSetup.exe",
            "https://laptop-updates.brave.com/latest/origin/winx64/release"
        )

        $downloaded = $false
        foreach ($url in $downloadUrls) {
            Write-Log -Level INFO "Downloading Brave Origin installer from $url..."
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                $webClient.DownloadFile($url, $downloadTarget)

                if ((Test-Path $downloadTarget) -and ((Get-Item $downloadTarget).Length -gt 500000)) {
                    Write-Log -Level SUCCESS "Installer downloaded successfully: $downloadTarget"
                    $installerPath = $downloadTarget
                    $downloaded = $true
                    break
                }
            } catch {
                Write-Log -Level WARN "Download from $url failed: $($_.Exception.Message)"
            }
        }

        if (-not $downloaded) {
            Write-Log -Level ERROR "Could not download Brave Origin installer. Please download and install it manually."
            return $false
        }
    } else {
        Write-Log -Level INFO "Using existing installer: $installerPath"
    }

    Write-Log -Level INFO "Launching installer (accept UAC prompt if prompted)..."
    try {
        $proc = Start-Process -FilePath $installerPath -Wait -PassThru
        Write-Log -Level SUCCESS "Installer completed with exit code: $($proc.ExitCode)"

        # Give installer a moment to settle and create initial profile directories
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-Log -Level ERROR "Failed to run installer: $($_.Exception.Message)"
        return $false
    }
}

function Set-NotePropertySafe {
    param($Target, [string]$PropertyName, $Value)

    if ($Target.PSObject.Properties[$PropertyName]) {
        $Target.$PropertyName = $Value
    } else {
        $Target | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $Value -Force
    }
}

function Patch-LocalStateFile {
    param(
        [string]$Path,
        [string]$DisplayName,
        [switch]$SkipBackup
    )

    if (-not (Test-Path (Split-Path -Parent $Path))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    }

    # Backup handling
    $backupPath = "$Path.bak"
    if (Test-Path $Path) {
        if (-not $SkipBackup) {
            try {
                Copy-Item -Path $Path -Destination $backupPath -Force
                Write-Log -Level DEBUG "Backup saved: $backupPath"
            } catch {
                Write-Log -Level WARN "Failed to create backup: $($_.Exception.Message)"
            }
        }
    }

    # Read and parse existing Local State (or initialize fresh)
    $localState = $null
    if (Test-Path $Path) {
        try {
            $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
            # Remove UTF-8 BOM if left behind by previous bad scripts
            if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
                $raw = $raw.Substring(1)
            }
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $localState = $raw | ConvertFrom-Json
            }
        } catch {
            Write-Log -Level WARN "Existing configuration could not be parsed. A clean configuration will be created."
        }
    }

    if ($null -eq $localState) {
        $localState = [PSCustomObject]@{}
    }

    # Inject brave.origin = { purchase_validated: true }
    if (-not $localState.PSObject.Properties['brave'] -or $null -eq $localState.brave) {
        $localState | Add-Member -NotePropertyName 'brave' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if (-not $localState.brave.PSObject.Properties['origin'] -or $null -eq $localState.brave.origin) {
        $localState.brave | Add-Member -NotePropertyName 'origin' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    Set-NotePropertySafe -Target $localState.brave.origin -PropertyName 'purchase_validated' -Value $true

    # Inject skus.state["67"] = { credentials: { items: { "6": "7" } } }
    if (-not $localState.PSObject.Properties['skus'] -or $null -eq $localState.skus) {
        $localState | Add-Member -NotePropertyName 'skus' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if (-not $localState.skus.PSObject.Properties['state'] -or $null -eq $localState.skus.state) {
        $localState.skus | Add-Member -NotePropertyName 'state' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $skuPayload = '{"credentials":{"items":{"6":"7"}}}'
    Set-NotePropertySafe -Target $localState.skus.state -PropertyName '67' -Value $skuPayload

    # Serialize JSON with deep depth (prevents truncation of deep Chromium settings)
    $json = $localState | ConvertTo-Json -Depth 100

    # Write UTF-8 WITHOUT BOM (Chromium json_reader rejects BOM with syntax error)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    try {
        [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
    } catch {
        Write-Log -Level ERROR "Failed to write '$Path': $($_.Exception.Message)"
        return $false
    }

    # Verify JSON syntax integrity after writing
    try {
        $testContent = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $null = $testContent | ConvertFrom-Json
        Write-Log -Level SUCCESS "$DisplayName configured successfully."
        return $true
    } catch {
        Write-Log -Level ERROR "Verification failed for '$Path'. Output was not valid JSON."
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $Path -Force
            Write-Log -Level WARN "Restored original backup."
        }
        return $false
    }
}

function Restore-LocalStateFile {
    param(
        [string]$Path,
        [string]$DisplayName
    )

    $backupPath = "$Path.bak"
    if (Test-Path $backupPath) {
        try {
            Copy-Item -Path $backupPath -Destination $Path -Force
            Write-Log -Level SUCCESS "$DisplayName restored from backup."
            return $true
        } catch {
            Write-Log -Level ERROR "Failed to restore $($DisplayName): $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Log -Level WARN "No backup file found for $DisplayName ($backupPath)."
        return $false
    }
}

function Invoke-BraveOriginUninstall {
    param([switch]$ForceUninstall)

    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "   Brave Origin Complete Clean Slate (Windows)        " -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not $ForceUninstall) {
        Write-Log -Level WARN "This will permanently remove Brave Origin applications, user profiles, caches, and shortcuts."
        if ([Environment]::UserInteractive) {
            $confirm = Read-Host "Are you sure you want to proceed with complete removal? (y/N)"
            if ($confirm -notmatch '^[Yy]') {
                Write-Log -Level INFO "Uninstallation cancelled by user."
                return
            }
        }
    }

    $procNames = @("brave", "brave_crashpad_handler", "BraveUpdate", "BraveOriginSetup")
    $braveProcs = Get-Process -Name $procNames -ErrorAction SilentlyContinue | Where-Object {
        try {
            $_.Path -like "*Brave-Origin*" -or $_.Path -like "*BraveSoftware\Brave-Origin*" -or $_.Name -like "*BraveOrigin*"
        } catch {
            $true
        }
    }

    if ($braveProcs) {
        Write-Log -Level INFO "Terminating running Brave Origin processes..."
        $braveProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-Log -Level SUCCESS "Running processes closed."
    }

    $targetChannels = @()
    switch ($Channel) {
        "Release" { $targetChannels = @("Brave-Origin") }
        "Beta"    { $targetChannels = @("Brave-Origin-Beta") }
        "Nightly" { $targetChannels = @("Brave-Origin-Nightly") }
        "All"     { $targetChannels = @("Brave-Origin", "Brave-Origin-Beta", "Brave-Origin-Nightly") }
    }

    foreach ($ch in $targetChannels) {
        $chDisplay = $ch -replace "-", " "
        Write-Log -Level INFO "Processing channel: $chDisplay..."

        $setupLocations = @(
            "$env:LOCALAPPDATA\BraveSoftware\$ch\Application",
            "$env:ProgramFiles\BraveSoftware\$ch\Application",
            "${env:ProgramFiles(x86)}\BraveSoftware\$ch\Application"
        )

        foreach ($loc in $setupLocations) {
            if (Test-Path $loc) {
                $installer = Get-ChildItem -Path $loc -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($installer) {
                    Write-Log -Level INFO "Executing native Chromium uninstaller for $chDisplay..."
                    try {
                        Start-Process -FilePath $installer.FullName -ArgumentList "--uninstall", "--force-uninstall", "--delete-profile" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 1
                    } catch {}
                }
            }
        }

        $foldersToPurge = @(
            "$env:LOCALAPPDATA\BraveSoftware\$ch",
            "$env:ProgramFiles\BraveSoftware\$ch",
            "${env:ProgramFiles(x86)}\BraveSoftware\$ch",
            "$env:APPDATA\BraveSoftware\$ch"
        )

        foreach ($folder in $foldersToPurge) {
            if (Test-Path $folder) {
                try {
                    Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                    Write-Log -Level SUCCESS "Removed directory: $folder"
                } catch {
                    Write-Log -Level WARN "Could not completely delete $folder (file in use or permission denied)."
                }
            }
        }

        $shortcutLocations = @(
            [Environment]::GetFolderPath('Desktop'),
            [Environment]::GetFolderPath('CommonDesktop'),
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Brave Software",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Brave Software",
            "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        )

        foreach ($sLoc in $shortcutLocations) {
            if (Test-Path $sLoc) {
                $shortcuts = Get-ChildItem -Path $sLoc -Filter "*$chDisplay*.lnk" -ErrorAction SilentlyContinue
                foreach ($s in $shortcuts) {
                    try {
                        Remove-Item -Path $s.FullName -Force -ErrorAction SilentlyContinue
                        Write-Log -Level SUCCESS "Removed shortcut: $($s.FullName)"
                    } catch {}
                }
            }
        }

        $regKeys = @(
            "HKCU:\Software\BraveSoftware\$ch",
            "HKCU:\Software\Clients\StartMenuInternet\$ch",
            "HKLM:\Software\BraveSoftware\$ch",
            "HKLM:\Software\WOW6432Node\BraveSoftware\$ch",
            "HKLM:\Software\Clients\StartMenuInternet\$ch"
        )

        foreach ($rk in $regKeys) {
            if (Test-Path $rk) {
                try {
                    Remove-Item -Path $rk -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log -Level SUCCESS "Removed registry key: $rk"
                } catch {}
            }
        }

        $uninstallRegs = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($uReg in $uninstallRegs) {
            if (Test-Path $uReg) {
                $entries = Get-ChildItem -Path $uReg -ErrorAction SilentlyContinue
                foreach ($entry in $entries) {
                    try {
                        $dName = (Get-ItemProperty -Path $entry.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
                        if ($dName -and ($dName -like "*$chDisplay*" -or $dName -like "*$ch*")) {
                            Remove-Item -Path $entry.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                            Write-Log -Level SUCCESS "Removed uninstall entry: $dName"
                        }
                    } catch {}
                }
            }
        }
    }

    if ((Test-Path "$env:LOCALAPPDATA\BraveSoftware") -and ((Get-ChildItem -Path "$env:LOCALAPPDATA\BraveSoftware" -ErrorAction SilentlyContinue).Count -eq 0)) {
        Remove-Item -Path "$env:LOCALAPPDATA\BraveSoftware" -Force -ErrorAction SilentlyContinue
    }

    $tempInstallers = Get-ChildItem -Path $env:TEMP -Filter "*BraveOriginSetup*.exe" -ErrorAction SilentlyContinue
    foreach ($ti in $tempInstallers) {
        Remove-Item -Path $ti.FullName -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path "$env:TEMP\brave_installer*" -Recurse -Force -ErrorAction SilentlyContinue

    # 7. Unregister Scheduled Update Tasks
    try {
        Get-ScheduledTask -TaskName "*Brave*Origin*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}

    Write-Host ""
    Write-Host "[✔] Clean slate restored. All Brave Origin data, applications, and shortcuts completely removed." -ForegroundColor Green
    Write-Host ""
}

# --- Entry Point ---
Write-Host ""
Write-Host "  Brave Origin Profile for Windows" -ForegroundColor Cyan
Write-Host "  https://github.com/junksidetm/Brave-Origin-Unlocker-Windows" -ForegroundColor DarkGray
Write-Host ""

if ($Uninstall) {
    Invoke-BraveOriginUninstall -ForceUninstall:$Force
    return
}

$targets = @()

if ($UserDataPath) {
    if (-not (Test-Path $UserDataPath)) {
        Write-Log -Level ERROR "Provided UserDataPath does not exist: $UserDataPath"
        return
    }

    $localStatePath = if ((Split-Path -Leaf $UserDataPath) -eq "Local State") {
        $UserDataPath
    } else {
        Join-Path $UserDataPath "Local State"
    }

    $targets += [PSCustomObject]@{
        Label          = "Custom Profile"
        LocalStatePath = $localStatePath
    }
} else {
    $detected = Find-InstalledChannels

    if ($detected.Count -eq 0) {
        Write-Log -Level WARN "No existing Brave Origin installation detected on this system."

        $shouldInstall = $Install
        if (-not $shouldInstall -and [Environment]::UserInteractive) {
            $choice = Read-Host "Would you like to download and install Brave Origin now? (y/N)"
            if ($choice -match '^[Yy]') {
                $shouldInstall = $true
            }
        }

        if ($shouldInstall) {
            $installed = Install-BraveOrigin
            if ($installed) {
                $detected = Find-InstalledChannels
            }
        }

        if ($detected.Count -eq 0) {
            Write-Log -Level ERROR "No Brave Origin installations available to patch."
            Write-Log -Level INFO  "If you have a portable build, run: .\profile.ps1 -UserDataPath <path-to-user-data>"
            return
        }
    }

    $targets = @($detected)
}

if (-not (Stop-RunningBrave -ForceClose:$Force)) {
    return
}

$successCount = 0
$totalTargets = @($targets).Count

foreach ($target in $targets) {
    if ($Restore) {
        $ok = Restore-LocalStateFile -Path $target.LocalStatePath -DisplayName $target.Label
    } else {
        $ok = Patch-LocalStateFile -Path $target.LocalStatePath -DisplayName $target.Label -SkipBackup:$NoBackup
    }
    if ($ok) { $successCount++ }
}

Write-Host ""
if ($Restore) {
    Write-Log -Level SUCCESS "Restore complete ($successCount/$totalTargets configuration(s) restored)."
} else {
    Write-Log -Level SUCCESS "Configuration complete ($successCount/$totalTargets configuration(s) ready)."
    Write-Host "  You can now launch Brave Origin without purchase prompts." -ForegroundColor DarkGray
}
Write-Host ""
