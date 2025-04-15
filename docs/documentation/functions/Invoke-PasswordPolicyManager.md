# Invoke-PasswordPolicyManager

## Synopsis

Generates a Password Policy Manager Report for a workload domain or all workload domains.

## Syntax

### All-WorkloadDomains

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <String> -sddcManagerUser <String> -sddcManagerPass <String> -sddcRootPass <String> -reportPath <String> [-allDomains] [-darkMode] [-drift] [-policyFile <String>] [-json] [-wsaFqdn <String>] [-wsaRootPass <String>] [-wsaAdminPass <String>] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <String> -sddcManagerUser <String> -sddcManagerPass <String> -sddcRootPass <String> -reportPath <String> -workloadDomain <String> [-darkMode] [-drift] [-policyFile <String>] [-json] [-wsaFqdn <String>] [-wsaRootPass <String>] [-wsaAdminPass <String>] [<CommonParameters>]
```

## Description

The `Invoke-PasswordPolicyManager` generates a Password Policy Manager Report for a workload domain or all workload domains.

## Examples

### Example 1

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <sddc_manager_fqdn> -sddcManagerUser <admin_username> -sddcManagerPass <admin_password> -sddcRootPass <root_password> -reportPath <report_path> -darkMode -allDomains
```

This example runs a password policy report for all workload domains within an SDDC Manager instance.

### Example 2

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <sddc_manager_fqdn> -sddcManagerUser <admin_username> -sddcManagerPass <admin_password> -sddcRootPass <root_password> -reportPath <report_path> -darkMode -allDomains -wsaFqdn <wsa_fqdn> -wsaRootPass <wsa_root_password> -wsaAdminPass <wsa_admin_password>
```

This example runs a password policy report for all workload domains within an SDDC Manager instance and Workspace ONE Access.

### Example 3

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <sddc_manager_fqdn> -sddcManagerUser <admin_username> -sddcManagerPass <admin_password> -sddcRootPass <root_password> -reportPath <report_path> -darkMode -workloadDomain <workload_domain_name>
```

This example runs a password policy report for a specific workload domain within an SDDC Manager instance.

### Example 4

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <sddc_manager_fqdn> -sddcManagerUser <admin_username> -sddcManagerPass <admin_password> -sddcRootPass <root_password> -reportPath <report_path> -darkMode -allDomains -drift -policyFile <policy_file>.json
```

This example runs a password policy report for all workload domains within an SDDC Manager instance and compares the configuration against the JSON provided.

### Example 5

```powershell
Invoke-PasswordPolicyManager -sddcManagerFqdn <sddc_manager_fqdn> -sddcManagerUser <admin_username> -sddcManagerPass <admin_password> -sddcRootPass <root_password> -reportPath <report_path> -darkMode -allDomains -drift
```

This example runs a password policy report for all workload domains within an SDDC Manager instance and compares the configuration against the product defaults.

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

The path to save the report to.

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

Switch to run the report for all workload domains.

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

Switch to run the report for a specific workload domain.

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

### -darkMode

Switch to use dark mode for the report.

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

### -policyFile

The path to the JSON file containing the policy configuration.

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

Switch to output the report in JSON format.

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

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
