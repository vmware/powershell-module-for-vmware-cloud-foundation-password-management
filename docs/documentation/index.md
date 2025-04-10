<!-- markdownlint-disable first-line-h1 no-inline-html -->
# Reference

`VMware.CloudFoundation.PasswordManagement` is a PowerShell module that supports the ability to report and configure the password policy settings across your [VMware Cloud Foundatiоn][docs-vmware-cloud-foundation] instance.

With these cmdlets, you can perform the following actions on a VMware Cloud Foundation instance or a specific workload domain.

The module provides coverage for the following:

=== ":material-shield-check: &nbsp; Password Policies"

    1. Generate a password policy report for password expiration, password complexity, and account lockout.
    2. Generate a password policy report with configuration drift using a password policy configuration file.
    3. Update the password polices using a password policy configuration file.

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


[docs-vmware-cloud-foundation]: https://docs.vmware.com/en/VMware-Cloud-Foundation/index.html
