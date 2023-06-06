# Request-EsxiPasswordExpiration

## SYNOPSIS

Retrieves ESXi host password expiration.

## SYNTAX

```powershell
Request-EsxiPasswordExpiration -server <String> -user <String> -pass <String> -domain <String>
 -cluster <String> [-drift] [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## DESCRIPTION

The Request-EsxiPasswordExpiration cmdlet retrieves a list of ESXi hosts for a cluster displaying the currently
configured password expiration policy (Advanced Setting Security.PasswordMaxDays).
The cmdlet connects to SDDC
Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that the workload domain exists in the SDDC Manager inventory
- Validates that network connectivity and authentication is possible to vCenter Server
- Gathers the ESXi hosts for the cluster specificed
- Retrieve all ESXi hosts password expiration policy

## EXAMPLES

### EXAMPLE 1

```powershell
Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01
```

This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01.

### EXAMPLE 2

```powershell
Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and checks the configuration drift using the provided configuration JSON.

### EXAMPLE 3

```powershell
Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift
```

This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and compares the configuration against the product defaults.

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

The name of the workload domain to retrieve the policy from.

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

### -cluster

The name of the cluster to retrieve the policy from.

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
