<div align="center"> 
<picture>
    <source
      width="128px"
      media="(prefers-color-scheme: dark)"
      srcset="assests/images/Brave-origin-Profile-Light.svg"
    />
    <img 
      width="128px"
      src="assests/images/Brave-origin-Profile-Dark.svg"/>
</picture>

# Brave Origin Profile Manager & Offline State Utility
**Because a $60 paywall for a stripped-down browser on Windows that is literally free on Linux is absurd.**

<p>
  <a href="#-quick-run-one-liner">Quick Run</a> •
  <a href="#-cli-parameters--power-user-flags">CLI Options</a> •
  <a href="#-the-open-source-reality-mpl-20-loophole">MPL 2.0 Loophole</a> •
  <a href="#-statutory-defense--legal-loopholes">Legal Shield</a> •
  <a href="LEGAL.md">LEGAL.md</a>
</p>

<sub><b>Nominative Fair Use Disclaimer:</b> "Brave" and "Brave Origin" are registered trademarks of Brave Software Inc. Any logos, modified badge assets, or brand names are used strictly for descriptive identification and interoperability purposes under Nominative Fair Use (15 U.S.C. § 1125). This project is independent and is not affiliated with, endorsed by, or sponsored by Brave Software Inc.</sub>
</div>

---

### What is this?
Brave charges a $60 buyout for "Brave Origin" on Windows (a clean Brave build stripped of crypto wallets, VPN promos, and AI bloat). Meanwhile, the exact same build is completely free on Linux.

The punchline? The Windows paywall check is literally a client-side flag (`purchase_validated: true`) stored inside a local plaintext JSON file (`Local State`). 

This script is an open-source **local configuration & profile state manager**. It flips that flag, injects the SKU credentials, preserves your existing profile data without corruption (no UTF-8 BOM garbage, no depth truncation), and runs 100% offline. No Node.js. No Deno. No compilers. Just native PowerShell.

---

## ⚡ Quick Run (One-Liner)

Open any PowerShell terminal (standard user or Admin) and run:

```powershell
iex (iwr -Uri "https://codeberg.org/mrdarksidetm/Brave-Origin-Profile-Windows/raw/branch/main/scripts/profile.ps1" -UseBasicParsing).Content
```

*Auto-detects installed channels, backs up your config to `.bak`, closes locked browser processes cleanly, and applies the configuration patch.*

---

## 🛠️ CLI Parameters & Power-User Flags

Want more control than blind one-click execution? Run `profile.ps1` with dedicated switches:

```powershell
.\profile.ps1 [-Channel <Release|Beta|Nightly|All>] [-Force] [-Install] [-UserDataPath <path>] [-Restore] [-NoBackup]
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
# Standard: Detect whatever Brave Origin channels you have installed and configure them
.\profile.ps1

# The "Just do it": Kill active browser instances automatically and patch
.\profile.ps1 -Force

# Rollback: Revert everything back to how it was before running the patch
.\profile.ps1 -Restore

# Portable mode: Target an isolated build on an external drive
.\profile.ps1 -UserDataPath "E:\PortableApps\Brave-Origin\User Data"

# Missing the browser? Download, install, and configure in one command
.\profile.ps1 -Install -Force
```

---

## 🛡️ Statutory Defense & Legal Loopholes

If you're wondering how this project stands legally, we leverage four established statutory doctrines:

1. **Dual-Use Doctrine (*Sony Betamax* Defense)**:
   Under *Sony Corp. v. Universal City Studios* (1984), a tool cannot be outlawed if it is capable of **"substantial non-infringing uses"**. This utility serves as an offline profile state manager for sysadmins deploying offline enterprise seats, developers simulating testing environments, and portable USB profile users.
2. **DMCA § 1201(f) Interoperability Exemption**:
   17 U.S.C. § 1201(f) explicitly protects reverse engineering and local state modification for the purpose of achieving interoperability of computer programs.
3. **The *Lexmark* Precedent (Plaintext is not a TPM)**:
   Under *Lexmark Int'l v. Static Control Components* (387 F.3d 522), a plaintext, unencrypted JSON file on your own drive does **not** constitute an "effective technological protection measure". No encryption is broken. No binary executables are cracked. No remote servers are breached.
4. **Nominative Fair Use**:
   Modifying the logo colors and adding a badge does not eliminate trademark liability on its own; our use of the trademark is protected under **Nominative Fair Use** (15 U.S.C. § 1125), as it is used strictly to identify the compatible software without claiming endorsement. Full statutory citations are documented in [LEGAL.md](LEGAL.md).

---

## 🐧 The Open-Source Reality (MPL 2.0 Loophole)

Here is the ultimate open-source truth: **Brave's browser engine is completely open-source under MPL 2.0 and Chromium's BSD license.**

On Linux, Brave literally distributes Brave Origin for free. Under the Mozilla Public License 2.0, anyone has the legal right to compile Brave Origin from upstream source code ([`brave/brave-core`](https://github.com/brave/brave-core)) with the `is_brave_origin=true` GN flag for Windows. **Brave cannot DMCA their own open-source code.** What they sell on Windows is merely the convenience of a pre-compiled installer.

---

## 🌐 Anti-Censorship & Decentralized Mirroring

If GitHub ever capitulates to an overreaching takedown notice, this tool cannot be erased. Create your own local, un-censorable git mirror right now:

```powershell
# Create an immutable git bundle of this entire repository
git bundle create brave-origin-profile.bundle --all
```

You can also mirror this repo to decentralized or EU-governed platforms like **Codeberg** (hosted in Germany under Directive 2009/24/EC interoperability protections) or **Radicle**.

---

## ⚠️ Reality Check
If Brave eventually shifts license verification server-side or ties it to cloud accounts, this local patch won't work anymore. Until they do, enjoy not paying $60 for a config flag.

Use at your own discretion. Provided 'as is' without warranties.

---

## License
© [Abhijeet Yadav](https://github.com/mrdarksidetm) 2026 | Licensed under the [MIT License](LICENSE). See [LEGAL.md](LEGAL.md) for statutory disclosures.
