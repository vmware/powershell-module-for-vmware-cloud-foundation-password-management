# Publish-VcenterLocalAccountLockout

## Synopsis

Publish account lockout policy for each vCenter Server for a workload domain or all workload domains.

## Syntax

### All-WorkloadDomains

```powershell
Publish-VcenterLocalAccountLockout -server <String> -user <String> -pass <String> [-allDomains] [-drift] [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-VcenterLocalAccountLockout -server <String> -user <String> -pass <String> -workloadDomain <String> [-drift] [-reportPath <String>] [-policyFile <String>] [-json] [<CommonParameters>]
```

## Description

The `Publish-VcenterLocalAccountLockout` cmdlet returns account lockout policy for an SDDC Manager.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-password` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Collects password account lockout for each vCenter Server

## Examples

### Example 1

```powershell
Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
```

This example returns password account lockout for each vCenter Server for all workload domains.

### Example 2

```powershell
Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
```

This example returns password account lockout for a vCenter Server.

### Example 3

```powershell
Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example returns password account lockout for a vCenter Server and checks the configuration drift using the provided configuration JSON.

### Example 4

```powershell
Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
```

This example returns password account lockout for a vCenter Server and compares the configuration against the product defaults.

## Parameters

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
