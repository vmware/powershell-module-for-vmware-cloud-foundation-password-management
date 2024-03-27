# Invoke-PasswordRotationManager

## Synopsis

Generates a Password Rotation Manager Report for a workload domain or all workload domains.

## Syntax

### All-WorkloadDomains

```powershell
Invoke-PasswordRotationManager -sddcManagerFqdn <String> -sddcManagerUser <String> -sddcManagerPass <String> -sddcRootPass <String> -reportPath <String> [-allDomains] [-darkMode] [-json] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Invoke-PasswordRotationManager -sddcManagerFqdn <String> -sddcManagerUser <String> -sddcManagerPass <String> -sddcRootPass <String> -reportPath <String> -workloadDomain <String> [-darkMode] [-json] [<CommonParameters>]
```

## Description

The `Invoke-PasswordRotationManager` generates a Password Rotation Manager Report for a workload domain or all workload domains.

## Examples

### Example 1

```powershell
Invoke-PasswordRotationManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath "F:\Reporting" -darkMode -allDomains
```

This example runs a password rotation report for all workload domains within an SDDC Manager instance.

### Example 2

```powershell
Invoke-PasswordRotationManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath "F:\Reporting" -darkMode -workloadDomain sfo-w01
```

This example runs a password rotation report for a specific Workload Domain within an SDDC Manager instance.

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

### Common Parameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
