# Release History

## v1.5.0 (Unreleased)

Enhancement:

- Added `Invoke-PasswordRotationManager`, `Save-ClarityReportNavigationForRotation` and `Set-CreateReportDirectoryRotation` cmdlets and updated `Publish-PasswordRotationPolicy` cmdlet to generate report for password rotation settings for accounts managed by SDDC Manager in HTML or JSON format. Results can be filtered by workload domain. [GH-115](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/115) 
- Updated `Invoke-PasswordPolicyManager`, `Get-PasswordPolicyDefault`, `Get-PasswordPolicyConfig`, `Request-SddcManagerPasswordComplexity`, `Request-SddcManagerAccountLockout`, `Request-SsoAccountLockout`, `Request-VcenterPasswordExpiration`, `Request-VcenterPasswordComplexity`, `Request-VcenterAccountLockout`, `Request-VcenterRootPasswordExpiration`, `Request-NsxtManagerPasswordExpiration`, `Request-NsxtManagerPasswordComplexity`, `Request-NsxtManagerAccountLockout`, `Request-NsxtEdgePasswordExpiration`, `Request-NsxtEdgePasswordComplexity`, `Request-NsxtEdgeAccountLockout`, `Request-EsxiPasswordExpiration`, `Request-EsxiPasswordComplexity`, `Request-EsxiAccountLockout` and `Request-LocalUserPasswordExpiration` cmdlet to simplify the logic for reading version information. [GH-115](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/115)


## [v1.4.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.4.0)

> Release Date: 2023-08-29

Enhancement:

- Added `Request-SddcManagerPasswordExpiration` cmdlet to retrieve the password expiration policy for the default local users on an SDDC Manager appliance. [GH-97](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/97)
- Added `Update-SddcManagerPasswordExpiration` cmdlet to update the password expiration policy for the default local users on an SDDC Manager appliance. [GH-97](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/97)
- Added `Request-PasswordRotationPolicy` cmdlet to retrieve the password rotation settings for accounts managed by SDDC Manager. Results can be filtered by resource type or workload domain. [GH-100](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/100)
- Added `Publish-PasswordRotationPolicy` cmdlet to publish the password rotation settings for accounts managed by SDDC Manager in HTML or JSON format. Results can be filtered by resource type or workload domain. [GH-100](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/100)

Bugfix:

- Updated `Get-PasswordPolicyDefault` to include support for VMware Cloud Foundation 4.4.1. [GH-95](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/95)
- Updated `Get-PasswordPolicyConfig` to include support for VMware Cloud Foundation 4.4.1. [GH-95](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/95)
- Updated `Invoke-PasswordPolicyManager`, `Start-PasswordPolicyConfig`, and `Get-PasswordPolicyConfig` to better handle use of `Test-Path` and `Get-Content` cmdlets when verifing and consuming the password policy configuration JSON file. [GH-98](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/98)
- Updated `Test-PasswordPolicyConfig` to better handle validation of ESXi host password complexity policy in the password policy configuration JSON file. [GH-99](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/99)

Chore:

- Updated `VMware.PowerCLI` from v13.0.0 to v13.1.0. [GH-102](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/102)
- Updated `PowerValidatedSolutions` from v2.5.0 to v2.6.0. [GH-102](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/102)

## [v1.3.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.3.0)

> Release Date: 2023-08-15

Enhancement:

- Added the `RequiredModules` key to the module manifest to specify the minimum dependencies required to install and run the PowerShell module. [GH-63](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/63)
- Updated `Test-VcfPasswordManagementPrereq` to verify that the minimum dependencies are met to run the PowerShell module based on the module's manifest. [GH-63](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/63)

Bugfix:

