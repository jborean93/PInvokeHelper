---
external help file: PInvokeHelper-help.xml
Module Name: PInvokeHelper
online version:
schema: 2.0.0
---

# Import-Struct

## SYNOPSIS
Defines a struct.

## SYNTAX

```
Import-Struct [-ModuleBuilder] <ModuleBuilder> [-Name] <String> [-Fields] <Hashtable[]>
 [[-PackingSize] <PackingSize>] [<CommonParameters>]
```

## DESCRIPTION
Defines a struct in the ModuleBuilder specified.

## EXAMPLES

### EXAMPLE 1
```
$module_builder = New-DynamicModule -Name PInvokeHelper
```

$struct_definition = @{
    Name = 'TOKEN_PRIVILEGES'
    Fields = @(
        @{
            Name = 'PrivilegeCount'
            Type = (\[System.UInt32\])
        },
        @{
            Name = 'Privileges'
            Type = 'LUID_AND_ATTRIBUTES\[\]'
            MarshalAs = @{
                Type = \[System.Runtime.InteropServices.UnmanagedType\]::ByValArray
                SizeConst = 1
            }
        }
    )
}
Import-Struct -ModuleBuilder $module_builder @struct_definition

## PARAMETERS

### -ModuleBuilder
The ModuleBuilder to define the struct in.

```yaml
Type: ModuleBuilder
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the struct to define.

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

### -Fields
A list of hashes that define the fields of the struct.
Each value in the fields list should be a hash with the
following keys;

    Name: The name of the field.
    Type: The type of the field.
    MarshalAs: Optional hash that defines the MarshalAs attribute based on the Set-MarshalAsAttribute parameters.
        Type: Sets the \[MarshalAs(UnmanagedType.)\] value for the parameter.
        SizeConst: Optional SizeConst value for MarshalAs.
        ArraySubType: Optional ArraySubType value for MarshalAs.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PackingSize
Set the Pack value for the StructLayout attribute.

```yaml
Type: PackingSize
Parameter Sets: (All)
Aliases:
Accepted values: Unspecified, Size1, Size2, Size4, Size8, Size16, Size32, Size64, Size128

Required: False
Position: 4
Default value: Unspecified
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
