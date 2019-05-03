---
external help file: PInvokeHelper-help.xml
Module Name: PInvokeHelper
online version:
schema: 2.0.0
---

# Import-Enum

## SYNOPSIS
Defines an enum.

## SYNTAX

```
Import-Enum [-ModuleBuilder] <ModuleBuilder> [-Name] <String> [-Type] <Type> [-Values] <IDictionary> [-Flags]
 [<CommonParameters>]
```

## DESCRIPTION
Defines an enum in the module builder specified.

## EXAMPLES

### EXAMPLE 1
```
$module_builder = New-DynamicModule -Name PInvokeHelper
```

Defines
    \[Flags\]
    public LogonFlags : uint
    {
        WithoutProfile = 0,
        WithProfile = 1,
        NetCredentialsOnly = 2
    }

$enum = @{
    ModuleBuilder = $module_builder
    Name = 'LogonFlags'
    Type = (\[System.UInt32\])
    Flags = $true
    Values = @{
        WithoutProfile = 0
        WithProfile = 1
        NetCredentialsOnly = 2
    }
}
Import-Enum @enum

Defines
    public TokenInformationClass : int
    {
        User = 1,
        Groups = 2,
        Privileges = 3
    }

$enum = @{
    ModuleBuilder = $module_builder
    Name = 'TokenInformationClass'
    Type = (\[System.Int32\])
    Values = @{
        User = 1
        Groups = 2
        Privileges = 3
    }
}
Import-Enum @enum

## PARAMETERS

### -ModuleBuilder
The ModuleBuilder object to define the enum in.

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
The name of the enum to define.

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

### -Type
The enum base type.

```yaml
Type: Type
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Values
A hashtable of enum key/values to define.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Flags
Whether the enum has the \[Flags\] attribute applied.

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

## NOTES

## RELATED LINKS
