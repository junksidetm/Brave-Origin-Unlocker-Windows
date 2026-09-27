# Legal, Interoperability & Compliance Notice

This repository provides an open-source profile configuration utility for Windows. Before interacting with this repository, review the following legal disclosures, statutory exemptions, and licensing declarations.

---

### 1. Nominative Fair Use & Trademark Disclaimer
- **Trademark Ownership**: "Brave", "Brave Origin", the Brave lion emblem, and associated logos are registered trademarks of **Brave Software Inc.**
- **Identification Only**: Any names, logos, silhouettes, or modified badge assets appearing in this repository are utilized strictly for descriptive and nominative identification purposes under the **Nominative Fair Use doctrine** (*New Kids on the Block v. News America Publ'g, Inc.*, 971 F.2d 302, 9th Cir. 1992; *Toyota Motor Sales, U.S.A., Inc. v. Tabari*, 610 F.3d 1171, 9th Cir. 2010).
- **Non-Affiliation**: This project is completely independent. It is **not** affiliated with, authorized by, endorsed by, sponsored by, or in any way officially connected with Brave Software Inc. or any of its subsidiaries.

---

### 2. Dual-Use Doctrine & Non-Infringing Utility (*Sony Betamax*)
Under the landmark U.S. Supreme Court precedent *Sony Corp. of America v. Universal City Studios, Inc.*, 464 U.S. 417 (1984), a technology or utility cannot be classified as unlawful if it is capable of **substantial non-infringing uses**:
- **Offline Configuration & Profile Management**: Automates local profile state configuration for sysadmins and developers configuring offline environments without active network telemetry.
- **Portability Support**: Facilitates portable USB and custom directory installations where default operating system registration hooks are unavailable.
- **Diagnostics & Testing**: Enables developers to test and verify application behavior across Release, Beta, and Nightly channels under simulated license states.

---

### 3. DMCA Section 1201 Statutory Exemptions (17 U.S.C. § 1201)
- **17 U.S.C. § 1201(f) (Reverse Engineering for Interoperability)**:
  Explicitly permits the analysis and modification of computer programs to achieve interoperability of an independently created computer program with other programs, provided the information has not previously been readily available.
- **Absence of an "Effective Technological Measure"**:
  Under *Lexmark Int'l, Inc. v. Static Control Components, Inc.*, 387 F.3d 522 (6th Cir. 2004), an unencrypted, plaintext configuration file (`Local State`) stored locally on the user's personal filesystem does not constitute an *"effective technological protection measure"* (TPM). The script does not decrypt ciphertext, defeat cryptographic handshakes, forge digital signatures, or crack compiled binary executables.
- **17 U.S.C. § 1201(g) (Encryption and Security Research)**:
  Protects research and documentation analyzing how local client applications validate and persist security tokens and state attributes.

---

### 4. European Union Statutory Protection (Directive 2009/24/EC)
For users and contributors within the European Union:
- **Article 5(3)** of Directive 2009/24/EC explicitly protects the right of a lawful user to determine the ideas and principles which underlie any element of a computer program while performing operations that the user is entitled to perform (e.g., loading and running local software).
- **Article 6 (Decompilation & Interoperability)** guarantees the right to achieve interoperability between software programs, which cannot be overridden or restricted by private End-User License Agreements (EULAs).

---

### 5. Open-Source Provenance (MPL 2.0 & Chromium BSD)
The underlying browser engine and application architecture of Brave are open-source software:
- Upstream source code repository: [`brave/brave-core`](https://github.com/brave/brave-core) and [`brave/brave-browser`](https://github.com/brave/brave-browser).
- Licensed under the **Mozilla Public License 2.0 (MPL 2.0)** and Chromium's **3-Clause BSD License**.
- Brave Origin on Linux is officially compiled and distributed by Brave Software Inc. without paywall mechanisms. Under the MPL 2.0, any developer has the legal right to inspect, modify, and compile the source code directly for Windows or any other platform.

---

### 6. DMCA Counter-Notice Procedure
In the event that a DMCA § 512 or § 1201 notice is submitted against this repository:
- The maintainer reserves the statutory right under **17 U.S.C. § 512(g)** to file a formal Counter-Notification certifying a good-faith belief that the material was removed or disabled as a result of mistake, misidentification, or statutory exemption under § 1201(f) and the *Lexmark* precedent.
- Contributors and fork maintainers are encouraged to maintain decentralized mirrors (e.g., via Codeberg or local Git bundles) to prevent unilateral, centralized censorship.

---

### Disclaimer
This software is provided "as is", without warranty of any kind, express or implied. In no event shall the authors or copyright holders be held liable for any claim, damages, or other liability arising from the use or execution of this software.
