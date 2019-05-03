# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Import-PInvokeMethod {
    <#
    .SYNOPSIS
    Defines a Win32 function as a PInvoke method.

    .DESCRIPTION
    Defines a Win32 function as a PInvoke method and control some of the marshaling techniques used for that function.

    .PARAMETER TypeBuilder
    A TypeBuilder that represents the class to define the static methods in.

    .PARAMETER DllName
    The name of the Dll that contains the function to import.

    .PARAMETER Name
    The name of the Win32 function to import.

    .PARAMETER ReturnType
    The type that is returned by the function. Can also be a Hashtable with the following keys;

        Type: The type of the return value of the function.
        MarshalAs: An optional hash that contains the parameter for Set-MarshalAsAttribute.
            Type: Sets the [MarshalAs(UnmanagedType.)] value for the parameter.
            SizeConst: Optional SizeConst value for MarshalAs.
            ArraySubType: Optional ArraySubType value for MarshalAs.

    .PARAMETER ParameterTypes
    A list of types of the functions parameters. Each parameter is represented by a [Type] value for a simple
    parameter type but can also be a hashtable with the following keys;

        Type: Must be set to the type of the parameter
        Ref: Whether it is a [Ref] type, e.g. is ref or has an out parameter in .NET.
        MarshalAs: An optional hash that contains the parameter for Set-MarshalAsAttribute.
            Type: Sets the [MarshalAs(UnmanagedType.)] value for the parameter.
            SizeConst: Optional SizeConst value for MarshalAs.
            ArraySubType: Optional ArraySubType value for MarshalAs.

    .PARAMETER SetLastError
    Sets the 'SetLastError=true' field on the DllImport attribute of the function.

    .PARAMETER CharSet
    Sets the 'CharSet' field on the DllImport attribute of the function.

    .PARAMETER PassThru
    Output the MethodBuilder of the defined function.

    .OUTPUTS
    None, System.Reflection.Emit.MethodBuilder
    This cmdlet generates a System.Reflection.Emit.MethodInfo if you specify -PassThru, Otherwise this cmdlet does not
    return any output.

    .EXAMPLE
    $module_builder = New-DynamicModule -Name PInvokeHelper
    $type_builder = $module_buidler.DefineType('PInvokeHelper.NativeMethods', 'Public, Class')

    $function_definition = @{
        DllName = 'Kernel32.dll'
        Name = 'CreateProcessW'
        ReturnType = ([System.Boolean])
        ParameterTypes = @(
            @{
                Type = ([System.String])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            [System.Text.StringBuilder],
            [System.IntPtr],
            [System.IntPtr],
            [System.Boolean],
            [PSLimitedProcess.ProcessCreationFlags],
            [System.IntPtr],
            @{
                Type = ([System.String])
                MarshalAs = @{
                    Type = [System.Runtime.InteropServices.UnmanagedType]::LPWStr
                }
            },
            @{ Ref = $true; Type = [PSLimitedProcess.STARTUPINFOEX] },
            @{ Ref = $true; Type = [PSLimitedProcess.PROCESS_INFORMATION] }
        )
        SetLastError = $true
    }
    Import-PInvokeMethod -TypeBuilder $type_builder @function_definition

    # Call once all functions have been defined in the type/class
    $type_builder.CreateType() > $null
    #>
    [OutputType([System.Reflection.Emit.MethodBuilder])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Reflection.Emit.TypeBuilder]
        $TypeBuilder,

        [Parameter(Mandatory=$true)]
        [System.String]
        $DllName,

        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter(Mandatory=$true)]
        [Object]
        $ReturnType,

        [Object[]]
        $ParameterTypes = [Object[]]@(),

        [Switch]
        $SetLastError,

        [Runtime.InteropServices.CharSet]
        $CharSet = [System.Runtime.InteropServices.CharSet]::Auto,

        [Switch]$PassThru
    )

    # ParameterTypes is either an array of Type or Hashtable where the Hashtable can contain
    #     Ref = Whether the parameter is an in/out parameter
    #     Type = The actual type of the parameter, this must be set when using a hashtable
    #     MarshalAs = A hashtable that defines the custom MarshalAs attributes. See Set-MarshalAsAttribute
    $parameter_types = [System.Collections.Generic.List`1[Type]]@()
    $parameter_marshal_as = @{}
    for ($i = 0; $i -lt $ParameterTypes.Length; $i++) {
        $parameter = $ParameterTypes[$i]
        if ($parameter -is [System.Collections.IDictionary]) {
            if ($parameter.ContainsKey('Ref') -and $parameter.Ref) {
                $parameter_types.Add(($parameter.Type -as [Type]).MakeByRefType())
            } else {
                $parameter_types.Add(($parameter.Type -as [Type]))
            }

            if ($parameter.ContainsKey('MarshalAs')) {
                $parameter_idx = $i + 1
                $parameter_marshal_as.$parameter_idx = $parameter.MarshalAs
            }
        } else {
            $parameter_types.Add(($parameter -as [Type]))
        }
    }

    # Cast the defined return type as a type. Check if the parameter is a Hashtable that defines the MarshalAs attr
    $marshal_as = $null
    if ($ReturnType -is [System.Collections.IDictionary]) {
        $return_type = $ReturnType.Type -as [Type]

        if ($ReturnType.ContainsKey('MarshalAs')) {
            $marshal_as = $ReturnType.MarshalAs
        }
    } else {
        $return_type = $ReturnType -as [Type]
    }

    # Next, the method is created where we specify the name, parameters and
    # return type that is expected
    $method_builder = $TypeBuilder.DefineMethod(
        $Name,
        [System.Reflection.MethodAttributes]'Public, Static',
        $return_type,
        $parameter_types
    )

    # Set the retval MarshalAs attribute if set
    if ($null -ne $marshal_as) {
        $parameter_builder = $method_builder.DefineParameter(
            0, [System.Reflection.ParameterAttributes]::Retval, $null
        )
        Set-MarshalAsAttribute -Builder $parameter_builder @marshal_as
    }

    # Set the parameter MarshalAs attribute if set
    foreach ($marshal_info in $parameter_marshal_as.GetEnumerator()) {
        $param_idx = $marshal_info.Key
        $marshal_as = $marshal_info.Value
        $parameter_builder = $method_builder.DefineParameter(
            $param_idx,
            [System.Reflection.ParameterAttributes]::None,
            $null
        )
        Set-MarshalAsAttribute -Builder $parameter_builder @marshal_as
    }

    # Set the DllImport() attributes; SetLastError and CharSet
    $dll_ctor = [System.Runtime.InteropServices.DllImportAttribute].GetConstructor([System.String])
    $method_fields = [System.Reflection.FieldInfo[]]@(
        [System.Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
        [System.Runtime.InteropServices.DllImportAttribute].GetField('CharSet')
    )
    $method_fields_values = [Object[]]@($SetLastError.IsPresent, $CharSet)
    $dll_import_attr = New-Object -TypeName System.Reflection.Emit.CustomAttributeBuilder -ArgumentList @(
        $dll_ctor,
        $DllName,
        $method_fields,
        $method_fields_values
    )
    $method_builder.SetCustomAttribute($dll_import_attr)

    if ($PassThru) {
        $method_builder
    }
}