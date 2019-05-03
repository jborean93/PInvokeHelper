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

$dynamic_module = New-DynamicModule -Name PInvokeHelper.ImportStruct

Describe "$cmdlet_name PS$ps_version tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version latest

        It 'Import simple struct' {
            $struct_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.LUID'
                Fields = @(
                    @{
                        Name = 'LowPart'
                        Type = ([System.UInt32])
                    },
                    @{
                        Name = 'HighPart'
                        Type = ([System.Int32])
                    }
                )
            }
            Import-Struct @struct_params

            $actual = [StructTests.LUID]

            $actual | Should -Not -Be $null
            $actual.Name | Should -Be 'LUID'
            $actual.Namespace | Should -Be 'StructTests'
            $actual.StructLayoutAttribute.Value | Should -Be 'Sequential'
            $actual.DeclaredFields.Count | Should -Be 2
            $actual.DeclaredFields[0].Name | Should -Be 'LowPart'
            $actual.DeclaredFields[0].FieldType.FullName | Should -Be 'System.UInt32'
            $actual.DeclaredFields[0].IsPublic | Should -Be $true
            $actual.DeclaredFields[1].Name | Should -Be 'HighPart'
            $actual.DeclaredFields[1].FieldType.FullName | Should -Be 'System.Int32'
            $actual.DeclaredFields[1].IsPublic | Should -Be $true
            $actual.IsPublic | Should -Be $true

            $struct = New-Object -TypeName StructTests.LUID
            $struct.LowPart = [System.UInt32]::MaxValue
            $struct.HighPart = [System.Int32]::MaxValue

            [System.Runtime.InteropServices.Marshal]::SizeOf($struct) | Should -Be 8
        }

        It 'Defines struct with pack size' {
            $struct_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.PackedStruct'
                Fields = @(
                    @{
                        Name = 'Field1'
                        Type = ([System.UInt32])
                    },
                    @{
                        Name = 'Field2'
                        Type = ([System.Byte])
                    }
                    @{
                        Name = 'Field3'
                        Type = ([System.Int32])
                    }
                )
                PackingSize = [System.Reflection.Emit.PackingSize]::Size4
            }
            Import-Struct @struct_params

            $actual = [StructTests.PackedStruct]

            $actual | Should -Not -Be $null
            $actual.Name | Should -Be 'PackedStruct'
            $actual.Namespace | Should -Be 'StructTests'
            $actual.StructLayoutAttribute.Value | Should -Be 'Sequential'

            $actual = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][StructTests.PackedStruct])
            $actual | Should -Be 12
        }

        It 'Defines struct with MarshalAs field' {
            $struct_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.MarshalAs'
                Fields = @(
                    @{
                        Name = 'StringField'
                        Type = ([System.String])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                        }
                    }
                )
            }

            Import-Struct @struct_params

            $actual = [StructTests.MarshalAs]

            $actual | Should -Not -Be $null
            $actual.Name | Should -Be 'MarshalAs'
            $actual.Namespace | Should -Be 'StructTests'
            $actual.StructLayoutAttribute.Value | Should -Be 'Sequential'

            $actual.DeclaredFields.Count | Should -Be 1
            $actual.DeclaredFields[0].Name | Should -Be 'StringField'
            $actual.DeclaredFields[0].FieldType.FullName | Should -Be 'System.String'
            $actual.DeclaredFields[0].IsPublic | Should -Be $true
            $actual.DeclaredFields[0].CustomAttributes.Count | Should -Be 1

            $cust_attr = $actual.DeclaredFields[0].CustomAttributes[0]
            $cust_attr.AttributeType.FullName | Should -Be 'System.Runtime.InteropServices.MarshalAsAttribute'
            $cust_attr.ConstructorArguments[0].Value | Should -Be ([System.Runtime.InteropServices.UnmanagedType]::LPWStr)
            ($cust_attr.NamedArguments | Where-Object { $_.MemberName -eq 'ArraySubType' }).TypedValue.Value | Should -Be 0
            ($cust_attr.NamedArguments | Where-Object { $_.MemberName -eq 'SizeConst' }).TypedValue.Value | Should -Be 0
        }

        It 'Defines struct with SizeConst and ArraySubType' {
            $struct_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.MarshalAsAdv'
                Fields = @(
                    @{
                        Name = 'Field'
                        Type = ([System.UInt32[]])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                            SizeConst = 1
                            ArraySubType = [System.Runtime.InteropServices.UnmanagedType]::U4
                        }
                    }
                )
            }

            Import-Struct @struct_params

            $actual = [StructTests.MarshalAsAdv]

            $actual | Should -Not -Be $null
            $actual.Name | Should -Be 'MarshalAsAdv'
            $actual.Namespace | Should -Be 'StructTests'
            $actual.StructLayoutAttribute.Value | Should -Be 'Sequential'

            $actual.DeclaredFields.Count | Should -Be 1
            $actual.DeclaredFields[0].Name | Should -Be 'Field'
            $actual.DeclaredFields[0].FieldType.FullName | Should -Be 'System.UInt32[]'
            $actual.DeclaredFields[0].IsPublic | Should -Be $true
            $actual.DeclaredFields[0].CustomAttributes.Count | Should -Be 1

            $cust_attr = $actual.DeclaredFields[0].CustomAttributes[0]
            $cust_attr.AttributeType.FullName | Should -Be 'System.Runtime.InteropServices.MarshalAsAttribute'
            $cust_attr.ConstructorArguments[0].Value | Should -Be ([System.Runtime.InteropServices.UnmanagedType]::ByValArray)
            ($cust_attr.NamedArguments | Where-Object { $_.MemberName -eq 'ArraySubType' }).TypedValue.Value | `
                Should -Be ([System.Runtime.InteropServices.UnmanagedType]::U4)
            ($cust_attr.NamedArguments | Where-Object { $_.MemberName -eq 'SizeConst' }).TypedValue.Value | Should -Be 1
        }

        It 'Fails when invalid MarshalAs attributes are defined' {
            $struct_params = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.MarshalAsFail'
                Fields = @(
                    @{
                        Name = 'StringField'
                        Type = ([System.String])
                        MarshalAs = @{
                            Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                            Invalid = $true
                        }
                    }
                )
            }

            { Import-Struct @struct_params } | Should -Throw 'A parameter cannot be found that matches parameter name ''Invalid'''
        }

        It 'Defines struct with struct' {
            $struct1 = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.NestedStruct'
                Fields = @(
                    @{
                        Name = 'SubField'
                        Type = ([System.Boolean])
                    }
                )
            }

            $struct2 = @{
                ModuleBuilder = $dynamic_module
                Name = 'StructTests.ParentStruct'
                Fields = @(
                    @{
                        Name = 'ParentField'
                        Type = 'StructTests.NestedStruct'
                    }
                )
            }
            Import-Struct @struct1
            Import-Struct @struct2

            $parent = [StructTests.ParentStruct]
            $nested = [StructTests.NestedStruct]

            $parent | Should -Not -Be $null
            $parent.Name | Should -Be 'ParentStruct'
            $parent.Namespace | Should -Be 'StructTests'
            $parent.StructLayoutAttribute.Value | Should -Be 'Sequential'

            $parent.DeclaredFields.Count | Should -Be 1
            $parent.DeclaredFields[0].Name | Should -Be 'ParentField'
            $parent.DeclaredFields[0].FieldType.FullName | Should -Be 'StructTests.NestedStruct'
            $parent.DeclaredFields[0].IsPublic | Should -Be $true
            $parent.DeclaredFields[0].CustomAttributes.Count | Should -Be 0

            $nested | Should -Not -Be $null
            $nested.Name | Should -Be 'NestedStruct'
            $nested.Namespace | Should -Be 'StructTests'
            $nested.StructLayoutAttribute.Value | Should -Be 'Sequential'

            $nested.DeclaredFields.Count | Should -Be 1
            $nested.DeclaredFields[0].Name | Should -Be 'SubField'
            $nested.DeclaredFields[0].FieldType.FullName | Should -Be 'System.Boolean'
            $nested.DeclaredFields[0].IsPublic | Should -Be $true
            $nested.DeclaredFields[0].CustomAttributes.Count | Should -Be 0
        }
    }
}