# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function New-DynamicModule {
    <#
    .SYNOPSIS
    Creates a dynamic module.

    .DESCRIPTION
    Creates a dynamic module that can then be used by other functions in PInvokeHelper when defining other structs,
    enums, and methods.

    .PARAMETER Name
    The unique assembly and module name to define the builder in. The assembly with be "$($Name)Assembly" and the
    module will be "$($Name)Module".

    .OUTPUTS
    Creates a dynamic module that can be used to define further types like classes, enums, structs and so forth.

    .EXAMPLE
    New-DynamicModule -Name PInvokeHelper
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Justification="This does make a system change")]
    [OutputType([System.Reflection.Emit.ModuleBuilder])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name
    )

    $assembly_name = "$($Name)Assembly"
    $module_name = "$($Name)Module"

    $domain = [System.AppDomain]::CurrentDomain

    # Create the dynamic assembly that contains our new module. We set the access to Run so that we don't save the
    # defined types to disk.
    $dynamic_assembly = New-Object -TypeName System.Reflection.AssemblyName -ArgumentList $assembly_name
    $assembly_builder = $domain.DefineDynamicAssembly(
        $dynamic_assembly,
        [System.Reflection.Emit.AssemblyBuilderAccess]::Run
    )

    $dynamic_module = $assembly_builder.DefineDynamicModule($module_name, $false)

    return $dynamic_module
}