<!-- markdownlint-disable first-line-h1 no-inline-html -->
# Reference

The `VMware.CloudFoundation.PasswordManagement` is a PowerShell module supports the ability to report and configure the password policy settings across your [VMware Cloud Foundatiоn][docs-vmware-cloud-foundation] instance.

With these cmdlets, you can perform the following tasks on your VMware Cloud Foundation instance or a specific workload domain:

- Generate a baseline password policy configuration file based on the default password policy settings per component.
- Generate a password policy report detailing the password policy settings per component.
- Generate a password policy report with configuration drift using a password policy configuration file.
- Update password polices to a desired state using a password policy configuration file.

The module provides coverage for the following components:

- ESXi
- vCenter Single Sign-On
- vCenter Server
- NSX Local Manager
- NSX Edge
- SDDC Manager
- Workspace ONE Access (Standalone)

[docs-vmware-cloud-foundation]: https://docs.vmware.com/en/VMware-Cloud-Foundation/index.html
