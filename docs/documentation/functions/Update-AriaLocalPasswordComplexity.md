# Update-AriaLocalUserPasswordComplexity

## Synopsis

Configure password complexity for local users.

## Syntax

```powershell
Update-AriaLocalUserPasswordComplexity [-server] <String> [-user] <String> [-pass] <String> [-product] <String>
 [[-minLength] <Int32>] [[-uppercase] <Int32>] [[-lowercase] <Int32>] [[-numerical] <Int32>]
 [[-special] <Int32>] [[-unique] <Int32>] [[-history] <Int32>] [[-retry] <Int32>] [[-class] <Int32>]
 [[-sequence] <Int32>] [-json] [[-policyPath] <String>] [[-policyFile] <String>] [<CommonParameters>]
```

## DESCRIPTION

The `Update-AriaLocalUserPasswordComplexity` cmdlet configures the password complexity for local users

## Examples

### Example 1

```powershell
Update-AriaLocalUserPasswordComplexity -server sf0-vcf01 -user admin@local -pass VMware1!VMware1 -product vra -minLength 7 -uppercase 1 -lowercase 1 -numerical 1 -special 1 -unique 5 -history 3 -retry 3 -class 3 -sequence 3
```

This Example updates the VMware Aria Automation nodes with new values for each element.

### Example 2

```powershell
Update-AriaLocalUserPasswordComplexity -server sf0-vcf01 -user admin@local -pass VMware1!VMware1 -product vra -json -reportPath "F:\" -policyFile "passwordPolicyConfig.json"
```

This Example updates the VMware Aria Automation using Jthe SON file of preset values.

## Parameters

### -server

The fully qualified domain name of the SDDC Manager instance.

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

### -user

The username to authenticate to the SDDC Manager instance.

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

### -pass

The password to authenticate to the SDDC Manager instance.

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

### -product

The product to configure.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -minLength

The minimum number of characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -uppercase

The maximum number of uppercase characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -lowercase

The maximum number of lowercase characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -numerical

The maximum number of numerical characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -special

The maximum number of special characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -unique

The minimum number of unique characters in a password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -history

The number of passwords to remember.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -retry

The number of retries.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -class

The minimum number of character classes.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -sequence

The maximum number of repeated characters.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -json

Use a JSON file to configure the password complexity.

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

### -policyPath

The path to the policy file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -policyFile

The path to the policy file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
