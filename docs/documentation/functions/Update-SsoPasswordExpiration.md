# Update-SsoPasswordExpiration

## SYNOPSIS

Update the vCenter Single Sign-On password expiration policy.

## SYNTAX

```powershell
Update-SsoPasswordExpiration [-server] <String> [-user] <String> [-pass] <String> [-domain] <String>
 [-maxDays] <Int32> [<CommonParameters>]
```

## DESCRIPTION

The Update-SsoPasswordExpiration cmdlet configures the password expiration policy of a vCenter Single Sign-On
domain.
The cmdlet connects to SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Configures the vCenter Single Sign-On password expiration policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-SsoPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -maxDays 999
```

This example configures the password expiration policy for a vCenter Single Sign-On domain.

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

### -maxDays

The maximum number of days that a password is valid for.

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
