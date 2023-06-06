# Installing the Module

Verify that your system has a [supported edition and version](/powershell-module-for-vmware-cloud-foundation-password-management/#powershell) of PowerShell installed.

Install the PowerShell [module dependencies](/powershell-module-for-vmware-cloud-foundation-password-management/#module-dependencies) from the PowerShell Gallery by running the following commands:

```powershell
--8<-- "./docs/snippets/install-module.ps1"
```

If using PowerShell Core, import the modules before proceeding:

For example:

```powershell
--8<-- "./docs/snippets/import-module.ps1"
```

To verify the module dependencies are installed, run the following commands in the PowerShell console.

**Example**:

```powershell
Test-VcfPasswordManagementPrereq
```

:material-information-slab-circle: &nbsp; [Reference](/powershell-module-for-vmware-cloud-foundation-password-management/documentation/functions/Test-VcfPasswordManagementPrereq/)


Once installed, any cmdlets associated with `VMware.CloudFoundation.PasswordManagement` and the its dependencies will be available for use.

To view the cmdlets for available in the module, run the following command in the PowerShell console.

```powershell
Get-Command -Module VMware.CloudFoundation.PasswordManagement
```

To view the help for any cmdlet, run the `Get-Help` command in the PowerShell console.

For example:

```powershell
Get-Help -Name Invoke-PasswordPolicyManager
```

```powershell
Get-Help -Name Invoke-PasswordPolicyManager -Examples
```

```powershell
Get-Help -Name Invoke-PasswordPolicyManager -Full
```
