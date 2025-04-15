# Update-EsxiPasswordExpiration

## Synopsis

Updates the password expiration period in days for all ESX hosts in a cluster.

## Syntax

```powershell
Update-EsxiPasswordExpiration [-server] <String> [-user] <String> [-pass] <String> [-domain] <String> [-cluster] <String> [-maxDays] <String> [[-detail] <String>] [<CommonParameters>]
```

## Description

The `Update-EsxiPasswordExpiration` cmdlet configures the password expiration policy on ESXi.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that the workload domain exists in the SDDC Manager inventory
- Validates that network connectivity and authentication is possible to vCenter
- Gathers the ESX hosts for the cluster specified
- Configures the password expiration policy for all ESX hosts in the cluster

## Examples

### Example 1

```powershell
Update-EsxiPasswordExpiration -server <fqdn> -user <admin_username> -pass <admin_password> -domain <workload_domain_name> -cluster <cluster_name> -maxDays 999
```

This example configures all ESX hosts within the cluster named in the workload domain.

### Example 2

```powershell
Update-EsxiPasswordExpiration -server <fqdn> -user <admin_username> -pass <admin_password> -domain <workload_domain_name> -cluster <cluster_name> -maxDays 999 -detail false
```

This example configures all ESX hosts within the cluster named in the workload domain but does not show the detail per host.

## Parameters

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

### -cluster

The name of the cluster to update the policy for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxDays

The maximum number of days before the password expires.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
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
Position: 7
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
