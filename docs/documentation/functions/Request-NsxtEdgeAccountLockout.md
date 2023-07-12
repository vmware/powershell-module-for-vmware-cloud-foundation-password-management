# Request-NsxtEdgeAccountLockout

## Synopsis

Retrieves the account lockout policy for NSX Edge nodes.

## Syntax

```powershell
Request-NsxtEdgeAccountLockout -server <String> -user <String> -pass <String> -domain <String> [-drift] [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## Description

The `Request-NsxtEdgeAccountLockout` cmdlet retrieves the account lockout policy for NSX Edge nodes within a workload domain.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-password` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to NSX Local Manager
- Retrieves the account lockout policy

## Examples

### Example 1

```powershell
Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
```

This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain.

### Example 2

```powershell
Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain and checks the configuration drift using the provided configuration JSON.

### Example 3

```powershell
Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
```

This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain and compares the configuration against the product defaults.

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

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -domain

The name of the workload domain to retrieve the policy from.

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

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
