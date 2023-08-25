# Request-PasswordRotationPolicy

## Synopsis

Retrieves the password rotation settings for accounts managed by SDDC Manager based on the resource type
for a specified workload domain.

## Syntax

```powershell
Request-PasswordRotationPolicy [-server] <String> [-user] <String> [-pass] <String> [[-domain] <String>] [[-resource] <String>] [<CommonParameters>]
```

## Description

The `Request-PasswordRotationPolicy`` cmdlet retrieves the password rotation settings for accounts managed by SDDC Manager.

The cmdlet connects to the SDDC Manager using the -server, -user, and -pass values:

- Validates that network connectivity and authentication is possible to SDDC Manager.
- Retrives the password rotation settings based on the criteria specified by the -domain and -resource values or all resource types for all workload domains if no values are specified.

## Examples

### Example 1

```powershell
Request-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1!
```

This example retrieves the password rotation settings for all resource types managed by SDDC Manager for all workload domains.

### Example 2

```powershell
Request-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
```

This example retrieves the password rotation settings for all resource types managed by SDDC Manager for the sfo-m01 workload domain.

### Example 3

```powershell
Request-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -resource nsxManager
```

This example retrieves the password rotation settings for the NSX Manager accounts managed by SDDC Manager for all workload domains.

### Example 4

```powershell
Request-PasswordRotationPolicy -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -resource nsxManager
```

This example retrieves the password rotation settings for the NSX Manager accounts managed by SDDC Manager for the sfo-m01 workload domain.

## PARAMETERS

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

The name of the workload domain to retrieve the user password rotation settings for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -resource

The resource type to retrieve the user password rotation settings for. One of: sso, vcenterServer, nsxManager, nsxEdge, ariaLifecycle, ariaOperations, ariaOperationsLogs, ariaAutomation, workspaceOneAccess, backup.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
