# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

$verbose = @{}
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") {
    $verbose.Add("Verbose", $true)
}

$ps_version = $PSVersionTable.PSVersion.Major
$cmdlet_name = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$module_name = (Get-ChildItem -Path $PSScriptRoot\.. -Directory -Exclude @("Tests", "Docs")).Name
Import-Module -Name $PSScriptRoot\..\$module_name -Force

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should return message for success' {
            $actual = Get-Win32ErrorMessage -ErrorCode 0
            $actual | Should -Be "The operation completed successfully (Win32 ErrorCode 0 - 0x00000000)"
        }

        It 'Should return message for error' {
            $actual = Get-Win32ErrorMessage -ErrorCode 5
            $actual | Should -Be "Access is denied (Win32 ErrorCode 5 - 0x00000005)"
        }
    }
}