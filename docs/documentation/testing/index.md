# Testing the PowerShell Module with Pester

## Overview

Pester is a testing and mocking framework for PowerShell, most commonly used for writing unit and integration tests.

This project uses Pester integration test cases for testing the functionality of the modules functions both for the developer and in a CI/CD pipeline environment.

These Pester test cases allow for the verification of functions such as `Request-*` and `Update-*`, ensuring they function correctly during development.

This proactive approach helps catch regression issues before a release.

## Getting Started

???+ tip "Logs"

    A `./tests/logs` folder is provided, containing a log file that records detailed information about the testing process.

1. Clone the repository:

    ```bash
    git clone https://github.com/vmware/powershell-module-for-vmware-cloud-foundation-password-management.git
    ```

2. Navigate to the downloaded repository:

    ```bash
    cd powershell-module-for-vmware-cloud-foundation-password-management
    ```

3. Verify all the required module dependencies are imported and then import the module:

    ```powershell
    --8<-- "./docs/snippets/import-module-tests.ps1"
    ```

4. Navigate to the `tests` directory:

    ```bash
    cd tests
    ```

5. Under the `tests` folder, copy the `inputData.json.example` file to `inputData.json` and include information about your testbed.

    This file serves as an input file to run tests against a VMware Cloud Foundation **development** environment.

6. Run all Pester test cases in a file with the following command:

    ```powershell
    Invoke-Pester ".\PPM.Tests.ps1"
    ```

7. There are positive and negative test cases for each policy. If you want to run only one policy, use the tag associated with the policy:

    ```powershell
    Invoke-Pester -Path ".\PPM.Tests.ps1"  -Tag "NSXEdgeAccountLockout"
    ```

8. To run only positive test cases for a policy, provide the name for the `-Tag` and use the `-ExcludeTag` with the tag `"Negative"`:

    ```powershell
    Invoke-Pester -Path ".\PPM.Tests.ps1" -Tag "NSXEdgeAccountLockout" -ExcludeTag "Negative"
    ```

9. To see detailed output of the run, which includes information on which test cases are started, their status, and so on, use the following option:

    ```powershell
    Invoke-Pester -Path ".\PPM.Tests.ps1" -Output Detailed
    ```