- Updated `Request-SsoPasswordComplexity` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Request-SsoAccountLockout` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Request-EsxiPasswordExpiration` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Request-EsxiPasswordComplexity` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Request-EsxiAccountLockout` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Update-EsxiPasswordExpiration` to use `Test-VCFConnection` instead of `Test-Connection` to check the connection. [GH-62](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/62)
- Updated `Get-PasswordPolicyDefault` to include support for VMware Cloud Foundation 4.5.2. [GH-91](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/91)
- Updated `Get-PasswordPolicyConfig` to include support for VMware Cloud Foundation 4.5.2. [GH-91](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/91)
- Updated `Get-PasswordPolicyDefault` to include support for VMware Cloud Foundation 4.5.0. [GH-71](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/71)
- Updated `Get-PasswordPolicyConfig` to include support for  VMware Cloud Foundation 4.5.0. [GH-71](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/71)
- Updated `Invoke-PasswordPolicyManager` to address version support updates and JSON file depth handling. [GH-71](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/71)
- Updated `Request-NsxtEdgePasswordExpiration` to pass the `-transportNodeId` parameter to `Get-NsxtApplianceUser` to retrieve the NSX Edge node ID. [GH-76](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/76)
- Updated `Update-NsxtEdgePasswordExpiration` to pass the `-transportNodeId` parameter to `Get-NsxtApplianceUser` and `Set-NsxtApplianceUserExpirationPolicy` to retrieve the NSX Edge node ID. [GH-76](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/76)

Chore:

- Added the `RequiredModules` key to the module manifest to specify the minimum dependencies required to install and run the PowerShell module. [GH-63](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/63)
- Updated `Test-VcfPasswordManagementPrereq` to verify that the minimum dependencies are met to run the PowerShell module based on the module's manifest. [GH-63](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/63)
- Updated `PowerValidatedSolution` from v2.4.0 to v2.5.0. [GH-63](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/63)

## [v1.2.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.2.0)

> Release Date: 2023-06-27

Enhancement:

- Enhanced `Update-NsxtManagerPasswordComplexity` to handle VMware Cloud Foundation 5.0 and NSX 4.x changes. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Get-PasswordPolicyDefault` to handle VMware Cloud Foundation versions as defaults are changing accordingly. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Get-PasswordPolicyConfig` to handled version parameter as it internally calls `Get-PasswordPolicyDefault`. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Test-PasswordPolicyConfig` to check if right version of the json file is used for comparison. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SddcManagerPasswordComplexity` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SddcManagerAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoPasswordExpiration` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoPasswordComplexity` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-VcenterPasswordExpiration` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-VcenterPasswordComplexity` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-VcenterAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-VcenterRootPasswordExpiration` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-NsxtManagerPasswordComplexity` to handle password complexity policies to be read from API than static file for VCF5.0. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-NsxtManagerAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-NsxtManagerPasswordComplexity` mainly, where all new parameters added with reference to NSX 4.X, are handled and also API is used to get all configurations than static common-password file. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-NsxtEdgePasswordExpiration` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-NsxtEdgePasswordComplexity` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-NsxtEdgeAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-EsxiPasswordExpiration` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-EsxiPasswordComplexity` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-EsxiAccountLockout` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-LocalUserPasswordExpirationt` to handle VMware Cloud Foundation version specific JSON file during drift option. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-LocalUserPasswordExpiration` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-WsaLocalUserAccountLockout` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-WsaLocalUserPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-WsaLocalUserPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Publish-EsxiPasswordPolicy` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-EsxiAccountLockout` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-EsxiPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-EsxiPasswordExpiration` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-NsxtEdgePasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-NsxtManagerPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-VcenterAccountLockout` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-SsoPasswordExpiration` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-SsoPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-SsoAccountLockout` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoAccountLockout` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Request-SsoPasswordExpiration` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Update-SddcManagerPasswordComplexity` to handle disconnects gracefully. [GH-42](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/42)
- Enhanced `Get-PasswordPolicyConfig` as there is no significance of default value while parameter is mandatory. [GH-45](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/45)
- Enhanced `Get-PasswordPolicyDefault` as there is no significance of default value while parameter is mandatory. [GH-45](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/45)
- Enhanced `Update-NsxtManagerPasswordComplexity` cmdlet to handle `hash_algorithm` parameter for NSX 4.x. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Request-NsxtManagerPasswordComplexity` cmdlet to handle `hash_algorithm` parameter for NSX 4.x. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Request-NsxtManagerPasswordComplexity` cmdlet to handle connection to management domain vCenter Server instance as NSX Manager virtual machines are placed on the management network. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Request-LocalUserPasswordExpiration` cmdlet to handle connection to management domain vCenter Server instance as NSX Manager virtual machines are placed on the management network. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Update-LocalUserPasswordComplexity` cmdlet to handle connection to management domain vCenter Server instance as NSX Manager virtual machines are placed on the management network. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Get-PasswordPolicyConfig` cmdlet to handle `hash_algorithm` parameter for NSX 4.x. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Enhanced `Get-PasswordPolicyDefault` cmdlet to handle `jsonFile` parameter cleanly. [GH-51](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/51)
- Enhanced `Publish-SSO*` cmdlet to handle isolated workload domain in VMware Cloud Foundation 5.0 environment. [GH-51](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/51)
- Enhanced `Get-PasswordPolicyDefault` cmdlet to handle existing JSON file overriding using `force` parameter. [GH-52](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/52)
- Enhanced `Update-SsoPasswordComplexity` cmdlet to add validation on parameter values. [GH-56](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/56)

