# Update-SddcManagerAccountLockout

## Synopsis

Updates the account lockout policy for an SDDC Manager.

## Syntax

```powershell
Update-SddcManagerAccountLockout [-server] <String> [-user] <String> [-pass] <String> [-rootPass] <String> [-failures] <Int32> [[-unlockInterval] <Int32>] [[-rootUnlockInterval] <Int32>] [<CommonParameters>]
```

## Description

The `Update-SddcManagerAccountLockout` cmdlet configures the account lockout policy for an SDDC Manager.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-password` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Configures the account lockout policy

## Examples

### Example 1

```powershell
Update-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -failures 3 -unlockInterval 86400 -rootUnlockInterval 300
```

This example configures the account lockout policy for an SDDC Manager.

## Parameters

### -server

The fully qualified domain name of the SDDC Manager instance.

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

The username to authenticate to the SDDC Manager instance.

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

The password to authenticate to the SDDC Manager instance.

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

### -rootPass

The password for the SDDC Manager appliance root account.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -rootUnlockInterval

The number of seconds before a locked root account is unlocked.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
