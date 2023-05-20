# Publish-WsaLocalPasswordPolicy

## SYNOPSIS

Publish password policies for Workspace ONE Access Local Users.

## SYNTAX

### All-WorkloadDomains

```powershell
Publish-WsaLocalPasswordPolicy -server <String> -user <String> -pass <String> -wsaFqdn <String>
 -wsaRootPass <String> -policy <String> [-drift] [-reportPath <String>] [-policyFile <String>] [-json]
 [-allDomains] [<CommonParameters>]
```

### Specific-WorkloadDomain

```powershell
Publish-WsaLocalPasswordPolicy -server <String> -user <String> -pass <String> -wsaFqdn <String>
 -wsaRootPass <String> -policy <String> [-drift] [-reportPath <String>] [-policyFile <String>] [-json]
 -workloadDomain <String> [<CommonParameters>]
```

## DESCRIPTION

The Publish-WsaDirectoryPasswordPolicy cmdlet retrieves the requested password policy for all ESXi hosts and converts
the output to HTML.
The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:

- Validates that network connectivity and authentication is possible to SDDC Manager
- Validates that network connectivity and authentication is possible to vCenter Server
- Retrieves the requested password policy for Workspace ONE Access Local Users and converts to HTML

## EXAMPLES

### EXAMPLE 1

```powershell
Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
```

This example will return password expiration policy for Workspace ONE Access Directory Users.

```powershell
Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
```

This example will return password complexity policy for Workspace ONE Access Directory Users.

```powershell
Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
```

This example will return account lockout policy for Workspace ONE Access Directory Users.

```powershell
Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
```

This example will return password expiration policy for Workspace ONE Access Directory Users and compare the configuration against the passwordPolicyConfig.json.

```powershell
Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains -drift
```

This example will return password expiration policy for Workspace ONE Access Directory Users and compares the configuration against the product defaults.

## PARAMETERS

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

### -wsaFqdn

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

### -wsaRootPass

The password for the Workspace ONE Access appliance root account.

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

### -policy

The policy to publish.
One of: PasswordExpiration, PasswordComplexity, AccountLockout.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
