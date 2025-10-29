# YLMassRemove

YLMassRemove is an advanced, customizable PowerShell module and CLI for aggressive app removal, UWP uninstallation, Windows Update rollback, registry and filesystem cleanup, and reportable dry-run operations. Built for power users and administrators who want full control over uninstall logic, logging, and deep system sweeps.

---

## Table of contents
1. Overview
2. Features
3. Requirements
4. Quick installation
5. Persistent aliases
6. Usage and examples
7. Command reference (exported functions & aliases)
8. Logging, dry-run, and reports
9. Safety and permissions
10. Manifest summary (.psd1)
11. Development and contribution
12. License
13. Contact and project links

---

## Overview
YLMassRemove packages a broad set of removal tools in a single module:
- Single-app uninstall flows with deep-clean options
- Stubborn/uncooperative app removal (single and bulk)
- UWP package removal and mass-UWP flows
- Targeted Windows update uninstall and system update helpers
- Mass removal with pipeline support, concurrency, and reporting
- A dynamic help viewer (YL-Help) and full comment-based help for every exported command
- Convenience wrappers and backward-compatible aliases to preserve older scripts

---

## Features
- Deep removal for Win32 and UWP applications
- Stubborn removal tooling:
  - `Stubborn-Uninstall` (single)
  - `MassStubborn-Uninstall` (bulk)
- Mass removal utilities with pipeline input and concurrency (`Mass-Remove`, `MassUWP-Uninstall`)
- Update management:
  - `Uninstall-Update` (targeted update uninstall)
  - `Update-ALL` (update helper)
- Dry-run simulation with `-DryRun` and rich logging
- Per-item and aggregated reporting (CSV / JSON)
- Robust safety flags: `-WhatIf`, `-Confirm`, `-DryRun`, `-Nuke`
- YL-Help: dynamic, searchable help viewer with examples
- Backward-compatible convenience wrappers and aliases:
  - `rm-app`, `rm-bulk`, `rmhard-app`, `rmhard-bulk`, `rm-uwp`, `rm-uwpbulk`, `ls-progs`, `uptodate`, `yl-hlp32`
- Pipeline friendly and supports ValueFromPipeline where relevant
- Optional concurrency controls for bulk operations
- Exportable logs and reports for auditing

---

## Requirements
- PowerShell 7 or later recommended for Publish-Module and modern module support
- Module metadata targets PowerShell 5.1 for full feature support
- Compatible with Desktop and Core editions of PowerShell
- Administrative privileges are required for deep system changes (uninstalling system-scoped apps, registry sweeps, stopping services, removing drivers)

---

## Flags
-DryRun: Simulates what the cmdlet does
-WhatIf: Same as -DryRun but more detailed
-Force: Does the cmdlet commands powerfully/forcefully
-Search: Searches through manually chosen paths (e.g., -Search:D:\Apps\Backup,C:\ProgramData,"C:\Windows\Installer") & allows up to 38 locations to search
-Cleanup: Searches Services, Registry Leftovers & Task Scheduler
-Recurse: Paired best with -Cleanup, recurses through specified paths
-Confirm: Confirms the option if it's dangerous
-Help: Shows info about the cmdlet
-Nuke: Combines -Recurse, -Confirm, -Force, -Erase & Cleanup
-Erase: Securely erases folders, files, & registry leftovers
-ExportHelpAs(Html/csv/md/txt/<CUSTOM_EXT>): Exports the help for that specific cmdlet or alias, or flag in a readable, understandable way

---

## Installation

