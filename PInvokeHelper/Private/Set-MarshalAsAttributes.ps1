# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Set-MarshalAsAttribute {
    <#
    .SYNOPSIS
    Adds the MarshalAs attribute.

    .DESCRIPTION
    Add the [MarshalAs()] attribute to a builder object.

    .PARAMETER Builder
    The builder object to add the MarshalAs attribute to.

    .PARAMETER Type
    The UnmanagedType value to set on the MarshalAs attribute.

    .PARAMETER SizeConst
    The SizeConst value to set on the MarshalAs attribute.

    .PARAMETER ArraySubType
    The ArraySubType value to set on the MarshalAs attribute.

    .EXAMPLE
    Set-MarshalAsAttribute -Builder $method_builder -Type LPWStr -SizeConst 8
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification="This does make a system change but localised to the passed in builder")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Object]
        $Builder,

        [Parameter(Mandatory=$true)]
        [System.Runtime.InteropServices.UnmanagedType]
        $Type,

        [System.Int32]
        $SizeConst,

        [System.Runtime.InteropServices.UnmanagedType]
        $ArraySubType
    )

    $ctor_info = [System.Runtime.InteropServices.MarshalAsAttribute].GetConstructor(
        [System.Runtime.InteropServices.UnmanagedType]
    )
    $no_params = @{
        TypeName = 'System.Reflection.Emit.CustomAttributeBuilder'
        ArgumentList = [System.Collections.Generic.List`1[Object]]@($ctor_info, $Type)
    }

    $field_array = [System.Collections.Generic.List`1[System.Reflection.FieldInfo]]@()
    $field_values = [System.Collections.Generic.List`1[Object]]@()
    if ($null -ne $SizeConst) {
        $field_array.Add([System.Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
        $field_values.Add($SizeConst)
    }
    if ($null -ne $ArraySubType) {
        $field_array.Add([System.Runtime.InteropServices.MarshalAsAttribute].GetField('ArraySubType'))
        $field_values.Add($ArraySubType)
    }
    $no_params.ArgumentList.Add($field_array.ToArray())
    $no_params.ArgumentList.Add($field_values.ToArray())

    $attribute_builder = New-Object @no_params
    $Builder.SetCustomAttribute($attribute_builder)
}