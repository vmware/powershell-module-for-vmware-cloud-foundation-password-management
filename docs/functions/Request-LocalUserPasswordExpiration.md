# Request-LocalUserPasswordExpiration

## SYNOPSIS

Retrieve local user password expiration policy.

## SYNTAX

```powershell
Request-LocalUserPasswordExpiration -server <String> -user <String> -pass <String> -domain <String>
 -vmName <String> -guestUser <String> -guestPassword <String> -localUser <Array> [-product <String>] [-drift]
 [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## DESCRIPTION

The Request-LocalUserPasswordExpiration cmdlet retrieves a local user password expiration policy.
The cmdlet connects to SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Retrives the local user password expiration policy

## EXAMPLES

### EXAMPLE 1

```powershell
Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root"
```

This example retrieves the global password expiration policy for the vCenter Server.

```powershell
Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root" -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the global password expiration policy for the vCenter Server and checks the configuration drift using the provided configuration JSON.

```powershell
Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root" -drift
```

This example retrieves the global password expiration policy for the vCenter Server and compares the configuration against the product defaults.

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

The name of the workload domain which the product is deployed for.

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

### -vmName

The name of the virtual machine to retrieve the policy from.

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

### -guestUser

The username to authenticate to the virtual machine guest operating system.

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

### -guestPassword

The password to authenticate to the virtual machine guest operating system.

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

### -localUser

The local user to retrieve the password expiration policy for.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -product

The product to retrieve the password expiration policy for.
One of: sddcManager, vcenterServer, nsxManager, nsxEdge, wsaLocal.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -drift

Switch to compare the current configuration against the product defaults or a JSON file.

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

### -reportPath

The path to save the policy report.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -policyFile

The path to the policy configuration file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
