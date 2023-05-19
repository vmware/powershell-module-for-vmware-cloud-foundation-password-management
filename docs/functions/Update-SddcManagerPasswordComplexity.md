# Update-SddcManagerPasswordComplexity

## SYNOPSIS

Update the password complexity policy for SDDC Manager.

## SYNTAX

```powershell
Update-SddcManagerPasswordComplexity [-server] <String> [-user] <String> [-pass] <String> [-rootPass] <String>
 [-minLength] <Int32> [[-minLowercase] <Int32>] [[-minUppercase] <Int32>] [[-minNumerical] <Int32>]
 [[-minSpecial] <Int32>] [[-minUnique] <Int32>] [[-minClass] <Int32>] [[-maxSequence] <Int32>]
 [[-history] <Int32>] [[-maxRetry] <Int32>] [<CommonParameters>]
```

## DESCRIPTION

The Update-SddcManagerPasswordComplexity cmdlet configures the password complexity policy for SDDC Manager.
The cmdlet connects to SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Configures the password complexity policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -minLength 6 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -minClass 4 -maxSequence 0 -history 5 -maxRetry 3
```

This example configures the password complexity policy for SDDC Manager.

## PARAMETERS

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

### -rootPass

The password for the SDDC Manager appliance root account.

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

### -minLowercase

The minimum number of lowercase characters in the password.

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

### -minUppercase

The minimum number of uppercase characters in the password.

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

### -minNumerical

The minimum number of numerical characters in the password.

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

### -minSpecial

The minimum number of special characters in the password.

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

### -minUnique

The minimum number of unique characters in the password.

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

### -minClass

The minimum number of character classes in the password.

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

### -maxSequence

The maximum number of sequential characters in the password.

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

### -history

The number of previous passwords that a password cannot match.

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

### -maxRetry

The number of failed login attempts before the account is locked.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
