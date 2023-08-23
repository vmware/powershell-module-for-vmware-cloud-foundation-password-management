# Start-PasswordPolicyConfig

## Synopsis

Configures all password policies.

## Syntax

```powershell
Start-PasswordPolicyConfig -sddcManagerFqdn <String> -sddcManagerUser <String> -sddcManagerPass <String> -sddcRootPass <String> -reportPath <String> -policyFile <String> [-wsaFqdn <String>] [-wsaRootPass <String>] [-wsaAdminPass <String>] [<CommonParameters>]
```

## Description

The `Start-PasswordPolicyConfig` configures the password policies across all components of the VMware Cloud Foundation instance using the JSON configuration file provided.

## Examples

### Example 1

```powershell
Start-PasswordPolicyConfig -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This examples configures all password policies for all components across a VMware Cloud Foundation instance.

### Example 2

```powershell
Start-PasswordPolicyConfig -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json" -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -wsaAdminPass VMw@re1!
```

This example configures all password policies for all components across a VMware Cloud Foundation instance and a Workspace ONE Access instance.

## Parameters

### -sddcManagerFqdn

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

### -sddcManagerUser

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

### -sddcManagerPass

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

### -reportPath

The path to save the policy report.

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

### -policyFile

The path to the JSON file containing the policy configuration.

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

### -wsaFqdn

The fully qualified domain name of the Workspace ONE Access instance.

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

### -wsaRootPass

The password for the Workspace ONE Access appliance root account.

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

### -wsaAdminPass

The password for the Workspace ONE Access admin account.

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
