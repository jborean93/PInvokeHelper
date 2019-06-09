# PInvokeHelper

[![Build status](https://ci.appveyor.com/api/projects/status/00i9wmp0awo535a6?svg=true)](https://ci.appveyor.com/project/jborean93/pinvokehelper)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PInvokeHelper.svg)](https://www.powershellgallery.com/packages/PInvokeHelper)
[![codecov](https://codecov.io/gh/jborean93/PInvokeHelper/branch/master/graph/badge.svg)](https://codecov.io/gh/jborean93/PInvokeHelper)

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
by using the script cmdlets in the script [Install-ModuleNupkg.ps1](https://gist.github.com/jborean93/e0cb0e3aabeaa1701e41f2304b023366).

```powershell
# Enable TLS1.1/TLS1.2 if they're available but disabled (eg. .NET 4.5)
$security_protocols = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::SystemDefault
if ([Net.SecurityProtocolType].GetMember("Tls11").Count -gt 0) {
    $security_protocols = $security_protocols -bor [Net.SecurityProtocolType]::Tls11
}
if ([Net.SecurityProtocolType].GetMember("Tls12").Count -gt 0) {
    $security_protocols = $security_protocols -bor [Net.SecurityProtocolType]::Tls12
}
[Net.ServicePointManager]::SecurityProtocol = $security_protocols

# Run the script to load the cmdlets and get the URI of the nupkg
$invoke_wr_params = @{
    Uri = 'https://gist.github.com/jborean93/e0cb0e3aabeaa1701e41f2304b023366/raw/Install-ModuleNupkg.ps1'
    UseBasicParsing = $true
}
$install_script = (Invoke-WebRequest @invoke_wr_params).Content

################################################################################################
# Make sure you check the script at the URI first and are happy with the script before running #
################################################################################################
Invoke-Expression -Command $install_script

# Get the URI to the nupkg on the gallery
$gallery_uri = Get-PSGalleryNupkgUri -Name PInvokeHelper

# Install the nupkg for the current user, add '-Scope AllUsers' to install
# for all users (requires admin privileges)
Install-PowerShellNupkg -Uri $gallery_uri
```

_Note: I can't stress this enough, make sure you review the script specified by Uri` before running the above_

If you wish to remove a module installed with the above method you can run;

```powershell
$module_path = (Get-Module -Name PInvokeHelper -ListAvailable).ModuleBase
Remove-Item -LiteralPath $module_path -Force -Recurse
```

## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the
changes. To test out your changes locally you can just run `.\build.ps1` in
PowerShell. This script will ensure all dependencies are installed before
running the test suite.

_Note: this requires PowerShellGet or WMF 5 to be installed_
