---
external help file: PInvokeHelper-help.xml
Module Name: PInvokeHelper
online version:
schema: 2.0.0
---

# Get-Win32ErrorMessage

## SYNOPSIS
Gets the Win32 Error message.

## SYNTAX

```
Get-Win32ErrorMessage [-ErrorCode] <Int32> [<CommonParameters>]
```

## DESCRIPTION
Gets the Win32 Error message based on error code passed in

## EXAMPLES

### EXAMPLE 1
```
$res = [PInvoke]::CreatePipe(
```

\[Ref\]$ReadHandle,
    \[Ref\]$WriteHandle,
    0,
    0
); $err_code = \[System.Runtime.InteropServices.Marshal\]::GetLastWin32Error()

if (-not $res) {
    $msg = Get-Win32ErrorMessage -ErrorCode $err_code
    throw $msg
}

## PARAMETERS

### -ErrorCode
The error code to convert.
\When calling a PInvoke function this can be retrieved with
    \[System.Runtime.InteropServices.Marshal\]::GetLastWin32Error()

This should be done inline, e.g.
    \[PInvoke\]::Function(); $err_code = \[System.Runtime.InteropServices.Marshal\]::GetLastWin32Error()

Failure to do this in line may result in the wrong error code being retrieved.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String. The Win32 error message for the code specified.
## NOTES

## RELATED LINKS
