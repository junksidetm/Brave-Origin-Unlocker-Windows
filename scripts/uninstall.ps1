<#
.SYNOPSIS
    Brave Origin Clean Slate & Complete Uninstaller for Windows.

.DESCRIPTION
    Completely uninstalls Brave Origin applications, user profiles, caches,
    shortcuts, and registry entries across all channels (Release, Beta, Nightly).
    Leaves the Windows environment in a clean slate as if it was never installed.

.PARAMETER Channel
    Target channel to remove: 'Release', 'Beta', 'Nightly', or 'All'.
    Default: 'All'.

.PARAMETER Force
    Silently forces process termination and uninstallation without interactive prompts.

.EXAMPLE
    .\uninstall.ps1
    Prompts for confirmation and completely uninstalls Brave Origin and deletes all data.

.EXAMPLE
    .\uninstall.ps1 -Force
    Uninstalls Brave Origin immediately without confirmation.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet("Release", "Beta", "Nightly", "All")]
    [string]$Channel = "All",

    [switch]$Force
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

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   Brave Origin Complete Clean Slate (Windows)        " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Confirm action unless force flag is specified
if (-not $Force) {
    Write-Log -Level WARN "This will permanently remove Brave Origin applications, user profiles, caches, and shortcuts."
    if ([Environment]::UserInteractive) {
        $confirm = Read-Host "Are you sure you want to proceed with complete removal? (y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Log -Level INFO "Uninstallation cancelled by user."
            return
        }
    }
}

# 1. Terminate running Brave Origin instances
$braveProcs = Get-Process -Name "brave" -ErrorAction SilentlyContinue | Where-Object {
    try {
        $_.Path -like "*Brave-Origin*" -or $_.Path -like "*BraveSoftware\Brave-Origin*"
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

# Determine target channels
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

    # 2. Run official silent uninstaller if present
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
                    $proc = Start-Process -FilePath $installer.FullName -ArgumentList "--uninstall", "--force-uninstall", "--delete-profile" -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 1
                } catch {
                    # Continue with directory wipe
                }
            }
        }
    }

    # 3. Force-remove Application & User Data directories
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

    # 4. Remove Shortcuts (Desktop, Start Menu, Taskbar)
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

    # 5. Remove Registry Keys
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

    # Purge Uninstall Registry Entries
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

# Clean BraveSoftware parent directory if empty
if ((Test-Path "$env:LOCALAPPDATA\BraveSoftware") -and ((Get-ChildItem -Path "$env:LOCALAPPDATA\BraveSoftware" -ErrorAction SilentlyContinue).Count -eq 0)) {
    Remove-Item -Path "$env:LOCALAPPDATA\BraveSoftware" -Force -ErrorAction SilentlyContinue
}

# 6. Purge Temp & Installer leftovers
$tempInstallers = Get-ChildItem -Path $env:TEMP -Filter "*BraveOriginSetup*.exe" -ErrorAction SilentlyContinue
foreach ($ti in $tempInstallers) {
    Remove-Item -Path $ti.FullName -Force -ErrorAction SilentlyContinue
}
Remove-Item -Path "$env:TEMP\brave_installer*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[✔] Clean slate restored. All Brave Origin data, applications, and shortcuts completely removed." -ForegroundColor Green
Write-Host ""
