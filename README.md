# PInvokeHelper

[![Build status](https://ci.appveyor.com/api/projects/status/00i9wmp0awo535a6?svg=true)](https://ci.appveyor.com/project/jborean93/pinvokehelper)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PInvokeHelper.svg)](https://www.powershellgallery.com/packages/PInvokeHelper)

Various cmdlets that can be used to dynamically define C# structs and methods for
[PInvoking](https://docs.microsoft.com/en-us/cpp/dotnet/how-to-call-native-dlls-from-managed-code-using-pinvoke?view=vs-2019)
native Win32 APIs.


## Info

Cmdlets included with this module are;

* [Get-Win32ErrorMessage](Docs/Get-Win32ErrorMessage.md): Converts an Win32 Error code to a human readable error message.
* [Import-Enum](Docs/Import-Enum.md): Import an enum.
* [Import-PInvokeMethod](Docs/Import-PInvokeMethod.md): Import a Win32 API function as a static method.
* [Import-Struct](Docs/Import-Struct.md): Import a struct for use in a Win32 API.
* [New-DynamicModule](Docs/New-DynamicModule.md): Simple helper function to create a dynamic module required by the above cmdlets.

As well as generating these cmdlets, importing this module will also define
the class `PInvokeHelper.SafeNativeHandle`. This class can be used as a
substitution for `System.IntPtr` in PInvoke methods that return a handle. The
benefits of using this is that you are able to guarantee the closing of the
native handle when the object is garbage collected or `.Dispose()` is manually
called.

An example of how to use this for a PInvoke method would be;

```powershell
$module_builder = New-DynamicModule -Name 'Process'
$type_builder = $module_builder.DefineType('NativeMethods', 'Public, Class')
Import-PInvokeMethod -TypeBuilder $type_builder `
    -DllName 'Kernel32.dll' `
    -Name 'OpenProcess' `
    -ReturnType ([PInvokeHelper.SafeNativeHandle]) `
    -ParameterTypes @([System.UInt32], [System.Boolean], [System.UInt32]) `
    -SetLastError
$type_builder.CreateType() > $null

$h_process = [NativeMethods]::OpenProcess(
    0x0400,
    $false,
    $PID
); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

if ($h_process.IsInvalid) {
    $msg = Get-Win32ErrorMessage -ErrorCode $err_code
    throw "Failed to open process '$PID': $msg"
}

try {
    [System.Int64][System.IntPtr]$h_process
} finally {
    # Not necessary but it is recommended to manually dispose the handle when
    # it is no longer needed.
    $h_process.Dispose()
}
```

## Requirements

These cmdlets have the following requirements

* PowerShell v3.0 or newer
* Windows PowerShell (not PowerShell Core)
* Windows Server 2008 R2/Windows 7 or newer


## Installing

The easiest way to install this module is through
[PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/overview).
This is installed by default with PowerShell 5 but can be added on PowerShell
3 or 4 by installing the MSI [here](https://www.microsoft.com/en-us/download/details.aspx?id=51451).

Once installed, you can install this module by running;

```
# Install for all users
Install-Module -Name PInvokeHelper

# Install for only the current user
Install-Module -Name PInvokeHelper -Scope CurrentUser
```

If you wish to remove the module, just run
`Uninstall-Module -Name PInvokeHelper`.

If you cannot use PowerShellGet, you can still install the module manually,
here are some basic steps on how to do this;

1. Download the latext zip from GitHub [here](https://github.com/jborean93/PInvokeHelper/releases/latest)
2. Extract the zip
3. Copy the folder `PInvokeHelper` inside the zip to a path that is set in `$env:PSModulePath`. By default this could be `C:\Program Files\WindowsPowerShell\Modules` or `C:\Users\<user>\Documents\WindowsPowerShell\Modules`
4. Reopen PowerShell and unblock the downloaded files with `$path = (Get-Module -Name PInvokeHelper -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1;`
5. Reopen PowerShell one more time and you can start using the cmdlets

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable `PSModulePath` if you want to use another path._


## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the
changes. To test out your changes locally you can just run `.\build.ps1` in
PowerShell. This script will ensure all dependencies are installed before
running the test suite.

_Note: this requires PowerShellGet or WMF 5 to be installed_

## Backlog

* Fix up doc generation to product a correct markdown file
