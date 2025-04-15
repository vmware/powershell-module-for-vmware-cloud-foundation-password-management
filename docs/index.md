<!-- markdownlint-disable first-line-h1 no-inline-html -->

<img src="assets/images/icon-color.svg" alt="PowerShell Module for VMware Cloud Foundation Password Management" width="150">

# PowerShell Module for VMware Cloud Foundation Password Management

[:material-powershell: &nbsp; PowerShell Gallery][psgallery-module-password-management]{ .md-button .md-button--primary }

`VMware.CloudFoundation.PasswordManagement` is a PowerShell module designed to help you report on
and manage password policy settings within your VMware Cloud Foundation environment.

Using this module, you can perform various tasks on a VMware Cloud Foundation instance or a specific
workload domain.

The module provides coverage for the following:

=== ":material-shield-check: &nbsp; Password Policies"

    1. Generate detailed password policy reports, including information on password expiration, complexity, and account lockout settings.
    2. Identify configuration drift by generating password policy reports using a predefined configuration file.
    3. Update password policies seamlessly using a password policy configuration file.
    4. Create comprehensive password rotation reports for all accounts managed by SDDC Manager.

    Components:

    * VMware SDDC Manager
    * VMware vCenter Single Sign-On
    * VMware vCenter
    * VMware ESX
    * VMware NSX Local Manager
    * VMware NSX Edge
    * VMware Aria Suite Lifecycle
    * VMware Aria Operations
    * VMware Aria Operations for Logs
    * VMware Aria Operations for Networks
    * VMware Aria Automation
    * VMware Workspace ONE Access

=== ":fontawesome-solid-rotate: &nbsp; Password Rotation"

    Generate a password rotation report for accounts managed by SDDC Manager.

    Components:

    * VMware SDDC Manager
    * VMware vCenter Single Sign-On
    * VMware vCenter
    * VMware NSX Local Manager
    * VMware NSX Edge
    * VMware Aria Suite Lifecycle
    * VMware Aria Operations
    * VMware Aria Operations for Logs
    * VMware Aria Automation
    * VMware Workspace ONE Access

    ???+ note "Note"
        - VMware ESX password rotation is not managed by SDDC Manager.
        - VMware Aria Suite password rotation is only supported if deployed in VMware Cloud Foundation mode and present in the SDDC Manager inventory.

## Requirements

### Platforms

The following table lists the supported platforms for this module.

Platform                                                     | Support                             | Reference
-------------------------------------------------------------|-------------------------------------|--------------------------------------------------------------------------------------
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 5.2 | :fontawesome-solid-check:{ .green } | :fontawesome-solid-book: &nbsp; [Documentation][docs-vmware-cloud-foundation-ppm-5-2]
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 5.1 | :fontawesome-solid-check:{ .green } | :fontawesome-solid-book: &nbsp; [Documentation][docs-vmware-cloud-foundation-ppm-5-1]
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 5.0 | :fontawesome-solid-check:{ .green } | :fontawesome-solid-book: &nbsp; [Documentation][docs-vmware-cloud-foundation-ppm-5-0]
:fontawesome-solid-cloud: &nbsp; VMware Cloud Foundation 4.5 | :fontawesome-solid-check:{ .green } | :fontawesome-solid-book: &nbsp; [Documentation][docs-vmware-cloud-foundation-ppm-4-5]

### PowerShell

The following table lists the supported editions and versions of PowerShell for this module.

Edition                                                              | Version
---------------------------------------------------------------------|----------
:material-powershell: &nbsp; [PowerShell Core][microsoft-powershell] | >= 7.2.0

### Module Dependencies

The following table lists the required PowerShell module dependencies for this module.

PowerShell Module                                    | Version   | Publisher | Reference
-----------------------------------------------------|-----------|-----------|---------------------------------------------------------------------------
[VMware.PowerCLI][psgallery-module-powercli]         | >= 13.3.0 | Broadcom  | :fontawesome-solid-book: &nbsp; [Documentation][developer-module-powercli]
[VMware.vSphere.SsoAdmin][psgallery-module-ssoadmin] | >= 1.3.9  | Broadcom  | :fontawesome-brands-github: &nbsp; [GitHub][github-module-ssoadmin]
[PowerVCF][psgallery-module-powervcf]                | >= 2.4.1  | Broadcom  | :fontawesome-solid-book: &nbsp; [Documentation][docs-module-powervcf]
[PowerValidatedSolutions][psgallery-module-pvs]      | >= 2.12.1 | Broadcom  | :fontawesome-solid-book: &nbsp; [Documentation][docs-module-pvs]

[docs-vmware-cloud-foundation-ppm-5-2]: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-2/vmware-cloud-foundation-operations-5-2.html
[docs-vmware-cloud-foundation-ppm-5-1]: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-1/vmware-cloud-foundation-operations-5-1.html
[docs-vmware-cloud-foundation-ppm-5-0]: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/5-0/vmware-cloud-foundation-operations-5-0.html
[docs-vmware-cloud-foundation-ppm-4-5]: https://techdocs.broadcom.com/us/en/vmware-cis/vcf/vcf-5-2-and-earlier/4-5/vmware-cloud-foundation-operations-4-5.html
[microsoft-powershell]: https://docs.microsoft.com/en-us/powershell
[psgallery-module-powercli]: https://www.powershellgallery.com/packages/VMware.PowerCLI
[psgallery-module-powervcf]: https://www.powershellgallery.com/packages/PowerVCF
[psgallery-module-password-management]: https://www.powershellgallery.com/packages/VMware.CloudFoundation.PasswordManagement
[psgallery-module-pvs]: https://www.powershellgallery.com/packages/PowerValidatedSolutions
[psgallery-module-ssoadmin]: https://www.powershellgallery.com/packages/VMware.vSphere.SsoAdmin
[developer-module-powercli]: https://developer.broadcom.com/powercli
[docs-module-powervcf]: https://vmware.github.io/powershell-module-for-vmware-cloud-foundation
[docs-module-pvs]: https://vmware.github.io/power-validated-solutions-for-cloud-foundation
[github-module-ssoadmin]: https://github.com/vmware/PowerCLI-Example-Scripts/tree/master/Modules/VMware.vSphere.SsoAdmin
