<!-- markdownlint-disable first-line-h1 no-inline-html -->

<img src=".github/icon-400px.svg" alt="A PowerShell Module for Cloud Foundation Password Management" width="150"></br></br>

# PowerShell Module for VMware Cloud Foundation Password Management

[<img src="https://img.shields.io/badge/Documentation-Read-blue?style=for-the-badge&logo=readthedocs&logoColor=white" alt="Documentation">][docs-module]&nbsp;&nbsp;
[<img src="https://img.shields.io/badge/Changelog-Read-blue?style=for-the-badge&logo=github&logoColor=white" alt="CHANGELOG" >][changelog]

[<img src="https://img.shields.io/powershellgallery/v/VMware.CloudFoundation.PasswordManagement?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell Gallery">][psgallery-module]&nbsp;&nbsp;
<img src="https://img.shields.io/powershellgallery/dt/VMware.CloudFoundation.PasswordManagement?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell Gallery Downloads">

## Overview

`VMware.CloudFoundation.PasswordManagement` is a PowerShell module designed to help you report on
and manage password policy settings within your VMware Cloud Foundation environment.

Using this module, you can perform various tasks on a VMware Cloud Foundation instance or a specific
workload domain.

- Generate detailed password policy reports, including information on password expiration,
  complexity, and account lockout settings.
- Identify configuration drift by generating password policy reports using a predefined configuration file.
- Update password policies seamlessly using a password policy configuration file.
- Create comprehensive password rotation reports for all accounts managed by SDDC Manager.

For details on specific VMware Cloud Foundation versions supported by this module, please refer to the [documentation][docs-module].

## Documentation

For detailed instructions on using this module, refer to the [documentation][docs-module].

## Contributing

We encourage community contributions! To get started, please refer to the [contribution guidelines][contributing].

## Support

This module is community-driven and maintained by the project contributors. It is not officially
supported by Broadcom Support but thrives on collaboration and input from its users.

Use the GitHub [issues][gh-issues] to report bugs or suggest features and enhancements. Issues are
monitored by the maintainers and are prioritized based on criticality and community [reactions][gh-reactions].

Before filing an issue, please search the issues and use the reactions feature to add votes to
matching issues. Please include as much information as you can. Details like these are incredibly
useful in helping the us evaluate and prioritize any changes:

- A reproducible test case or series of steps.
- Any modifications you've made relevant to the bug.
- Anything unusual about your environment or deployment.

You can also start a discussion on the GitHub [discussions][gh-discussions] area to ask questions or
share ideas.

## License

© Broadcom. All Rights Reserved.

The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.

This project is licensed under the [BSD 2-Clause License](LICENSE).

[changelog]: CHANGELOG.md
[contributing]: CONTRIBUTING.md
[docs-module]: https://vmware.github.io/powershell-module-for-vmware-cloud-foundation-password-management
[gh-discussions]: https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/discussions
[gh-issues]: https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management/issues
[gh-reactions]: https://github.blog/2016-03-10-add-reactions-to-pull-requests-issues-and-comments/
[psgallery-module]: https://www.powershellgallery.com/packages/VMware.CloudFoundation.PasswordManagement
