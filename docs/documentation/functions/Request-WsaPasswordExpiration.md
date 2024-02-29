# Request-WsaPasswordExpiration

## Synopsis

Retrieves Workspace ONE Access password expiration.

## Syntax

```powershell
Request-WsaPasswordExpiration -server <String> -user <String> -pass <String> [-drift] [-reportPath <String>] [-policyFile <String>] [<CommonParameters>]
```

## Description

The `Request-WsaPasswordExpiration` cmdlet retrieves the Workspace ONE Access password expiration policy.

- Validates that network connectivity and authentication is possible to Workspace ONE Access
- Retrieves the password expiration policy

## Examples

### Example 1

```powershell
Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1!
```

This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io.

### Example 2

```powershell
Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io and checks the configuration drift using the provided configuration JSON.

### Example 3

```powershell
Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift
```

This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io and compares the configuration against the product defaults.

## Parameters

### -server

The fully qualified domain name of the Workspace ONE Access instance.

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

The username to authenticate to the Workspace ONE Access instance.

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

The password to authenticate to the Workspace ONE Access instance.

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

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
