# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

@{
    RootModule = 'PInvokeHelper.psm1'
    ModuleVersion = '0.2.0'
    GUID = 'c21db2a6-c5f6-4589-b618-babe8d378bfd'
    Author = 'Jordan Borean'
    Copyright = 'Copyright (c) 2019 by Jordan Borean, Red Hat, licensed under MIT.'
    Description = "Contains helper methods that can be used to define PInvoke methods and structs without touching the disk.`nSee https://github.com/jborean93/PInvokeHelper for more info"
    PowerShellVersion = '3.0'
    FunctionsToExport = @(
        'Get-Win32ErrorMessage',
        'Import-Enum',
        'Import-PInvokeMethod',
        'Import-Struct',
        'New-DynamicModule'
    )
    PrivateData = @{
        PSData = @{
            Tags = @(
                "DevOps",
                "PInvoke",
                "Windows"
            )
            LicenseUri = 'https://github.com/jborean93/PInvokeHelper/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jborean93/PInvokeHelper'
            ReleaseNotes = 'See https://github.com/jborean93/PInvokeHelper/blob/master/CHANGELOG.md'
        }
    }
}
