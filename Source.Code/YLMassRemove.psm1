<#
.SYNOPSIS
YLMassRemove core module implementation.

.DESCRIPTION
This module contains enhanced, robust, and well-documented cmdlets for
mass removal tasks, UWP management, update handling, listing, and a
dynamic help system (YL-Help). The module emphasizes safety (Confirm,
WhatIf), logging, dry-run modes, and clear, descriptive help output.

.NOTES
Author: DoorsPastaLLC
Module: YLMassRemove
Version: 3.5.0.1
#>

#region Module initialization and shared helpers

# Module-wide variables
Set-Variable -Name YL_ModuleLoadedAt -Value (Get-Date) -Scope Script -Option ReadOnly,AllScope
Set-Variable -Name YL_DefaultLogPath -Value (Join-Path $env:ALLUSERSPROFILE 'YLMassRemove\ylmassremove.log') -Scope Script -Option ReadOnly,AllScope
Set-Variable -Name YL_EnableVerboseLog -Value $false -Scope Script -Option AllScope
Set-Variable -Name YL_CommandRegistry -Value @{} -Scope Script

# Ensure log directory exists
$logDir = Split-Path -Path $YL_DefaultLogPath -Parent
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

function Write-YLLog {
<#
.SYNOPSIS
Write an entry to the module log.

.PARAMETER Message
Message to write.

.PARAMETER Level
Log level - INFO, WARN, ERROR, DEBUG.

.PARAMETER NoConsole
Suppress console output.

.DESCRIPTION
Writes timestamped log entries to default log path and optionally to console.
#>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('INFO','WARN','ERROR','DEBUG')]
        [string]$Level = 'INFO',

        [switch]$NoConsole
    )
    $time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $entry = "$time [$Level] $Message"
    try {
        Add-Content -Path $YL_DefaultLogPath -Value $entry -ErrorAction Stop
    } catch {
        # If writing log fails, attempt to create file
        New-Item -Path $YL_DefaultLogPath -ItemType File -Force | Out-Null
        Add-Content -Path $YL_DefaultLogPath -Value $entry
    }
    if (-not $NoConsole) {
        switch ($Level) {
            'ERROR' { Write-Host $entry -ForegroundColor Red }
            'WARN'  { Write-Host $entry -ForegroundColor Yellow }
            'DEBUG' { if ($YL_EnableVerboseLog) { Write-Host $entry -ForegroundColor Gray } }
            default { Write-Host $entry -ForegroundColor Cyan }
        }
    }
}

function Get-YLModuleFunctionSignatures {
<#
.SYNOPSIS
Return a registry of exported functions and help descriptions.

.DESCRIPTION
Used by YL-Help to present structured information about available cmdlets.
#>
    param()
    $registry = @{}
    $currentExports = Get-Command -Module YLMassRemove -ErrorAction SilentlyContinue | Where-Object { $_.CommandType -eq 'Function' }
    foreach ($cmd in $currentExports) {
        $help = Get-Help $cmd.Name -ErrorAction SilentlyContinue
        $short = if ($help) { ($help.Synopsis) } else { '' }
        $params = @{}
        try {
            $paramInfo = (Get-Command $cmd.Name).Parameters
            foreach ($p in $paramInfo.GetEnumerator()) {
                $params[$p.Key] = @{
                    Type = $p.Value.ParameterType.Name
                    Mandatory = $p.Value.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | ForEach-Object { $_.Mandatory }
                }
            }
        } catch { }
        $registry[$cmd.Name] = @{
            Synopsis = $short
            Parameters = $params
        }
    }
    return $registry
}

# Helper to ensure pipeline input handling in cmdlets
function ConvertTo-ArrayOfObjects {
    param(
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    process {
        if ($null -eq $InputObject) { return }
        elseif ($InputObject -is [System.Array]) { $InputObject }
        else { ,$InputObject }
    }
}

#endregion

#region Common parameter sets and helpers for operations

function Invoke-YLSafeAction {
<#
.SYNOPSIS
Wrapper for safe execution of destructive actions with support for -WhatIf, -Confirm, DryRun and logging.

.PARAMETER Action
ScriptBlock representing destructive action.

.PARAMETER Description
Human readable description for logs and confirmation prompts.

.PARAMETER ConfirmPreference
If set, will prompt using ShouldProcess and ShouldContinue patterns.

.PARAMETER DryRun
If set, action is not executed.

.PARAMETER Force
If set, bypass confirmations.

.DESCRIPTION
Centralizes confirmation, WhatIf, and dry-run behavior for module cmdlets.
#>
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$Action,

        [string]$Description = 'Perform action',

        [switch]$DryRun,

        [switch]$Force
    )

    # Use ShouldProcess for PowerShell standardized confirmation
    $supportsShouldProcess = $PSCmdlet.ShouldProcess($Description)
    if ($DryRun) {
        Write-YLLog -Message "DRYRUN: $Description" -Level 'INFO'
        return $true
    }
    if ($Force -or $PSCmdlet.ShouldProcess($Description)) {
        try {
            & $Action
            Write-YLLog -Message "SUCCESS: $Description" -Level 'INFO'
            return $true
        } catch {
            Write-YLLog -Message "FAILED: $Description - $_" -Level 'ERROR'
            throw
        }
    } else {
        Write-YLLog -Message "SKIPPED: $Description (user declined)" -Level 'WARN'
        return $false
    }
}

