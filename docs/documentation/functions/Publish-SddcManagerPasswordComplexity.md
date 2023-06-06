# Publish-SddcManagerPasswordComplexity

## SYNOPSIS

Publish password complexity policy for SDDC Manager.

## SYNTAX

### All-WorkloadDomains

```powershell
Publish-SddcManagerPasswordComplexity -server <String> -user <String> -pass <String> -sddcRootPass <String>
 [-allDomains] [-drift] [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-SddcManagerPasswordComplexity -server <String> -user <String> -pass <String> -sddcRootPass <String>
 -workloadDomain <String> [-drift] [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

## DESCRIPTION

The Publish-SddcManagerPasswordComplexity cmdlet returns password complexity policy for SDDC Manager.
The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Collects password complexity policy for SDDC Manager

## EXAMPLES

### EXAMPLE 1

```powershell
Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -allDomains
```

This example will return password complexity policy for SDDC Manager.

### EXAMPLE 2

```powershell
Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-w01
```

This example will NOT return the password complexity policy for SDDC Manager as the Workload Domain provided is not the Management Domain.

### EXAMPLE 3

```powershell
Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example will return the password complexity policy for SDDC Manager and compare the configuration against passwordPolicyConfig.json.

### EXAMPLE 4

```powershell
Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift
```

This example will return the password complexity policy for SDDC Manager and compare the configuration against the product defaults.

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

### -sddcRootPass

The password for the SDDC Manager appliance root account.

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

Switch to return the policy for all workload domains.

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

Switch to return the policy for a specific workload domain.

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
