# Release History

## v1.1.0

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

Enhancements:

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

Chores:

- Added `.PARAMETER` entries for user-facing functions. [GH-37](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/pull/37)

> **Note**
>
> Whilst this release will support VMware Cloud Foundation 5.0, it does not support password complexity for NSX 4.x. Please use the NSX 4.x product documentation to configure password complexity. Reference: [GH-38](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/issues/38)

## [v1.0.0](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/releases/tag/v1.0.0)

> Release Date: 2023-04-25

- Initial Module Release