#endregion

#region Exported functions with enhanced behavior

function App-Uninstall {
<#
.SYNOPSIS
Uninstall a Windows application by name, package, or MSI product code.

.DESCRIPTION
Attempts multiple strategies to uninstall an application:
- Uses Get-WmiObject / Get-CimInstance to find uninstall strings
- Uses Start-Process with uninstall command for classic apps
- Uses Remove-AppxPackage for UWP apps when required
- Supports -WhatIf, -Confirm and -DryRun
- Provides verbose, progress and logging

.PARAMETER Name
Name or partial name of application to uninstall.

.PARAMETER MsiProductCode
MSI product code GUID to uninstall.

.PARAMETER Recurse
Attempt to remove associated files and registry entries.

.PARAMETER DryRun
Simulate actions without performing them.

.PARAMETER Force
Bypass confirmations.

.PARAMETER Confirm
Standard -Confirm switch.

.EXAMPLE
App-Uninstall -Name "7-Zip" -Recurse
#>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Name,

        [Parameter(Mandatory=$false)]
        [ValidatePattern('^\{?[0-9A-Fa-f\-]{36}\}?$')]
        [string]$MsiProductCode,

        [switch]$Recurse,

        [switch]$DryRun,

        [switch]$Force
    )

    begin {
        Write-YLLog -Message "App-Uninstall invoked; Name=$Name; MsiProductCode=$MsiProductCode; Recurse=$Recurse" -Level 'DEBUG'
    }
    process {
        if ($MsiProductCode) {
            $desc = "Uninstall MSI product $MsiProductCode"
            Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                $msiexec = "$env:SystemRoot\System32\msiexec.exe"
                $args = "/x $MsiProductCode /qn /norestart"
                Start-Process -FilePath $msiexec -ArgumentList $args -Wait -NoNewWindow
            }
            return
        }

        if (-not $Name) {
            Write-YLLog -Message "No Name or MsiProductCode provided to App-Uninstall" -Level 'WARN'
            Write-Warning "Provide -Name or -MsiProductCode"
            return
        }

        # Search in registry for uninstall strings
        $uninstallEntries = @()
        $hives = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
        foreach ($h in $hives) {
            try {
                $items = Get-ChildItem -Path $h -ErrorAction SilentlyContinue
                foreach ($it in $items) {
                    $displayName = (Get-ItemProperty -Path $it.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName
                    if ($displayName -and ($displayName -like "*$Name*")) {
                        $entry = Get-ItemProperty -Path $it.PSPath -ErrorAction SilentlyContinue
                        $uninstallEntries += [PSCustomObject]@{
                            Name = $displayName
                            UninstallString = $entry.UninstallString
                            RegistryKey = $it.PSPath
                        }
                    }
                }
            } catch { }
        }

        if (-not $uninstallEntries) {
            # Try using Get-Package (PackageManagement)
            try {
                $pkgs = Get-Package -Name "*$Name*" -ErrorAction SilentlyContinue
                foreach ($p in $pkgs) {
                    $uninstallEntries += [PSCustomObject]@{
                        Name = $p.Name
                        ProviderName = $p.ProviderName
                        Version = $p.Version
                        Package = $p
                    }
                }
            } catch { }
        }

        if (-not $uninstallEntries) {
            # Try UWP
            $uwpMatches = Get-AppxPackage -Name "*$Name*" -ErrorAction SilentlyContinue
            foreach ($u in $uwpMatches) {
                $uninstallEntries += [PSCustomObject]@{
                    Name = $u.Name
                    PackageFullName = $u.PackageFullName
                    IsUWP = $true
                }
            }
        }

        if (-not $uninstallEntries) {
            Write-YLLog -Message "No application matched name '$Name'" -Level 'WARN'
            Write-Warning "No installed application matched name '$Name'"
            return
        }

        foreach ($entry in $uninstallEntries) {
            if ($entry.IsUWP) {
                $desc = "Remove UWP package $($entry.PackageFullName)"
                Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                    Remove-AppxPackage -Package $entry.PackageFullName -ErrorAction Stop
                }
                continue
            }

            if ($entry.UninstallString) {
                $uStr = $entry.UninstallString
                # Clean uninstall string if it's quoted or has arguments
                $exe, $args = if ($uStr -match '^(["'']?)(.+?)(?:["'']?)\s*(.*)$') { @($matches[2], $matches[3]) } else { @($uStr, '') }
                $desc = "Execute uninstall command for $($entry.Name)"
                Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                    if ($exe -like '*.msi' -or $exe -match 'msiexec') {
                        # Use silent uninstall switch if possible
                        if ($exe -match 'msiexec') {
                            Start-Process -FilePath $exe -ArgumentList $args -Wait -NoNewWindow
                        } else {
                            Start-Process -FilePath 'msiexec.exe' -ArgumentList "/x `"$exe`" /qn /norestart" -Wait -NoNewWindow
                        }
                    } else {
                        Start-Process -FilePath $exe -ArgumentList $args -Wait -NoNewWindow
                    }
                }
            } elseif ($entry.Package) {
                $desc = "Uninstall package via provider $($entry.ProviderName) for $($entry.Name)"
                Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                    Uninstall-Package -InputObject $entry.Package -Force
                }
            } else {
                Write-YLLog -Message "Unknown uninstall path for entry: $entry" -Level 'WARN'
            }

            if ($Recurse) {
                # Attempt to remove associated folders in Program Files and registry keys
                $progPaths = @(
                    Join-Path $env:ProgramFiles $entry.Name,
                    Join-Path $env:ProgramFiles "($($entry.Name))",
                    Join-Path $env:ProgramFilesX86 $entry.Name
                ) | Where-Object { Test-Path $_ }
                foreach ($p in $progPaths) {
                    $desc = "Remove folder $p"
                    Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                        Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
                    }
                }
                # Additional registry cleanup (best effort, non-recursive)
                try {
                    $regKey = $entry.RegistryKey
                    if ($regKey) {
                        $desc = "Remove registry key $regKey"
                        Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                            Remove-Item -Path $regKey -Recurse -Force -ErrorAction Stop
                        }
                    }
                } catch { }
            }
        }
    }
    end {
        Write-YLLog -Message "App-Uninstall completed" -Level 'DEBUG'
    }
}
Export-ModuleMember -Function App-Uninstall

function Mass-Remove {
<#
.SYNOPSIS
Batch remove applications by list or pattern.

.DESCRIPTION
Accepts pipeline input or -InputObject list of names to remove. Wraps App-Uninstall
with concurrency control, logging, dry-run, and a summary report at completion.

.PARAMETER InputObject
List of application names.

.PARAMETER Concurrency
Number of parallel workers (best-effort using background jobs).

.PARAMETER DryRun
Simulate removal without performing it.

.PARAMETER Force
Bypass confirmations.

.EXAMPLE
'7-Zip','Notepad++' | Mass-Remove -Concurrency 2 -DryRun
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$InputObject,

        [ValidateRange(1,16)]
        [int]$Concurrency = 2,

        [switch]$DryRun,

        [switch]$Force
    )

    begin {
        $items = @()
        Write-YLLog -Message "Mass-Remove start; Concurrency=$Concurrency; DryRun=$DryRun" -Level 'INFO'
    }
    process {
        foreach ($i in $InputObject) { $items += $i }
    }
    end {
        if (-not $items) { Write-Warning "No items provided to Mass-Remove"; return }
        $jobs = @()
        foreach ($name in $items) {
            $script = {
                param($n,$dry,$force)
                Import-Module (Split-Path -Parent $MyInvocation.MyCommand.Definition) -Force
                App-Uninstall -Name $n -DryRun:$dry -Force:$force
            }
            $jobs += Start-Job -ScriptBlock $script -ArgumentList @($name, $DryRun.IsPresent, $Force.IsPresent)
            while ($jobs.Count -ge $Concurrency) {
                $done = Wait-Job -Job $jobs -Any -Timeout 1
                $jobs = $jobs | Where-Object { $_.State -eq 'Running' }
            }
        }
        # Wait for remaining
        if ($jobs) { Wait-Job -Job $jobs }
        foreach ($j in $jobs) { Receive-Job -Job $j -ErrorAction SilentlyContinue | Out-Null; Remove-Job -Job $j -Force -ErrorAction SilentlyContinue }
        Write-YLLog -Message "Mass-Remove finished for items: $($items -join ', ')" -Level 'INFO'
    }
}
Export-ModuleMember -Function Mass-Remove

function Stubborn-Uninstall {
<#
.SYNOPSIS
Forceful removal attempts for stubborn or partially uninstalled applications.

.DESCRIPTION
Tries several strategies and escalations:
- Attempts App-Uninstall first
- Kills processes holding files
- Removes leftover files and registry keys
- Uses msiexec /x where applicable
- Generates a detailed report in $env:TEMP on completion

.PARAMETER Name
Application name or partial name.

.PARAMETER KillProcesses
Kill processes matching the application name.

.PARAMETER DeepClean
Attempt aggressive file and registry deletion.

.PARAMETER DryRun
Simulate actions.

.PARAMETER Force
Bypass confirmations.

.EXAMPLE
Stubborn-Uninstall -Name "SomeApp" -KillProcesses -DeepClean -Force
#>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,

        [switch]$KillProcesses,

        [switch]$DeepClean,

        [switch]$DryRun,

        [switch]$Force
    )

    begin {
        $report = [System.Collections.Generic.List[psobject]]::new()
        $reportFile = Join-Path $env:TEMP ("YLMassRemove_StubbornReport_{0}.txt" -f ([guid]::NewGuid().ToString()))
        Write-YLLog -Message "Stubborn-Uninstall starting for $Name" -Level 'INFO'
    }
    process {
        # First, call App-Uninstall to try standard removal
        App-Uninstall -Name $Name -DryRun:$DryRun -Force:$Force

        if ($KillProcesses) {
            $procs = Get-Process | Where-Object { ($_.ProcessName -like "*$Name*") -or ($_.Path -and ($_.Path -like "*$Name*")) } -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                $desc = "Kill process $($p.ProcessName) (PID $($p.Id))"
                Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                    Stop-Process -Id $p.Id -Force -ErrorAction Stop
                }
                $report.Add([pscustomobject]@{ Action='KilledProcess'; Process=$p.ProcessName; PID=$p.Id })
            }
        }

        if ($DeepClean) {
            # Attempt to find typical install locations and remove them
            $possiblePaths = @(
                Join-Path $env:ProgramFiles $Name,
                Join-Path $env:ProgramFilesX86 $Name,
                Join-Path $env:LOCALAPPDATA $Name,
                Join-Path $env:PROGRAMDATA $Name
            ) | Where-Object { Test-Path $_ }

            foreach ($p in $possiblePaths) {
                $desc = "Deep remove folder $p"
                Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                    Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
                }
                $report.Add([pscustomobject]@{ Action='RemovedFolder'; Path=$p })
            }

            # Registry cleanup best-effort
            $regPaths = @(
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
            )
            foreach ($r in $regPaths) {
                try {
                    $keys = Get-ChildItem -Path $r -ErrorAction SilentlyContinue
                    foreach ($k in $keys) {
                        $props = Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue
                        if ($props.DisplayName -and ($props.DisplayName -like "*$Name*")) {
                            $desc = "Remove registry key $($k.PSPath)"
                            Invoke-YLSafeAction -Description $desc -DryRun:$DryRun -Force:$Force -Action {
                                Remove-Item -Path $k.PSPath -Recurse -Force -ErrorAction Stop
                            }
                            $report.Add([pscustomobject]@{ Action='RemovedRegistry'; Key=$k.PSPath })
                        }
                    }
                } catch { }
            }
        }

        # Save report
        $report | Out-File -FilePath $reportFile -Force -Encoding UTF8
        Write-YLLog -Message "Stubborn-Uninstall report saved to $reportFile" -Level 'INFO'
        Write-Host "Report: $reportFile"
    }
    end {
        Write-YLLog -Message "Stubborn-Uninstall complete for $Name" -Level 'INFO'
    }
}
Export-ModuleMember -Function Stubborn-Uninstall

function UWP-Uninstall {
<#
.SYNOPSIS
Uninstall a UWP app by name or package full name.

.DESCRIPTION
Removes Appx packages for current user or all users depending on parameters.
Supports -WhatIf, -Confirm, and -DryRun.

.PARAMETER Name
Partial name match for app package.

.PARAMETER PackageFullName
Exact package full name.

.PARA
