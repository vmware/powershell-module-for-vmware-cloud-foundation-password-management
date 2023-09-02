# Publish-PasswordRotationPolicy

## Synopsis

Publishes the credential password rotation settings for credentials managed by SDDC Manager based on the resource type
for a specified workload domain.

## Syntax

### All-WorkloadDomains

```powershell
Publish-PasswordRotationPolicy -server <String> -user <String> -pass <String> [-allDomains] [-resource <String>] [-json] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-PasswordRotationPolicy -server <String> -user <String> -pass <String> -workloadDomain <String> [-resource <String>] [-json] [<CommonParameters>]
```

## Description

The `Publish-PasswordRotationPolicy` cmdlet retrieves the credential password rotation settings for credentials managed by SDDC Manager.

The cmdlet connects to the SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager.
- Retrives the credential password rotation settings based on the criteria specified by the -domain and -resource values or all resource types for all workload domains if no values are specified.

## Examples

### Example 1

```powershell
Publish-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -allDomains
```

This example publishes the credential password rotation settings for all resource types managed by SDDC Manager for all workload domains.

### Example 2

```powershell
Publish-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -workloadDomain sfo-m01
```

This example publishes the credential password rotation settings for all resource types managed by SDDC Manager for the sfo-m01 workload domain.

### Example 3

```powershell
Publish-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -resource nsxManager
```

This example publishes the credential password rotation settings for the NSX Manager accounts managed by SDDC Manager for all workload domains.

### Example 4

```powershell
Publish-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -workloadDomain sfo-m01 -resource nsxManager
```

This example publishes the credential password rotation settings for the NSX Manager accounts managed by SDDC Manager for the sfo-m01 workload domain.

### Example 5

```powershell
Publish-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -allDomains -json
```

This example publishes the credential password rotation settings for all resource types managed by SDDC Manager for all workload domains in JSON format.

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

### -resource

The resource type to publish the policy for. One of: sso, vcenterServer, nsxManager, nsxEdge, ariaLifecycle, ariaOperations, ariaOperationsLogs, ariaAutomation, workspaceOneAccess, backup.

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
