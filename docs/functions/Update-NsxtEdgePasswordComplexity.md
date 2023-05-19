# Update-NsxtEdgePasswordComplexity

## SYNOPSIS

Configure the password complexity policy for NSX Edge.

## SYNTAX

```powershell
Update-NsxtEdgePasswordComplexity [-server] <String> [-user] <String> [-pass] <String> [-domain] <String>
 [-minLength] <Int32> [[-minLowercase] <Int32>] [[-minUppercase] <Int32>] [[-minNumerical] <Int32>]
 [[-minSpecial] <Int32>] [[-minUnique] <Int32>] [[-maxRetry] <Int32>] [[-detail] <String>] [<CommonParameters>]
```

## DESCRIPTION

The Update-NsxtEdgePasswordComplexity cmdlet updates the password complexity policy for each NSX Edge
node for a workload domain.
The cmdlet connects to SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to NSX Local Manager
- Updates the password complexity policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-NsxtEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 15 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -maxRetry 3
```

This example updates the password complexity policy for each NSX Edge node for a workload domain.

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

### -domain

The name of the workload domain to retrieve the policy from.

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

### -maxRetry

The maximum number of retries before the account is locked.

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

### -detail

Return the details of the policy.
One of true or false.
Default is true.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
