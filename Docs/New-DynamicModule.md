---
external help file: PInvokeHelper-help.xml
Module Name: PInvokeHelper
online version:
schema: 2.0.0
---

# New-DynamicModule

## SYNOPSIS
Creates a dynamic module.

## SYNTAX

```
New-DynamicModule [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Creates a dynamic module that can then be used by other functions in PInvokeHelper when defining other structs,
enums, and methods.

## EXAMPLES

### EXAMPLE 1
```
New-DynamicModule -Name PInvokeHelper
```

## PARAMETERS

### -Name
The unique assembly and module name to define the builder in.
The assembly with be "$($Name)Assembly" and the
module will be "$($Name)Module".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Creates a dynamic module that can be used to define further types like classes, enums, structs and so forth.
## NOTES

## RELATED LINKS
