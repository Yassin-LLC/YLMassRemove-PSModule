@{
    # Identity
    RootModule           = 'YLMassRemove.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = 'b7a3f9e2-3e5a-4d9f-9c6f-1a2b3c4d5e6f'
    Author               = 'DoorsPastaLLC'
    CompanyName          = 'Yassin-NRO'
    Copyright            = '(c) 2025 Yassin-NRO'
    Description          = 'YLMassRemove: advanced and customizable uninstaller for Windows Updates, UWP apps, and traditional programs.'

    # Compatibility
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop')

    # Files shipped
    FileList             = @(
        'YLMassRemove.psm1',
        'Help_README.md',
        'LICENSE',
        'Yassin-GitHub.url',
        'YLMassRemove.psd1'
    )

    # Exported members (names only)
    FunctionsToExport    = @(
        'App-Uninstall',
        'Mass-Remove',
        'Stubborn-Uninstall',
        'MassStubborn-Uninstall',
        'UWP-Uninstall',
        'MassUWP-Uninstall',
        'List-Apps',
        'Uninstall-Update',
        'Update-ALL',
        'YL-Help',
        'rm-app',
        'rm-bulk',
        'rm-uwp',
        'rm-uwpbulk',
        'rm-upd',
        'rmhard-app',
        'rmhard-bulk',
        'ls-progs',
        'uptodate',
        'yl-hlp32'
    )

    CmdletsToExport      = @(
        'App-Uninstall',
        'Mass-Remove',
        'Stubborn-Uninstall',
        'MassStubborn-Uninstall',
        'UWP-Uninstall',
        'MassUWP-Uninstall',
        'List-Apps',
        'Uninstall-Update',
        'Update-ALL',
        'YL-Help'
    )

    AliasesToExport      = @(
        'rm-app',
        'rm-bulk',
        'rm-uwp',
        'rm-uwpbulk',
        'rm-upd',
        'rmhard-app',
        'rmhard-bulk',
        'ls-progs',
        'uptodate',
        'yl-hlp32'
    )

    # Dependencies and processing
    RequiredModules      = @('PSWindowsUpdate','NtObjectManager')
    RequiredAssemblies   = @()
    ScriptsToProcess     = @()
    TypesToProcess       = @()
    FormatsToProcess     = @()

    # Allowed metadata keys
    HelpInfoURI          = 'https://github.com/Yassin-LLC/YLMassRemove-PSModule/wiki'
    DefaultCommandPrefix = ''
}
