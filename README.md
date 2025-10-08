# YLMassRemove-PSModule

> **an PS-CLI that does an very advanced/customizable uninstallation of Windows Updates, UWPs & Normal apps.**

YLMassRemove-PSModule is a powerful PowerShell CLI module designed to provide advanced, flexible, and batch uninstallation capabilities for Windows systems. This tool streamlines the removal of Windows Updates, Universal Windows Platform (UWP) apps, and traditional installed applications, with extensive customization and automation options.

---

## 🚀 Features

- **Batch Uninstallation:** Remove multiple Windows Updates, UWP apps, and normal programs in a single operation.
- **Advanced Customization:** Choose which updates or apps to target, set filters, and define exclusion lists.
- **Comprehensive Logging:** Track all actions with verbose logs for auditing and troubleshooting.
- **Safety Controls:** Includes dry-run, confirmation prompts, and rollback options to avoid accidental removals.
- **Automation Ready:** Scriptable interface for IT admins and power users, ideal for mass deployments or system maintenance.
- **Cross-Compatibility:** Works on Windows 10/11 with PowerShell 5.x and above.

---

## 📦 Installation

### Prerequisites

- **Windows** 10/11
- **PowerShell** 5.1 or later (including PowerShell Core)
- Administrative privileges

### Install via PowerShell Gallery

```powershell
Install-Module -Name YLMassRemove -Scope AllUsers
```

### Manual Installation

Clone the repository and import the module:

```powershell
git clone https://github.com/Yassin-LLC/YLMassRemove-PSModule.git
Import-Module ./YLMassRemove-PSModule/YLMassRemove-PSModule.psm1
```

---

## ⚡ Usage

### Uninstall Windows Updates

```powershell
# List all installed updates
Get-YLInstalledUpdates

# Uninstall selected KB updates
Remove-YLWindowsUpdate -KBList "KB5005565","KB5016616"
```

### Remove UWP Apps

```powershell
# List all UWP apps
Get-YLUWPApps

# Remove specified UWP apps
Remove-YLUWPApps -AppNames "Microsoft.XboxApp","Microsoft.SkypeApp"
```

### Uninstall Normal Applications

```powershell
# List installed programs
Get-YLInstalledPrograms

# Batch uninstall by name
Remove-YLPrograms -ProgramNames "7-Zip","Adobe Reader"
```

### Advanced Options

- **Dry Run:** Preview what will be uninstalled without making changes.
- **Exclude List:** Protect specific updates or apps from removal.
- **Verbose Logging:** See detailed output for every operation.

---

## 🛡️ Safety & Recovery

- **Confirmation Prompts:** Prevents accidental data loss.
- **Rollback Support:** Logs allow manual recovery or reinstallation if needed.
- **Filter & Exclude:** Fine-tune what gets removed.

---

## 💡 Example Scripts

```powershell
# Uninstall all updates from a specific month
Remove-YLWindowsUpdate -FilterDate "2024-06"

# Remove all UWP games except protected ones
Remove-YLUWPApps -Category "Games" -Exclude "Microsoft.MinecraftUWP"

# Fully automate removal with no prompts
Remove-YLPrograms -ProgramNames "FooApp" -Force
```

---

## 📝 Documentation

- [Usage Guide](docs/USAGE.md)
- [Command Reference](docs/COMMANDS.md)
- [FAQ](docs/FAQ.md)

---

## 💬 Support

- [GitHub Issues](https://github.com/Yassin-LLC/YLMassRemove-PSModule/issues)
- [Discussions](https://github.com/Yassin-LLC/YLMassRemove-PSModule/discussions)

---

---

## 📄 License

MIT License – see [LICENSE](LICENSE) for details.

---

## 🏆 Credits

Developed by [Yassin-LLC](https://github.com/Yassin-LLC).
