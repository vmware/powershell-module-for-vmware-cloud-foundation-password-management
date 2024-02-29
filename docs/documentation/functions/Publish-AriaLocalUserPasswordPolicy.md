# Publish-AriaLocalUserPasswordPolicy

## Synopsis

Publishes the password policies for Aria product local users.

## Syntax

### All-WorkloadDomains

```powershell
Publish-AriaLocalUserPasswordPolicy -server <String> -user <String> [-pass <String>] -policy <String> [-drift]
 [-reportPath <String>] [-policyFile <String>] [-json] [-allDomains] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-AriaLocalUserPasswordPolicy -server <String> -user <String> [-pass <String>] -policy <String> [-drift]
 [-reportPath <String>] [-policyFile <String>] [-json] -workloadDomain <String> [<CommonParameters>]
```

## Description

The `Publish-AriaLocalUserPasswordPolicy` cmdlet retrieves the requested password policy for all ESXi hosts and converts
the output to HTML.

The cmdlet connects to the SDDC Manager using the -server, -user, and -pass values:

- Validates that network connectivity and authentication is possible to SDDC Manager.
- Validates which VMware Aria products are installed.

## Examples

### Example 1

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -allDomains
```

This example returns password expiration policy for all VMware Aria products for all domains.

### Example 2

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-m01
```

This example returns password expiration policy for all VMware Aria products for the management domain.

### Example 3

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -allDomains
```

This example returns password complexity policy for all VMware Aria products for all domains.

### Example 4

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -workloadDomain sfo-m01
```

This example returns password complexity policy for all VMware Aria products for the management domain.

### Example 5

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -allDomains
```

This example returns password account lockout policy for all VMware Aria products for all domains.

### Example 6

```powershell
Publish-AriaLocalUserPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -workloadDomain sfo-m01
```

This example returns password account lockout policy for all VMware Aria products for the management domain.

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

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -policy

The policy to publish.

One of: `PasswordExpiration`, `PasswordComplexity`, `AccountLockout`.

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

### Common Parameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
