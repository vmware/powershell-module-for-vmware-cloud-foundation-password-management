# Get-AriaLocalUserPasswordComplexity

## Synopsis

Retrieves the password complexity for local users.

## Syntax

```powershell
Get-AriaLocalUserPasswordComplexity -vmName <String> -guestUser <String> -guestPassword <String> [-vrni]
 [-product <String>] [-drift] [-version <String>] [-reportPath <String>] [-policyFile <String>]
 [<CommonParameters>]
```

## Description

The `Get-AriaLocalUserPasswordComplexity` cmdlets retrieves the password complexity for local users.

## Examples

### Example 1

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -product vra
```

This example retrieves the VMware Aria Automation password complexity.

### Example 2

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vrni01 -guestUser root -guestPassword VMw@re1!VMw@re1! -vrni
```

This example retrieves the VMware Aria Operations for Networks password complexity.

### Example 3

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -drift -product vra -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the VMware Aria Automation password complexity and checks the configuration drift using the provided configuration JSON.

### Example 4

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -drift -product vra
```

This example retrieves the VMware Aria Automation password complexity and compares the configuration against the product defaults.

### Example 5

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vrni01 -guestUser root -guestPassword VMw@re1! -drift -vrni -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the VMware Aria Operations for Networks password complexity and checks the configuration drift using the provided configuration JSON.

### Example 6

```powershell
Get-AriaLocalUserPasswordComplexity -vmName sfo-vrni01 -guestUser root -guestPassword VMw@re1! -drift -vrni
```

This example retrieves the VMware Aria Operations for Networks password complexity and compares the configuration against the product defaults.

## Parameters

### -vmName

The virtual machine name.

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

### -guestUser

The guest user name.

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

### -guestPassword

The guest user password.

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

### -vrni

The VMware Aria Operations for Networks flag.

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

### -product

The product to retrieve the password complexity policy.

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

### -drift

The configuration drift flag.

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

### -version

The product version.

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

### -reportPath

The report path.

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

The policy file.

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
