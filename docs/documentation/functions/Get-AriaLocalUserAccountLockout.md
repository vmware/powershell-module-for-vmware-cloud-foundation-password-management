# Get-AriaLocalUserAccountLockout

## Synopsis

Retrieves the password account lockout for local users.

## Syntax

```powershell
Get-AriaLocalUserAccountLockout -vmName <String> -guestUser <String> -guestPassword <String> [-vrni]
 [-product <String>] [-drift] [-version <String>] [-reportPath <String>] [-policyFile <String>]
 [<CommonParameters>]
```

## Description

The `Get-AriaLocalUserAccountLockout` cmdlets retrieves the password account lockout for local users.

## Examples

### Example 1

```powershell
Get-AriaLocalUserAccountLockout -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -product vra
```

This example retrieves the VMware Aria Automation account lockout policy.

### Example 2

```powershell
Get-AriaLocalUserAccountLockout -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -product vra -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the VMware Aria Automation account lockout policy and checks the configuration drift using the provided configuration JSON.

### Example 3

```powershell
Get-Get-AriaLocalUserAccountLockout -vmName sfo-vra01 -guestUser root -guestPassword VMw@re1! -product vra -drift
```

This example retrieves the VMware Aria Automation account lockout policy and compares the configuration against the product defaults.

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

The VMware Ariare Aria Operations for Networks flag.

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

The product to retrieve the password account lockout policy.

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
