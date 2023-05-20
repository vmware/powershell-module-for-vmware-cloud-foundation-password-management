# Publish-VcenterLocalPasswordExpiration

## SYNOPSIS

Publish password expiration policy for each local user of vCenter Server.

## SYNTAX

### All-WorkloadDomains

```powershell
Publish-VcenterLocalPasswordExpiration -server <String> -user <String> -pass <String> [-allDomains] [-drift]
 [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-VcenterLocalPasswordExpiration -server <String> -user <String> -pass <String> -workloadDomain <String>
 [-drift] [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

## DESCRIPTION

The Publish-VcenterLocalPasswordExpiration cmdlet returns password expiration policy for SDDC Manager.
The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Collects password expiration policy for each local user of vCenter Server

## EXAMPLES

### EXAMPLE 1

```powershell
Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
```

This example will return password expiration policy for each local user of vCenter Server for all Workload Domains.

```powershell
Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example will return password expiration policy for each local user of vCenter Server and checks the configuration drift using the provided configuration JSON.

```powershell
Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
```

This example will return password expiration policy for each local user of vCenter Server and compares the configuration against the product defaults.

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

### -allDomains

Switch to publish the policy for all workload domains.

```yaml
Type: SwitchParameter
Parameter Sets: All-WorkloadDomains
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -workloadDomain

Switch to publish the policy for a specific workload domain.

```yaml
Type: String
Parameter Sets: Specific-WorkloadDomain
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

### -json

Switch to publish the policy in JSON format.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