Bugfix:

- Fixed default values for `unlockInterval` and `rootUnlockInterval` for `VcenterLocalAccountLockout` setting in `Get-PasswordPolicyDefault` cmdlet. [GH-47](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/45)
- Fixed `Request-LocalUserPasswordExpiration` cmdlet to display the value for `minDays` while `drift` option is used. [GH-49](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/49)
- Fixed small typo in `Request-SsoPasswordComplexity` and `Request-WsaPasswordComplexity` cmdlets. [GH-56](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/56)

## [v1.1.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.1.0)

> Release Date: 2023-05-30

Bugfix:

- Fixed the placement for the use of `Disconnect-SSOserver`. [GH-26](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/26)
- Fixed drift option error for `Request-VcenterAccountLockout`. [GH-32](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/32)
- Exported `Get-PasswordPolicyConfig`. [GH-32](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/32)
- Fixed drift option error for `Publish-VcenterLocalAccountLockout`. [GH-34](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/34)
- Fixed drift option error for `Publish-VcenterLocalPasswordExpiration`. [GH-34](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/34)
- Fixed drift option error for `Publish-VcenterLocalPasswordComplexity`. [GH-34](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/34)
- Handled empty email string values and "0" value for WSADirectory feilds coming from JSON file  `Test-PasswordPolicyConfig`. [GH-36](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/36)
- Corrected Description in `Start-PasswordPolicyConfig`. [GH-36](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/36)

Enhancement:

- Updated `Update-SDDCManagerPasswordComplexity` to handle all structural changes of the common-password file on SDDC Manager. [GH-28](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/28)
- Updated `Update-VcenterAccountLockout` to handle isolated VI Workload Domains. [GH-29](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/29)
- Updated `Request-VcenterPasswordComplexity` to handle isolated VI Workload Domains. [GH-29](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/29)
- Updated `Request-VcenterAccountLockout` to handle isolated VI Workload Domains. [GH-29](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/29)
- Updated `Update-VcenterPasswordComplexity` to handle isolated VI Workload Domains. [GH-29](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/29)
- Updated `Update-SsoPasswordComplexity` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)
- Updated `Update-SsoAccountLockout` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)
- Updated `Update-SsoPasswordExpiration` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)
- Updated `Request-SsoAccountLockout` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)
- Updated `Request-SsoPasswordComplexity` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)
- Updated `Request-SsoPasswordExpiration` to handle isolated VI Workload Domains. [GH-30](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/30)

Chore:

- Added `.PARAMETER` entries for user-facing functions. [GH-37](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/37)

> **Note**
>
> Whilst this release will support VMware Cloud Foundation 5.0, it does not support password complexity for NSX 4.x. Please use the NSX 4.x product documentation to configure password complexity. Reference: [GH-38](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/issues/38)

## [v1.0.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.0.0)

> Release Date: 2023-04-25

- Initial Module Release
