# Copyright: (c) 2019, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-Win32ErrorMessage {
    <#
    .SYNOPSIS
    Gets the Win32 Error message.

    .DESCRIPTION
    Gets the Win32 Error message based on error code passed in

    .PARAMETER ErrorCode
    The error code to convert. \When calling a PInvoke function this can be retrieved with
        [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    This should be done inline, e.g.
        [PInvoke]::Function(); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    Failure to do this in line may result in the wrong error code being retrieved.

    .OUTPUTS
    System.String. The Win32 error message for the code specified.

    .EXAMPLE
    $res = [PInvoke]::CreatePipe(
        [Ref]$ReadHandle,
        [Ref]$WriteHandle,
        0,
        0
    ); $err_code = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if (-not $res) {
        $msg = Get-Win32ErrorMessage -ErrorCode $err_code
        throw $msg
    }
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Int32]
        $ErrorCode
    )

    $exp = New-Object -TypeName System.ComponentModel.Win32Exception -ArgumentList $ErrorCode
    ('{0} (Win32 ErrorCode {1} - 0x{1:X8})' -f $exp.Message, $ErrorCode)
}