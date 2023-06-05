# Update-WsaAccountLockout

## SYNOPSIS

Update the Workspace ONE Access account lockout policy.

## SYNTAX

```powershell
Update-WsaAccountLockout [-server] <String> [-user] <String> [-pass] <String> [-failures] <Int32>
 [-failureInterval] <Int32> [-unlockInterval] <Int32> [<CommonParameters>]
```

## DESCRIPTION

The Update-WsaAccountLockout cmdlet configures the account lockout policy for Workspace ONE Access.

- Validates that network connectivity and authentication is possible to Workspace ONE Access
- Configures the Workspace ONE Access account lockout policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-WsaAccountLockout -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -failures 5 -failureInterval 180 -unlockInterval 900
```

This example configures the account lockout policy for Workspace ONE Access.

## PARAMETERS

### -server

The fully qualified domain name of the Workspace ONE Access instance.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
Position: 2
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -failures

The number of failed login attempts before the account is locked.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -failureInterval

The number of seconds before the failed login attempts counter is reset.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -unlockInterval

The number of seconds before a locked account is unlocked.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
