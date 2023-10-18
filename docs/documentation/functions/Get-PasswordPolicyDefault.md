# Get-PasswordPolicyDefault

## Synopsis

Get password policy default settings.

## Syntax

### All (Default)

```powershell
Get-PasswordPolicyDefault -version <String> [<CommonParameters>]
```

### json

```powershell
Get-PasswordPolicyDefault [-generateJson] -version <String> [-jsonFile <String>] [-force <Switch>] [<CommonParameters>]
```

## Description

The `Get-PasswordPolicyDefault` cmdlet returns the default password policy settings, it can also be used to generate the base JSON file used with Password Policy Manager.

Default settings for VMware products include:

- VMware SDDC Manager
- VMware ESXi
- VMware vCenter Single Sign-On
- VMware vCenter Server
- VMware NSX Manager
- VMware NSX Edge
- VMware Workspace ONE Access

## Examples

### Example 1

```powershell
Get-PasswordPolicyDefault -version '5.0.0.0'
```

This example returns the default password policy settings for the VMware Cloud Foundation version 5.0.0.0.

### Example 2

```powershell
Get-PasswordPolicyDefault -generateJson -jsonFile passwordPolicyConfig.json -version '5.0.0.0'
```

This example creates a JSON file named `passwordPolicyConfig.json` with the default password policy settings for the given version of VMware Cloud Foundation.

### Example 3

```powershell
Get-PasswordPolicyDefault -generateJson -jsonFile passwordPolicyConfig.json -version '5.0.0.0' -force
```

This example creates a JSON file named `passwordPolicyConfig.json` with the default password policy settings for the given version of VMware Cloud Foundation.
If `passwordPolicyConfig.json` is already present, it is overwritten due to 'force' parameter.

## Parameters

### -generateJson

Switch to generate a JSON file.

```yaml
Type: SwitchParameter
Parameter Sets: json
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -version

The VMware Cloud Foundation version to get policy defaults for the JSON file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: 5.0.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -jsonFile

The name of the JSON file to generate.

```yaml
Type: String
Parameter Sets: json
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -force

The switch used to overwrite the JSON file if already exists.

```yaml
Type: Switch
Parameter Sets: json
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### Common Parameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
