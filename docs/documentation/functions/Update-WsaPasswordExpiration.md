# Update-WsaPasswordExpiration

## SYNOPSIS

Update the Workspace ONE Access password expiration policy.

## SYNTAX

```powershell
Update-WsaPasswordExpiration [-server] <String> [-user] <String> [-pass] <String> [-maxDays] <Int32>
 [-warnDays] <Int32> [-reminderDays] <Int32> [-tempPasswordHours] <Int32> [<CommonParameters>]
```

## DESCRIPTION

The Update-WsaPasswordExpiration cmdlet configures the password expiration policy for a Workspace ONE Access
instance.

- Validates that network connectivity and authentication is possible to Workspace ONE Access
- Configures the Workspace ONE Access password expiration policy

## EXAMPLES

### EXAMPLE 1

```powershell
Update-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -maxDays 999 -warnDays 14 -reminderDays 7 -tempPasswordHours 24
```

This example configures the password expiration policy for Workspace ONE Access.

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

### -maxDays

The maximum number of days that a password is valid.

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

### -warnDays

The number of days before a password expires that a warning is issued.

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

### -reminderDays

The number of days before a password expires that a reminder is issued.

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

### -tempPasswordHours

The number of hours that a temporary password is valid.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
