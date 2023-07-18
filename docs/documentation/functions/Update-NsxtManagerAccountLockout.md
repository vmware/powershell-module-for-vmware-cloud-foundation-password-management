# Update-NsxtManagerAccountLockout

## Synopsis

Updates the account lockout policy for NSX Local Manager.

## Syntax

```powershell
Update-NsxtManagerAccountLockout [-server] <String> [-user] <String> [-pass] <String> [-domain] <String> [[-cliFailures] <Int32>] [[-cliUnlockInterval] <Int32>] [[-apiFailures] <Int32>] [[-apiFailureInterval] <Int32>] [[-apiUnlockInterval] <Int32>] [[-detail] <String>] [<CommonParameters>]
```

## Description

The `Update-NsxtManagerAccountLockout` cmdlet configures the account lockout policy for NSX Local Manager nodes within a workload domain.
The cmdlet connects to SDDC Manager using the `-server`, `-user`, and `-pass` values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to NSX Local Manager
- Configure the account lockout policy

## Examples

### Example 1

```powershell
Update-NsxtManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cliFailures 5 -cliUnlockInterval 900 -apiFailures 5 -apiFailureInterval 120 -apiUnlockInterval 900
```

This example configures the account lockout policy in NSX Local Manager nodes in the sfo-m01 workload domain.

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

### -domain

The name of the workload domain to update the policy for.

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

### -cliFailures

The number of failed login attempts before the account is locked out for the CLI.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -cliUnlockInterval

The number of seconds before the account is unlocked for the CLI.

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

### -apiFailures

The number of failed login attempts before the account is locked out for the API.

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

### -apiFailureInterval

The number of seconds before the account is unlocked for the API.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -apiUnlockInterval

The number of seconds before the account is unlocked for the API.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -detail

Return the details of the policy.
One of true or false.
Default is true.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
