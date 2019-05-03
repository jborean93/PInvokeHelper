# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Import-Enum {
    <#
    .SYNOPSIS
    Defines an enum.

    .DESCRIPTION
    Defines an enum in the module builder specified.

    .PARAMETER ModuleBuilder
    The ModuleBuilder object to define the enum in.

    .PARAMETER Name
    The name of the enum to define.

    .PARAMETER Type
    The enum base type.

    .PARAMETER Values
    A hashtable of enum key/values to define.

    .PARAMETER Flags
    Whether the enum has the [Flags] attribute applied.

    .EXAMPLE
    $module_builder = New-DynamicModule -Name PInvokeHelper

    Defines
        [Flags]
        public LogonFlags : uint
        {
            WithoutProfile = 0,
            WithProfile = 1,
            NetCredentialsOnly = 2
        }

    $enum = @{
        ModuleBuilder = $module_builder
        Name = 'LogonFlags'
        Type = ([System.UInt32])
        Flags = $true
        Values = @{
            WithoutProfile = 0
            WithProfile = 1
            NetCredentialsOnly = 2
        }
    }
    Import-Enum @enum

    Defines
        public TokenInformationClass : int
        {
            User = 1,
            Groups = 2,
            Privileges = 3
        }

    $enum = @{
        ModuleBuilder = $module_builder
        Name = 'TokenInformationClass'
        Type = ([System.Int32])
        Values = @{
            User = 1
            Groups = 2
            Privileges = 3
        }
    }
    Import-Enum @enum
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Reflection.Emit.ModuleBuilder]
        $ModuleBuilder,

        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter(Mandatory=$true)]
        [Type]
        $Type,

        [Parameter(Mandatory=$true)]
        [System.Collections.IDictionary]
        $Values,

        [Switch]
        $Flags
    )

    $enum_builder = $ModuleBuilder.DefineEnum($Name, 'Public', $Type)

    # Add the Flags attribute if required
    if ($Flags) {
        $ctor_info = [System.FlagsAttribute].GetConstructor([Type]::EmptyTypes)
        $attribute_builder = New-Object -TypeName System.Reflection.Emit.CustomAttributeBuilder -ArgumentList @(
            $ctor_info,
            @()
        )
        $enum_builder.SetCustomAttribute($attribute_builder)
    }

    foreach ($kvp in $Values.GetEnumerator()) {
        $value = $kvp.Value -as $Type
        $enum_builder.DefineLiteral($kvp.Key, $value) > $null
    }
    $enum_builder.CreateType() > $null
}