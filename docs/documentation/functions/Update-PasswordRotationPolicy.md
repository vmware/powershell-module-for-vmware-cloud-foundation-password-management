# Update-PasswordRotationPolicy

## Synopsis

Updates the credential password rotation settings for a credential managed by SDDC Manager.

## Syntax

```powershell
Update-PasswordRotationPolicy [-server] <String> [-user] <String> [-pass] <String> [-domain] <String> [-resource] <String> [-resourceName] <String> [-credential] <String> [-credentialName] <String> [-autoRotate] <String> [[-frequencyInDays] <Int32>] [<CommonParameters>]
```

## Description

The `Update-PasswordRotationPolicy` cmdlet updates the credential password rotation settings for a credential managed by SDDC Manager. The cmdlet connects to the SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager.
- Updates the credential password rotation settings based on the credential criteria specified.

## Examples

### Example 1

```powershell
Update-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -resource vcenterServer -resourceName sfo-m01-vc01.sfo.rainpole.io -credential SSH -credentialName root -autoRotate disabled
```

This example disables the credential password rotation settings for a credential managed by SDDC Manager.

### Example 2

```powershell
Update-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -resource vcenterServer -resourceName sfo-m01-vc01.sfo.rainpole.io -credential SSH -credentialName root -autoRotate enabled -frequencyInDays 90
```

This example enables the credential password rotation settings for a credential managed by SDDC Manager.

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

The name of the workload domain to retrieve the credential password rotation settings for.

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

### -resource

The resource type to retrieve the credential password rotation settings for.
One of: sso, vcenterServer, nsxManager, nsxEdge, ariaLifecycle, ariaOperations, ariaOperationsLogs, ariaAutomation, workspaceOneAccess, backup.

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

### -resourceName

The name of the resource to retrieve the credential password rotation settings for.

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

### -credential

The credential type to retrieve the user password rotation settings for.
One of: ssh, api, audit, sso.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -credentialName

The name of the credential to retrieve the user password rotation settings for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -autoRotate

Enable or disable the credential password rotation for the credential by SDDC Manager.
One of: enabled, disabled.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -frequencyInDays

The number of days of warning before credential's password will be automatically rotated by SDDC Manager.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
