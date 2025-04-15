# Request-SddcManagerAccountLockout

## Synopsis

Retrieves the account lockout policy for an SDDC Manager.

## Syntax

```powershell
Request-SddcManagerAccountLockout -server <String> -user <String> -pass <String> -rootPass <String> [-drift] [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## Description

The `Request-SddcManagerAccountLockout` cmdlet retrieves the account lockout policy for an SDDC Manager.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter
- Retrieves the account lockout policy for an SDDC Manager

## Examples

### Example 1

```powershell
Request-SddcManagerAccountLockout -server <fqdn> -user <admin_username> -pass <admin_password> -rootPass <root_password>
```

This example retrieves the account lockout policy for an SDDC Manager.

### Example 2

```powershell
Request-SddcManagerAccountLockout -server <fqdn> -user <admin_username> -pass <admin_password> -rootPass <root_password> -drift -reportPath <report_path> -policyFile <policy_file>.json
```

This example retrieves the account lockout policy for an SDDC Manager and and compares the configuration against the policy configuration file.

### Example 3

```powershell
Request-SddcManagerAccountLockout -server <fqdn> -user <admin_username> -pass <admin_password> -rootPass <root_password> -drift
```

This example retrieves the account lockout policy for an SDDC Manager and compares the configuration against the product defaults.

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

### -rootPass

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

The path to the password policy file to compare against.

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
