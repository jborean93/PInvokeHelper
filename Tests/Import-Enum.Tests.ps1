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

$dynamic_module = New-DynamicModule -Name PInvokeHelper.ImportEnum

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Should import enum with Int32' {
            $enum_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'TestInt32'
                Type = ([System.Int32])
                Values = @{
                    Value1 = 1
                    Value2 = 5
                }
            }
            Import-Enum @enum_params

            $actual = [TestInt32]

            $actual | Should -Not -Be $null
            $actual.BaseType.FullName | Should -Be 'System.Enum'
            $actual.IsPublic | Should -Be $true
            $actual.CustomAttributes.Count | Should -Be 0

            [TestInt32]::Value1 | Should -Be 1
            [TestInt32]::Value2 | Should -Be 5
            [System.Enum]::GetName($actual, 1) | Should -Be 'Value1'
            [System.Enum]::GetName($actual, 5) | Should -Be 'Value2'
            [System.Enum]::GetName($actual, 2) | Should -Be $null
            [System.Enum]::GetNames($actual) | Should -Be 'Value1', 'Value2'
            [System.Enum]::GetUnderlyingType($actual).FullName | Should -Be 'System.Int32'
        }

        It 'Should fail to import enum that exceed max value' {
            $enum_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'TestInt32Fail'
                Type = ([System.Int32])
                Values = @{
                    Value1 = [System.UInt32]::MaxValue
                }
            }
            { Import-Enum @enum_params } | Should -Throw "Null is not a valid constant value for this type."
        }

        It 'Should import flags enum with UInt32' {
            $enum_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'TestUInt32'
                Type = ([System.UInt32])
                Flags = $true
                Values = @{
                    Value1 = 0x00000000
                    Value2 = 0x00000001
                    Value3 = 0x00000002
                    Value4 = 0x00000003
                    Value5 = 0x00000004
                    ValueMax = [System.UInt32]::MaxValue
                }
            }
            Import-Enum @enum_params

            $actual = [TestUInt32]

            $actual | Should -Not -Be $null
            $actual.BaseType.FullName | Should -Be 'System.Enum'
            $actual.IsPublic | Should -Be $true
            $actual.CustomAttributes.Count | Should -Be 1
            $actual.CustomAttributes[0].AttributeType | Should -Be 'System.FlagsAttribute'

            [TestUInt32]::Value1 | Should -Be 0
            [TestUInt32]::Value2 | Should -Be 1
            [TestUInt32]::Value3 | Should -Be 2
            [TestUInt32]::Value4 | Should -Be 3
            [System.Enum]::GetName($actual, 0) | Should -Be 'Value1'
            [System.Enum]::GetName($actual, 1) | Should -Be 'Value2'
            [System.Enum]::GetName($actual, 2) | Should -Be 'Value3'
            [System.Enum]::GetName($actual, 3) | Should -Be 'Value4'
            [System.Enum]::GetName($actual, 4) | Should -Be 'Value5'
            [System.Enum]::GetName($actual, [System.UInt32]::MaxValue) | Should -Be 'ValueMax'
            [System.Enum]::GetNames($actual) | Should -Be 'Value1', 'Value2', 'Value3', 'Value4', 'Value5', 'ValueMax'
            [System.Enum]::GetUnderlyingType($actual).FullName | Should -Be 'System.UInt32'
        }
    }
}