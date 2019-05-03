# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Import-Struct {
    <#
    .SYNOPSIS
    Defines a struct.

    .DESCRIPTION
    Defines a struct in the ModuleBuilder specified.

    .PARAMETER ModuleBuilder
    The ModuleBuilder to define the struct in.

    .PARAMETER Name
    The name of the struct to define.

    .PARAMETER Fields
    A list of hashes that define the fields of the struct. Each value in the fields list should be a hash with the
    following keys;

        Name: The name of the field.
        Type: The type of the field.
        MarshalAs: Optional hash that defines the MarshalAs attribute based on the Set-MarshalAsAttribute parameters.
            Type: Sets the [MarshalAs(UnmanagedType.)] value for the parameter.
            SizeConst: Optional SizeConst value for MarshalAs.
            ArraySubType: Optional ArraySubType value for MarshalAs.

    .PARAMETER PackingSize
    Set the Pack value for the StructLayout attribute.

    .EXAMPLE
    $module_builder = New-DynamicModule -Name PInvokeHelper

    $struct_definition = @{
        Name = 'TOKEN_PRIVILEGES'
        Fields = @(
            @{
                Name = 'PrivilegeCount'
                Type = ([System.UInt32])
            },
            @{
                Name = 'Privileges'
                Type = 'LUID_AND_ATTRIBUTES[]'
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
                    SizeConst = 1
                }
            }
        )
    }
    Import-Struct -ModuleBuilder $module_builder @struct_definition
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
        [Hashtable[]]
        $Fields,

        [System.Reflection.Emit.PackingSize]
        $PackingSize = [System.Reflection.Emit.PackingSize]::Unspecified
    )

    $struct_builder = $ModuleBuilder.DefineType(
        $Name,
        'Class, Public, Sealed, BeforeFieldInit, AutoLayout, SequentialLayout',
        [System.ValueType],
        $PackingSize
    )

    foreach ($field in $Fields) {
        # Make sure we cast the Type key for the field as an actual [Type]. This allows the Type definition to be
        # defined as a string and only casted when it's actually needed.
        $field_type = $field.Type -as [Type]

        # Add a custom MarshalAs attribute if required. This should contain the Type and the optional SizeConst key.
        if ($field.ContainsKey('MarshalAs')) {
            $field_builder = $struct_builder.DefineField($field.Name, $field_type, 'Public, HasFieldMarshal')
            $marshal_as = $field.MarshalAs
            Set-MarshalAsAttribute -Builder $field_builder @marshal_as
        } else {
            $struct_builder.DefineField($field.Name, $field_type, 'Public') > $null
        }
    }

    $struct_builder.CreateType() > $null
}