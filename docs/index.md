<!-- markdownlint-disable first-line-h1 no-inline-html -->

<img src="assets/images/icon-color.svg" alt="PowerShell Module for VMware Cloud Foundation Password Management" width="150">

# PowerShell Module for VMware Cloud Foundation Password Management

`VMware.CloudFoundation.PasswordManagement` is a PowerShell module that has been written to support the ability to report and configure the password policy settings across your [VMware Cloud Foundatiоn][docs-vmware-cloud-foundation] instance.

With these cmdlets, you can:

- Generate a password policy report for your SDDC Manager instance.
- Generate a password policy report with configuration drift for your SDDC Manager instance by using a password policy configuration file.
- Configure password polices for your SDDC Manager instance by using a password policy configuration file.

The module provides coverage for the following components:

- ESXi
- vCenter Single Sign-On
- vCenter Server
- NSX Local Manager
- NSX Edge
- SDDC Manager
- Standalone Workspace ONE Access

[:material-powershell: &nbsp; PowerShell Gallery][psgallery-module-password-management]{ .md-button .md-button--primary }

## Requirements

### Platforms

The following table lists the supported platforms for this module.

Platform                                                         | Support
-----------------------------------------------------------------|------------------------------------
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 5.0[^1] | :fontawesome-solid-check:{ .green }
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 4.5     | :fontawesome-solid-check:{ .green }
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 4.4     | :fontawesome-solid-check:{ .green }
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 4.3     | :fontawesome-solid-x:{ .red }

[^1]:
    Password complexity for NSX 4.x in VMware Cloud Foundation 5.0 is not currently supported in this module. Please use the NSX 4.x product documentation to configure password complexity. Reference: [GH-38](https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/issues/38)

### Operating Systems

The following table lists the supported operating systems for this module.

Operating System                                                       | Version
-----------------------------------------------------------------------|-----------
:fontawesome-brands-windows: &nbsp; Microsoft Windows Server           | 2019, 2022
:fontawesome-brands-windows: &nbsp; Microsoft Windows                  | 10, 11
:fontawesome-brands-linux: &nbsp; [VMware Photon OS][github-os-photon] | 3.0, 4.0

### PowerShell

The following table lists the supported editions and versions of PowerShell for this module.

Edition                                                                           | Version
----------------------------------------------------------------------------------|----------
:material-powershell: &nbsp; [Microsoft Windows PowerShell][microsoft-powershell] | 5.1
:material-powershell: &nbsp; [PowerShell Core][microsoft-powershell]              | >= 7.2.0

### Module Dependencies

The following table lists the required PowerShell module dependencies for this module.

PowerShell Module                                    | Version   | Publisher    | Reference
-----------------------------------------------------|-----------|--------------|---------------------------------------------------------------------------
[VMware.PowerCLI][psgallery-module-powercli]         | >= 13.0.0 | VMware, Inc. | :fontawesome-solid-book: &nbsp; [Documentation][developer-module-powercli]
[VMware.vSphere.SsoAdmin][psgallery-module-ssoadmin] | >= 1.3.9  | VMware, Inc. | :fontawesome-brands-github: &nbsp; [GitHub][github-module-ssoadmin]
[PowerVCF][psgallery-module-powervcf]                | >= 2.3.0  | VMware, Inc. | :fontawesome-brands-github: &nbsp; [GitHub][github-module-powervcf]
[PowerValidatedSolutions][psgallery-module-pvs]      | >= 2.2.0  | VMware, Inc. | :fontawesome-brands-github: &nbsp; [GitHub][github-module-pvs]

[docs-vmware-cloud-foundation]: https://docs.vmware.com/en/VMware-Cloud-Foundation/index.html
[microsoft-powershell]: https://docs.microsoft.com/en-us/powershell
[psgallery-module-powercli]: https://www.powershellgallery.com/packages/VMware.PowerCLI
[psgallery-module-powervcf]: https://www.powershellgallery.com/packages/PowerVCF
[psgallery-module-password-management]: https://www.powershellgallery.com/packages/VMware.CloudFoundation.PasswordManagement
[psgallery-module-pvs]: https://www.powershellgallery.com/packages/PowerValidatedSolutions
[psgallery-module-ssoadmin]: https://www.powershellgallery.com/packages/VMware.vSphere.SsoAdmin
[developer-module-powercli]: https://developer.vmware.com/tool/vmware-powercli
[github-module-powervcf]: https://github.com/vmware/powershell-module-for-vmware-cloud-foundation
[github-module-pvs]: https://github.com/vmware-samples/power-validated-solutions-for-cloud-foundation
[github-module-ssoadmin]: https://github.com/vmware/PowerCLI-Example-Scripts/tree/master/Modules/VMware.vSphere.SsoAdmin