- You can install our Module through the [PSGallery](https://www.powershellgallery.com) by using this command in an administrative powershell window:

```Install-Module -Name YLMassRemove -Scope AllUsers```

- If this doesn't work run this command in the same administrative powershell window:

```Set-ExecutionPolicy Bypass -Scope Process```

- Then run the same `Install-Module` command above

---

## Usage and examples

Basic listing:
```powershell
# List apps with a filter and include UWP packages
List-Apps -Filter "Zoom" -IncludeUWP
```

Single stubborn uninstall:
```powershell
# Direct cmdlet
Stubborn-Uninstall -Name "McAfee" -Nuke -Cleanup -Nuke

# Convenience wrapper (alias)
rmhard-app -Name "McAfee" -Nuke -Cleanup -Nuke
```

Bulk stubborn uninstall (pipeline-friendly):
```powershell
# Direct
"McAfee","Zoom" | MassStubborn-Uninstall -Nuke -Cleanup -Nuke

# Alias
"McAfee","Zoom" | rmhard-bulk -Nuke -Cleanup -Nuke
```

Mass removal simulation and export:
```powershell
Get-Content apps.txt | rm-bulk -DryRun | Export-Csv removed-sim.csv -NoTypeInformation
```

Uninstall a Windows update:
```powershell
Uninstall-Update -KB "KB5000802" -WhatIf
```

View built-in help with dynamic viewer:
```powershell
YL-Help -Name Stubborn-Uninstall
# or using alias if configured
usage
```

Concurrency example (if supported by your environment):
```powershell
"App1","App2","App3" | Mass-Remove -Concurrency 4 -DryRun
```

---

## Command reference (exported functions & aliases)

Functions exported:
- App-Uninstall
- Mass-Remove
- Stubborn-Uninstall
- MassStubborn-Uninstall
- UWP-Uninstall
- MassUWP-Uninstall
- List-Apps
- Uninstall-Update
- Update-ALL
- YL-Help

Convenience wrappers and exported functions:
- rm-app
- rm-bulk
- rm-uwp
- rm-uwpbulk
- rm-upd
- rmhard-app
- rmhard-bulk
- ls-progs
- uptodate
- yl-hlp32

Aliases (examples):
- `Set-Alias -Name rmhard-bulk -Value MassStubborn-Uninstall -Scope Global`
- `Set-Alias -Name rmhard-app -Value Stubborn-Uninstall -Scope Global`

See comment-based help for parameter details on each cmdlet:
```powershell
Get-Help Stubborn-Uninstall -Full
```

---

## Logging, dry-run, and reports
- Use `-DryRun` to simulate actions without making changes; output supports CSV/JSON for auditing.
- Logging levels: informational, verbose, warning, error. Use `-Verbose` and `-Debug` for more output.
- Per-item logs can be written to a directory using `-LogPath`.
- Bulk operations optionally aggregate results into a summary report with counts, success/fail lists, and error messages.

Example report export:
```powershell
Mass-Remove -InputObject (Get-Content apps.txt) -DryRun -ExportCsv "removal-sim.csv"
```

---

## Safety and permissions
- Use `-WhatIf` and `-DryRun` liberally before running destructive operations.
- `-Confirm` and `-Nuke` are supported where applicable.
- Administrative rights are required for many operations; run PowerShell as Administrator when performing system-wide removals.
- The module exposes deep-clean and registry-sweeping options—double-check targets before running.

---

## Manifest summary (.psd1)
Key manifest metadata included in the module:
- RootModule: `YLMassRemove.psm1`
- ModuleVersion: `1.0.0`
- GUID: `b7a3f9e2-3e5a-4d9f-9c6f-ylmassremove0001`
- Author: `DoorsPastaLLC` / CompanyName: `Yassin-NRO`
- Description: Aggressive and customizable removal, registry cleanup, UWP uninstallation, update management
- PowerShellVersion: `5.1` (recommended; ensure >= `3.0` for Publish-Module)
- CompatiblePSEditions: `Desktop`, `Core`
- FunctionsToExport: core cmdlets plus convenience wrappers
- AliasesToExport: wrapper aliases for backward compatibility
- Tags: uninstall, cleanup, registry, UWP, update, dryrun, logging, automation
- LicenseUri: MIT
- ProjectUri: GitHub repo link
- HelpInfoURI: README on GitHub

---

## Development and contribution

Contributing guidelines:
1. Fork the repository
2. Create a feature or fix branch
3. Add tests and update examples where applicable
4. Submit a pull request with a clear description and screenshots or logs if relevant

Issue reporting:
- Open an issue for bugs, feature requests, compatibility problems, or documentation improvements.
- Include PowerShell version, OS version, sample command used, expected result, and observed result.

Local development tips:
- Run functions in a development session by dot-sourcing the `.psm1`:
  ```powershell
  . .\YLMassRemove.psm1
  ```
- Use `-WhatIf`/`-DryRun` in tests to avoid destructive changes
- Keep wrappers and aliases consistent with exported function names

---

## License
MIT License  
(c) 2025 Yassin-NRO. All rights reserved.

---

## Contact and project links
- Repository: https://github.com/Yassin-LLC/YLMassRemove-PSModule  
- Project issues and PRs: open on the repo above
- X (Twitter Formerly): [Yassin on X](https://www.x.com/DoorsPastaLLC)

---

Thank you for using YLMassRemove. Use its power responsibly and always validate removal targets before running destructive operations.
