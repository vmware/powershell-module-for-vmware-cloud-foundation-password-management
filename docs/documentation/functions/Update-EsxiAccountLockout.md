# Update-EsxiAccountLockout

## Synopsis

Updates ESXi account lockout policy.

## Syntax

```powershell
Update-EsxiAccountLockout [-server] <String> [-user] <String> [-pass] <String> [-domain] <String> [-cluster] <String> [-failures] <Int32> [-unlockInterval] <Int32> [[-detail] <String>] [<CommonParameters>]
```

## Description

The `Update-EsxiAccountLockout` cmdlet configures the account lockout policy on ESXi.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that the workload domain exists in the SDDC Manager inventory
- Validates that network connectivity and authentication is possible to vCenter Server
- Gathers the ESXi hosts for the cluster specificed
- Configures the account lockout policy for all ESXi hosts in the cluster

## Examples

### Example 1

```powershell
Update-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -failures 5 -unlockInterval 900
```

This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01.

### Example 2

```powershell
Update-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -failures 5 -unlockInterval 900 -detail false
```

This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01 but does not show the detail per host.

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

### -failures

The number of failed login attempts before the account is locked.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -unlockInterval

The number of seconds before a locked out account is unlocked.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
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
Position: 8
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
