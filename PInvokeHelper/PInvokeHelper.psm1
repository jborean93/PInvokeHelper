# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

### TEMPLATED EXPORT FUNCTIONS ###
# The below is replaced by the CI system during the build cycle to contain all
# the Public and Private functions into the 1 psm1 file for faster importing.

if (Test-Path -LiteralPath $PSScriptRoot\Public) {
    $public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
} else {
    $public = @()
}
if (Test-Path -LiteralPath $PSScriptRoot\Private) {
    $private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
} else {
    $private = @()
}

# dot source the files
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

$public_functions = $public.Basename

### END TEMPLATED EXPORT FUNCTIONS ###

<#
Defines the PInvokeHelper.SafeNativeHandle class that guarantees a native handle to be closed. The C# type looks like

    public class SafeNativeHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeNativeHandle() : base(true) { }
        public SafeNativeHandle(IntPtr handle) : base(true) { this.handle = handle; }

        public static implicit operator IntPtr(SafeNativeHandle h) { return h.DangerousGetHandle(); }

        [DllImport("Kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(
            IntPtr pObject);

        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.MayFail)]
        protected override bool ReleaseHandle()
        {
            return CloseHandle(handle);
        }
    }
#>

$module_builder = New-DynamicModule -Name PInvokeHelper

$type_builder = $module_builder.DefineType(
    'PInvokeHelper.SafeNativeHandle',
    [System.Reflection.TypeAttributes]'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit',
    [Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid]
)

# Get the base constructor and handle field objects for use in the IL method definition
$base_type = [Microsoft.Win32.SafeHandles.SafeHandleZeroOrMinusOneIsInvalid]
$base_ctor = $base_type.GetConstructor(
    [System.Reflection.BindingFlags]'Instance, NonPublic',
    $null,
    [Type[]]@(,[System.Boolean]),
    $null
)
$base_handle_field = $base_type.GetField('handle', [System.Reflection.BindingFlags]'Instance, NonPublic')

# Define the constructor blocks
$ctor1 = $type_builder.DefineConstructor(
    [System.Reflection.MethodAttributes]'PrivateScope, Public, HideBySig, SpecialName, RTSpecialName',
    [System.Reflection.CallingConventions]'Standard, HasThis',
    @()
)
$ctor1_il = $ctor1.GetILGenerator()
$ctor1_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
$ctor1_il.Emit([System.Reflection.Emit.OpCodes]::Ldc_I4, 1)  # Sets $true onto stack
$ctor1_il.Emit([System.Reflection.Emit.OpCodes]::Call, $base_ctor)  # calls base(true)
$ctor1_il.Emit([System.Reflection.Emit.OpCodes]::Ret)

$ctor2 = $type_builder.DefineConstructor(
    [System.Reflection.MethodAttributes]'PrivateScope, Public, HideBySig, SpecialName, RTSpecialName',
    [System.Reflection.CallingConventions]'Standard, HasThis',
    [Type[]]@(,[System.IntPtr])
)
$ctor2_il = $ctor2.GetILGenerator()
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Ldc_I4, 1)
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Call, $base_ctor)
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_1)  # Loads the IntPtr arg passed into the constructor
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Stfld, $base_handle_field)  # Sets the handle field with param1
$ctor2_il.Emit([System.Reflection.Emit.OpCodes]::Ret)

# Define the CloseHandle method
$close_handle_builder = $type_builder.DefineMethod(
    'CloseHandle',
    [System.Reflection.MethodAttributes]'Private, Static',
    [System.Boolean],
    [Type[]]@([System.IntPtr])
)

$dll_import_attr = New-Object -TypeName System.Reflection.Emit.CustomAttributeBuilder -ArgumentList @(
    [System.Runtime.InteropServices.DllImportAttribute].GetConstructor([System.String]),
    'Kernel32.dll',
    [System.Reflection.FieldInfo[]]@([System.Runtime.InteropServices.DllImportAttribute].GetField('SetLastError')),
    [Object[]]@($true)
)
$close_handle_builder.SetCustomAttribute($dll_import_attr)

# Define the ReleaseHandle() method
$method_builder = $type_builder.DefineMethod(
    'ReleaseHandle',
    [System.Reflection.MethodAttributes]'PrivateScope, Family, Virtual, HideBySig',
    [System.Boolean],
    @()
)
$method_il = $method_builder.GetILGenerator()
$method_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
$method_il.Emit([System.Reflection.Emit.OpCodes]::Ldfld, $base_handle_field)  # Load the value of the handle field
$method_il.Emit([System.Reflection.Emit.OpCodes]::Call, $close_handle_builder)  # Call the CloseHandle method
$method_il.Emit([System.Reflection.Emit.OpCodes]::Ret)

# Set [ReliabilityContract(Consistency.WillNotCorrupState, Cer.MayFail)] on the ReleaseHandle() method
$reliability_attr = [System.Runtime.ConstrainedExecution.ReliabilityContractAttribute].GetConstructor(
    [Type[]]@([System.Runtime.ConstrainedExecution.Consistency], [System.Runtime.ConstrainedExecution.Cer])
)
$ca = New-Object -TypeName System.Reflection.Emit.CustomAttributeBuilder -ArgumentList @(
    $reliability_attr,
    @(
        [System.Runtime.ConstrainedExecution.Consistency]::WillNotCorruptState,
        [System.Runtime.ConstrainedExecution.Cer]::MayFail
    )
)
$method_builder.SetCustomAttribute($ca)

# Define implicit operator to IntPtr. This allows the SafeNativeHandle to be used in place of IntPtr without any
# explicit casts. Technically it is dangerous but we are using this type to make sure the handle is disposed.
$dangerous_get_handle = $base_type.GetMethod('DangerousGetHandle')
$impl_method = $type_builder.DefineMethod(
    'op_Implicit',
    [System.Reflection.MethodAttributes]'Public, HideBySig, SpecialName, Static',
    [System.IntPtr],
    @(,$type_builder)
)
$impl_il = $impl_method.GetILGenerator()
$impl_il.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
$impl_il.Emit([System.Reflection.Emit.OpCodes]::Callvirt, $dangerous_get_handle)
$impl_il.Emit([System.Reflection.Emit.OpCodes]::Ret)

$type_builder.CreateType() > $null

Export-ModuleMember -Function $public_functions
