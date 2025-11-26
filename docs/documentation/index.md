<!-- markdownlint-disable first-line-h1 no-inline-html -->
# Reference

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
