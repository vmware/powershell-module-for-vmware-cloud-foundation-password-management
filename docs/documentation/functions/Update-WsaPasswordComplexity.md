# Update-WsaPasswordComplexity

## SYNOPSIS

Update the Workspace ONE Access password complexity policy.

## SYNTAX

```powershell
Update-WsaPasswordComplexity [-server] <String> [-user] <String> [-pass] <String> [-minLength] <Int32>
 [-minLowercase] <Int32> [-minUppercase] <Int32> [-minNumeric] <Int32> [-minSpecial] <Int32>
 [-maxIdenticalAdjacent] <Int32> [-maxPreviousCharacters] <Int32> [-history] <Int32> [<CommonParameters>]
```

## DESCRIPTION

The Update-WsaPasswordComplexity cmdlet configures the password complexity policy for a Workspace ONE Access
instance.

- Validates that network connectivity and authentication is possible to Workspace ONE Access
- Configures the Workspace ONE Access password complexity policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-WsaPasswordComplexity -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -minLength 15 -minLowercase 1 -minUppercase 1 -minNumeric 1 -minSpecial 1 -maxIdenticalAdjacent 1 -maxPreviousCharacters 0 -history 5
```

This example configures the password complexity policy for Workspace ONE Access.

## PARAMETERS

### -server

The fully qualified domain name of the Workspace ONE Access instance.

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

The username to authenticate to the Workspace ONE Access instance.

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

The password to authenticate to the Workspace ONE Access instance.

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

### -minLength

The minimum number of characters that a password must contain.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -minLowercase

The minimum number of lowercase characters that a password must contain.

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

### -minUppercase

The minimum number of uppercase characters that a password must contain.

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

### -minNumeric

The minimum number of numeric characters that a password must contain.

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

### -minSpecial

The minimum number of special characters that a password must contain.

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

### -maxIdenticalAdjacent

The maximum number of identical adjacent characters that a password can contain.

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

### -maxPreviousCharacters

The maximum number of previous characters that a password can contain.

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

### -history

The number of previous passwords that a password cannot match.

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
