# Update-VcenterRootPasswordExpiration

## SYNOPSIS

Update the root user password expiration policy.

## SYNTAX

### expire

```powershell
Update-VcenterRootPasswordExpiration -server <String> -user <String> -pass <String> -domain <String>
 [-email <String>] [-maxDays <String>] [-warnDays <String>] [<CommonParameters>]
```

### neverexpire

```powershell
Update-VcenterRootPasswordExpiration -server <String> -user <String> -pass <String> -domain <String>
 [-neverexpire] [<CommonParameters>]
```

## DESCRIPTION

The Update-VcenterRootPasswordExpiration cmdlet configures the root user password expiration policy of a
vCenter Server.
The cmdlet connects to SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Configures the root user password expiration policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -email "admin@rainpole.io" -maxDays 999 -warnDays 14

```

This example configures the configures password expiration settings for the vCenter Server root account to expire after 999 days with email for warning set to "<admin@rainpole.io>".

```powershell
Update-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -neverexpire
```

This example configures the configures password expiration settings for the vCenter Server root account to never expire.

## PARAMETERS

### -server

The fully qualified domain name of the SDDC Manager instance.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
Position: Named
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
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -email

The email address to send password expiration warnings to.

```yaml
Type: String
Parameter Sets: expire
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxDays

The maximum number of days before the root user password expires.

```yaml
Type: String
Parameter Sets: expire
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -warnDays

The number of days before the root user password expires in which to send a warning email.

```yaml
Type: String
Parameter Sets: expire
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -neverexpire

Switch to configure the root user password to never expire.

```yaml
Type: SwitchParameter
Parameter Sets: neverexpire
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
