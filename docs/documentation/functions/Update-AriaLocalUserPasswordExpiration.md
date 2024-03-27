# Update-AriaLocalUserPasswordExpiration

## Synopsis

Configure password account lockout for local users.

## Syntax

```powershell
Update-AriaLocalUserPasswordExpiration [-server] <String> [-user] <String> [-pass] <String> [-product] <String>
 [[-localuser] <Array>] [[-maxdays] <Int32>] [[-mindays] <Int32>] [[-warndays] <Int32>] [-json]
 [[-policyPath] <String>] [[-policyFile] <String>] [<CommonParameters>]
```

## Description

The `Update-AriaLocalUserPasswordExpiration` cmdlet configures the password expiration for local users

## Examples

### Example 1

```powershell
Update-AriaLocalUserPasswordExpiration -server sf0-vcf01 -user admin@local -pass VMware1!VMware1 -product vra -localuser root -maxdays 90 -mindays 7 -warndays 7
```

This Example updates the VMware Aria Automation nodes with new values for each element.

### Example 2

```powershell
Update-AriaLocalUserPasswordExpiration -server sf0-vcf01 -user admin@local -pass VMware1!VMware1 -product vra -json -reportPath "F:\" -policyFile "passwordPolicyConfig.json"
```

This example updates the VMware Aria Automation using Jthe SON file of preset values.

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

### -localuser

The local user to configure.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxdays

The maximum number of days between password change.

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

### -mindays

The minimum number of days between password change.

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

### -warndays

The number of days before password expiration that a user is warned that password will expire.

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
Position: 9
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
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
