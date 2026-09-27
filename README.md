<div align="center"> 
<picture>
    <source
      width="128px"
      media="(prefers-color-scheme: dark)"
      srcset="assests/images/Brave-origin-Unlocker-Light.svg"
    />
    <img 
      width="128px"
      src="assests/images/Brave-origin-Unlocker-Dark.svg"/>
</picture>

# Brave Origin Unlocker (Windows)
**Because a $60 paywall for a stripped-down browser on Windows that is literally free on Linux is absurd.**
</div>

---

### What is this?
Brave charges a $60 buyout for "Brave Origin" on Windows (a clean Brave build stripped of crypto wallets, VPN promos, and AI bloat). Meanwhile, the exact same build is completely free on Linux.

The punchline? The Windows paywall check is literally a client-side flag (`purchase_validated: true`) stored inside a local plaintext JSON file (`Local State`). 

This script flips that flag, injects the SKU credentials, preserves your existing profile data without corruption (no UTF-8 BOM garbage, no depth truncation), and runs 100% offline. No Node.js. No Deno. No compilers. Just native PowerShell.

---

## ⚡ Quick Run (One-Liner)

Open any PowerShell terminal (standard user or Admin) and run:

```powershell
iex (iwr -Uri "https://raw.githubusercontent.com/mrdarksidetm/Brave-Origin-Unlocker-Windows/main/scripts/unlocker.ps1" -UseBasicParsing).Content
```

*Auto-detects installed channels, backs up your config to `.bak`, closes locked browser processes cleanly, and applies the unlock patch.*

---

## 🛠️ CLI Parameters & Power-User Flags

Want more control than blind one-click execution? Run `unlocker.ps1` with dedicated switches:

```powershell
.\unlocker.ps1 [-Channel <Release|Beta|Nightly|All>] [-Force] [-Install] [-UserDataPath <path>] [-Restore] [-NoBackup]
```

| Parameter | Type | Default | What it does |
| :--- | :--- | :--- | :--- |
| **`-Channel`** | `String` | `"All"` | Target specific channels (`Release`, `Beta`, `Nightly`, or `All`). Won't create dummy ghost directories for versions you don't even have installed. |
| **`-Force`** | `Switch` | `False` | Kills running `brave.exe` processes without prompting so file locks are cleared immediately. |
| **`-Install`** | `Switch` | `False` | No Brave Origin found? Pulls the official installer directly from Brave's CDN (no rate-limit traps) and kicks off setup. |
| **`-UserDataPath`** | `String` | `None` | Got a portable install or custom profile on a USB stick? Point directly to your `User Data` folder or `Local State` file. |
| **`-Restore`** | `Switch` | `False` | Instant rollback. Restores original `Local State` from `.bak` backup files if you ever want to revert. |
| **`-NoBackup`** | `Switch` | `False` | Live dangerously. Skips writing `.bak` files before applying modifications. |

---

### Real-World Examples

```powershell
# Standard: Detect whatever Brave Origin channels you have installed and unlock them
.\unlocker.ps1

# The "Just do it": Kill active browser instances automatically and patch
.\unlocker.ps1 -Force

# Rollback: Revert everything back to how it was before running the patch
.\unlocker.ps1 -Restore

# Portable mode: Target an isolated build on an external drive
.\unlocker.ps1 -UserDataPath "E:\PortableApps\Brave-Origin\User Data"

# Missing the browser? Download, install, and unlock in one command
.\unlocker.ps1 -Install -Force
```

---

## ⚠️ Reality Check
If Brave eventually shifts license verification server-side or ties it to cloud accounts, this local patch won't work anymore. Until they do, enjoy not paying $60 for a config flag.

Use at your own discretion. Provided 'as is' without warranties.

---

## License
© [Abhijeet Yadav](https://github.com/mrdarksidetm) 2026 | Licensed under the [MIT License](LICENSE)
