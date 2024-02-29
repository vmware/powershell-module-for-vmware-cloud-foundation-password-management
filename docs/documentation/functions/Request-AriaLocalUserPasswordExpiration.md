# Request-AriaLocalUserPasswordExpiration

## Synopsis

Retrieves the VMware Aria product password expiration.

## Syntax

```powershell
Request-AriaLocalUserPasswordExpiration -server <String> -user <String> -pass <String> [-product <String>] [-drift]
 [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## Description

The `Request-pcaPasswordExpiration` cmdlet retrieves the VMware Aria Automation password expiration policy.

- Validates that network connectivity and authentication is possible to SDDC Manager.
- Validates that network connectivity and authentication is possible to VMware Aria Suite Lifecycle.
- Retrieves the password expiration policy.

## Examples

### Example 1

```powershell
Request-AriaLocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.com -pass VMw@re1! -product vra
```

This example retrieves the password expiration policy for VMware Aria Automation instances.

### Example 2

```powershell
Request-AriaLocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.com -pass VMw@re1! -product vra -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the password expiration policy for VMware Aria Automation instances and checks the configuration drift using the provided configuration JSON.

### Example 3

```powershell
Request-AriaLocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.com -pass VMw@re1! -product vra -drift
```

This example retrieves the password expiration policy for VMware Aria Automation instances and compares the configuration against the product defaults.

### Example 4

```powershell
Request-AriaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VM@re1!VMware1! -vidm -settings directory.
```

This example retrieves the password expiration policy for Workspace ONE Access directory users.

### Example 5

```powershell
Request-AriaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VM@re1!VMware1! -vidm -settings directory -vidmdrift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the password expiration policy for Workspace ONE Access directory users and checks the configuration drift using the provided configuration JSON.

### Example 6

```powershell
Request-AriaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VM@re1!VMware1! -vidm -settings directory -vidmdrift
```

This example retrieves the password expiration policy for Workspace ONE Access directory users and compares the configuration against the product defaults.

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

### -product

The product to retrieve the password expiration policy.

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

### -vidm

Switch to retrieve the password complexity policy for VMware Aria Lifecycle Workspace One.

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

### -settings

The settings to retrieve the password expiration policy for VMware Aria Lifecycle Workspace One. One of: directory, localuser.

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

### -vidmdrift

Switch to compare the current configuration against the product defaults or a JSON file for Aria Lifecycle Workspace One.

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

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
