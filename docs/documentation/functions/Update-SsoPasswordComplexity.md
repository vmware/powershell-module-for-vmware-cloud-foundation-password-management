# Update-SsoPasswordComplexity

## Synopsis

Updates the password complexity policy for a vCenter Single Sign-On domain.

## Syntax

```powershell
Update-SsoPasswordComplexity [-server] <String> [-user] <String> [-pass] <String> [-domain] <String> [-minLength] <Int32> [-maxLength] <Int32> [-minAlphabetic] <Int32> [-minLowercase] <Int32> [-minUppercase] <Int32> [-minNumeric] <Int32> [-minSpecial] <Int32> [-maxIdenticalAdjacent] <Int32> [-history] <Int32> [<CommonParameters>]
```

## Description

The `Update-SsoPasswordComplexity` cmdlet configures the password complexity policy of a vCenter Single Sign-On domain.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-password` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Configures the vCenter Single Sign-On password complexity policy

## Examples

### Example 1

```powershell
Update-SsoPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 15 -maxLength 20 -minAlphabetic 2 -minLowercase 1 -minUppercase 1 -minNumeric 1 -minSpecial 1 -maxIdenticalAdjacent 1 -history 5
```

This example configures the password complexity policy for a vCenter Single Sign-On domain.

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

### -domain

The name of the workload domain to update the policy for.

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

The minimum length of the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxLength

The maximum length of the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minAlphabetic

The minimum number of alphabetic characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minLowercase

The minimum number of lowercase characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minUppercase

The minimum number of uppercase characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minNumeric

The minimum number of numeric characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minSpecial

The minimum number of special characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 11
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxIdenticalAdjacent

The maximum number of identical adjacent characters in the password.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 12
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -history

The number of previous passwords that a password cannot match.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 13
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
