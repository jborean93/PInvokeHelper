---
external help file: PInvokeHelper-help.xml
Module Name: PInvokeHelper
online version:
schema: 2.0.0
---

# Import-PInvokeMethod

## SYNOPSIS
Defines a Win32 function as a PInvoke method.

## SYNTAX

```
Import-PInvokeMethod [-TypeBuilder] <TypeBuilder> [-DllName] <String> [-Name] <String> [-ReturnType] <Object>
 [[-ParameterTypes] <Object[]>] [-SetLastError] [[-CharSet] <CharSet>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Defines a Win32 function as a PInvoke method and control some of the marshaling techniques used for that function.

## EXAMPLES

### EXAMPLE 1
```
$module_builder = New-DynamicModule -Name PInvokeHelper
```

$type_builder = $module_buidler.DefineType('PInvokeHelper.NativeMethods', 'Public, Class')

$function_definition = @{
    DllName = 'Kernel32.dll'
    Name = 'CreateProcessW'
    ReturnType = (\[System.Boolean\])
    ParameterTypes = @(
        @{
            Type = (\[System.String\])
            MarshalAs = @{
                Type = \[System.Runtime.InteropServices.UnmanagedType\]::LPWStr
            }
        },
        \[System.Text.StringBuilder\],
        \[System.IntPtr\],
        \[System.IntPtr\],
        \[System.Boolean\],
        \[PSLimitedProcess.ProcessCreationFlags\],
        \[System.IntPtr\],
        @{
            Type = (\[System.String\])
            MarshalAs = @{
                Type = \[System.Runtime.InteropServices.UnmanagedType\]::LPWStr
            }
        },
        @{ Ref = $true; Type = \[PSLimitedProcess.STARTUPINFOEX\] },
        @{ Ref = $true; Type = \[PSLimitedProcess.PROCESS_INFORMATION\] }
    )
    SetLastError = $true
}
Import-PInvokeMethod -TypeBuilder $type_builder @function_definition

# Call once all functions have been defined in the type/class
$type_builder.CreateType() \> $null

## PARAMETERS

### -TypeBuilder
A TypeBuilder that represents the class to define the static methods in.

```yaml
Type: TypeBuilder
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DllName
The name of the Dll that contains the function to import.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the Win32 function to import.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnType
The type that is returned by the function.
Can also be a Hashtable with the following keys;

    Type: The type of the return value of the function.
    MarshalAs: An optional hash that contains the parameter for Set-MarshalAsAttribute.
        Type: Sets the \[MarshalAs(UnmanagedType.)\] value for the parameter.
        SizeConst: Optional SizeConst value for MarshalAs.
        ArraySubType: Optional ArraySubType value for MarshalAs.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParameterTypes
A list of types of the functions parameters.
Each parameter is represented by a \[Type\] value for a simple
parameter type but can also be a hashtable with the following keys;

    Type: Must be set to the type of the parameter
    Ref: Whether it is a \[Ref\] type, e.g.
is ref or has an out parameter in .NET.
    MarshalAs: An optional hash that contains the parameter for Set-MarshalAsAttribute.
        Type: Sets the \[MarshalAs(UnmanagedType.)\] value for the parameter.
        SizeConst: Optional SizeConst value for MarshalAs.
        ArraySubType: Optional ArraySubType value for MarshalAs.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: [Object[]]@()
Accept pipeline input: False
Accept wildcard characters: False
```

### -SetLastError
Sets the 'SetLastError=true' field on the DllImport attribute of the function.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CharSet
Sets the 'CharSet' field on the DllImport attribute of the function.

```yaml
Type: CharSet
Parameter Sets: (All)
Aliases:
Accepted values: None, Ansi, Unicode, Auto

Required: False
Position: 6
Default value: Auto
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Output the MethodBuilder of the defined function.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None, System.Reflection.Emit.MethodBuilder
### This cmdlet generates a System.Reflection.Emit.MethodInfo if you specify -PassThru, Otherwise this cmdlet does not
### return any output.
## NOTES

## RELATED LINKS
