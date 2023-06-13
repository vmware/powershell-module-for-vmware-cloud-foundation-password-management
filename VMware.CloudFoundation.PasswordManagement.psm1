# Copyright 2023 VMware, Inc.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Note:
# This PowerShell module should be considered entirely experimental. It is still in development and not tested beyond lab
# scenarios. It is recommended you don't use it for any production environment without testing extensively!

# Allow communication with self-signed certificates when using Powershell Core. If you require all communications to be
# secure and do not wish to allow communication with self-signed certificates, remove lines 15-41 before importing the
# module.

if ($PSEdition -eq 'Core') {
    $PSDefaultParameterValues.Add("Invoke-RestMethod:SkipCertificateCheck", $true)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
}

if ($PSEdition -eq 'Desktop') {
    # Allow communication with self-signed certificates when using Windows PowerShell
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

    if ("TrustAllCertificatePolicy" -as [type]) {} else {
        Add-Type @"
	using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertificatePolicy : ICertificatePolicy {
        public TrustAllCertificatePolicy() {}
		public bool CheckValidationResult(
            ServicePoint sPoint, X509Certificate certificate,
            WebRequest wRequest, int certificateProblem) {
            return true;
        }
	}
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertificatePolicy
    }
}

##########################################################################
#Region     Begin Password Policy Manager Functions                 ######

Function Invoke-PasswordPolicyManager {
    <#
        .SYNOPSIS
        Generate the Password Policy Manager Report

        .DESCRIPTION
        The Invoke-PasswordPolicyManager generates a Password Policy Manager Report for a VMware Cloud Foundation instance

        .EXAMPLE
        Invoke-PasswordPolicyManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -darkMode -allDomains
        This example runs a password policy report for all Workload Domain within an SDDC Manager instance.

        .EXAMPLE
        Invoke-PasswordPolicyManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -darkMode -allDomains -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -wsaAdminPass VMw@re1!
        This example runs a password policy report for all Workload Domain within an SDDC Manager instance and Workspace ONE Access

        .EXAMPLE
        Invoke-PasswordPolicyManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -darkMode -workloadDomain sfo-w01
        This example runs a password policy report for a specific Workload Domain within an SDDC Manager instance.

        .EXAMPLE
        Invoke-PasswordPolicyManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -darkMode -allDomains -drift -policyFile "PasswordPolicyConfig.json"
        This example runs a password policy report for all Workload Domain within an SDDC Manager instance and compares the configuration against the JSON provided

        .EXAMPLE
        Invoke-PasswordPolicyManager -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -darkMode -allDomains -drift
        This example runs a password policy report for all Workload Domain within an SDDC Manager instance and compares the configuration against the product defaults

        .PARAMETER sddcManagerFqdn
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER sddcManagerUser
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER sddcManagerPass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER sddcRootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER reportPath
        The path to save the report to.

        .PARAMETER allDomains
        Switch to run the report for all workload domains.

        .PARAMETER workloadDomain
        Switch to run the report for a specific workload domain.

        .PARAMETER darkMode
        Switch to use dark mode for the report.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER policyFile
        The path to the JSON file containing the policy configuration.

        .PARAMETER json
        Switch to output the report in JSON format.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER wsaAdminPass
        The password for the Workspace ONE Access admin account.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerUser,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcRootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$darkMode,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$wsaAdminPass
    )

    Try {

        Clear-Host; Write-Host ""

        if (Test-VCFConnection -server $sddcManagerFqdn) {
            if (Test-VCFAuthentication -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass) {
                if (!(Test-Path -Path $reportPath)) {Write-Warning "Unable to locate report path $reportPath, enter a valid path and try again"; Write-Host ""; Break }
                if (!(Test-Path -Path $($reportPath + '\' + $policyFile))) {Write-Warning "Unable to locate policy file $policyFile, enter a valid path and try again"; Write-Host ""; Break }
                Start-SetupLogFile -Path $reportPath -ScriptName $MyInvocation.MyCommand.Name # Setup Log Location and Log File
                $defaultReport = Set-CreateReportDirectory -path $reportPath -sddcManagerFqdn $sddcManagerFqdn # Setup Report Location and Report File
                if ($PsBoundParameters.ContainsKey("allDomains")) {
                    $reportname = $defaultReport.Split('.')[0] + "-" + $sddcManagerFqdn.Split(".")[0] + ".htm"
                    $workflowMessage = "VMware Cloud Foundation instance ($sddcManagerFqdn)"
                    $commandSwitch = "-allDomains"
                } else {
                    $reportname = $defaultReport.Split('.')[0] + "-" + $workloadDomain + ".htm"
                    $workflowMessage = "Workload Domain ($workloadDomain)"
                    $commandSwitch = "-workloadDomain $workloadDomain"
                }
                if ($PsBoundParameters.ContainsKey('drift')) {
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $commandSwitch = $commandSwitch + " -drift -reportPath '$reportPath' -policyFile '$policyFile'"
                    } else {
                        $commandSwitch = $commandSwitch + " -drift"
                    }
                }

                if ($PsBoundParameters.ContainsKey("json")) {
                    $commandSwitch = $commandSwitch + " -json"
                    Write-LogMessage -Type INFO -Message "Starting the Process of Generating Password Policy Manager Config Drift JSON for $workflowMessage." -Colour Yellow
                } else {
                    Write-LogMessage -Type INFO -Message "Starting the Process of Generating Password Policy Manager Report for $workflowMessage." -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Setting up the log file to path $logfile."
                    Write-LogMessage -Type INFO -Message "Setting up report folder and report $reportName."
                }
                # Collect Password Policies
                Write-LogMessage -Type INFO -Message "Collecting SDDC Manager Password Policies for $workflowMessage."
                $sddcManagerPasswordExpiration = Invoke-Expression "Publish-SddcManagerPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -sddcRootPass $sddcRootPass $($commandSwitch)"
                $sddcManagerPasswordComplexity = Invoke-Expression "Publish-SddcManagerPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -sddcRootPass $sddcRootPass $($commandSwitch)"
                $sddcManagerAccountLockout = Invoke-Expression "Publish-SddcManagerAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -sddcRootPass $sddcRootPass $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting vCenter Single Sign-On Password Policies for $workflowMessage."
                $ssoPasswordExpiration = Invoke-Expression "Publish-SsoPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordExpiration $($commandSwitch)"
                $ssoPasswordComplexity = Invoke-Expression "Publish-SsoPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordComplexity $($commandSwitch)"
                $ssoAccountLockout = Invoke-Expression "Publish-SsoPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy AccountLockout $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting vCenter Server Password Expiration Policy for $workflowMessage."
                $vcenterPasswordExpiration = Invoke-Expression "Publish-VcenterPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting vCenter Server (Local User) Password Policies for $workflowMessage."
                $vcenterLocalPasswordExpiration = Invoke-Expression "Publish-VcenterLocalPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $vcenterLocalPasswordComplexity = Invoke-Expression "Publish-VcenterLocalPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $vcenterLocalAccountLockout = Invoke-Expression "Publish-VcenterLocalAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting NSX Manager Password Policies for $workflowMessage."
                $nsxManagerPasswordExpiration = Invoke-Expression "Publish-NsxManagerPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $nsxManagerPasswordComplexity = Invoke-Expression "Publish-NsxManagerPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $nsxManagerAccountLockout = Invoke-Expression "Publish-NsxManagerAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting NSX Edge Password Policies for $workflowMessage."
                $nsxEdgePasswordExpiration = Invoke-Expression "Publish-NsxEdgePasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $nsxEdgePasswordComplexity = Invoke-Expression "Publish-NsxEdgePasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"
                $nsxEdgeAccountLockout = Invoke-Expression "Publish-NsxEdgeAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass $($commandSwitch)"

                Write-LogMessage -Type INFO -Message "Collecting ESXi Password Policies for $workflowMessage."
                $esxiPasswordExpiration = Invoke-Expression "Publish-EsxiPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordExpiration $($commandSwitch)"
                $esxiPasswordComplexity = Invoke-Expression "Publish-EsxiPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordComplexity $($commandSwitch)"
                $esxiAccountLockout = Invoke-Expression "Publish-EsxiPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy AccountLockout $($commandSwitch)"

                if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                    Write-LogMessage -Type INFO -Message "Collecting Workspace ONE Access Local Directory Password Policies for $workflowMessage."
                    $wsaDirectoryPasswordExpiration = Invoke-Expression "Publish-WsaDirectoryPasswordPolicy -server $wsaFqdn -user admin -pass $wsaAdminPass -policy PasswordExpiration $($commandSwitch)"
                    $wsaDirectoryPasswordComplexity = Invoke-Expression "Publish-WsaDirectoryPasswordPolicy -server $wsaFqdn -user admin -pass $wsaAdminPass -policy PasswordComplexity $($commandSwitch)"
                    $wsaDirectoryAccountLockout = Invoke-Expression "Publish-WsaDirectoryPasswordPolicy -server $wsaFqdn -user admin -pass $wsaAdminPass -policy AccountLockout $($commandSwitch)"

                    Write-LogMessage -Type INFO -Message "Collecting Workspace ONE Access Local User Password Policies for $workflowMessage."
                    $wsaLocalPasswordExpiration = Invoke-Expression "Publish-WsaLocalPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordExpiration -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass $($commandSwitch)"
                    $wsaLocalPasswordComplexity = Invoke-Expression "Publish-WsaLocalPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy PasswordComplexity -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass $($commandSwitch)"
                    $wsaLocalAccountLockout = Invoke-Expression "Publish-WsaLocalPasswordPolicy -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -policy AccountLockout -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass $($commandSwitch)"
                }

                if ($PsBoundParameters.ContainsKey("json")) {
                    # Add VCF version into JSON file
                    $vcfVersion = New-Object -TypeName psobject
                    $vcfVersion | Add-Member -notepropertyname 'vcfVersion' -notepropertyvalue $version
                    $sddcManagerPasswordPolicy = New-Object -TypeName psobject
                    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $sddcManagerPasswordExpiration
                    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $sddcManagerPasswordComplexity
                    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $sddcManagerAccountLockout
                    $ssoPasswordPolicy = New-Object -TypeName psobject
                    $ssoPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $ssoPasswordExpiration
                    $ssoPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $ssoPasswordComplexity
                    $ssoPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $ssoAccountLockout
                    $vcenterPasswordPolicy = New-Object -TypeName psobject
                    $vcenterPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $vcenterPasswordExpiration
                    $vcenterLocalPasswordPolicy = New-Object -TypeName psobject
                    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $vcenterLocalPasswordExpiration
                    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $vcenterLocalPasswordComplexity
                    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $vcenterLocalAccountLockout
                    $nsxManagerPasswordPolicy = New-Object -TypeName psobject
                    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $nsxManagerPasswordExpiration
                    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $nsxManagerPasswordComplexity
                    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $nsxManagerAccountLockout
                    $nsxEdgePasswordPolicy = New-Object -TypeName psobject
                    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $nsxEdgePasswordExpiration
                    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $nsxEdgePasswordComplexity
                    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $nsxEdgeAccountLockout
                    $esxiPasswordPolicy = New-Object -TypeName psobject
                    $esxiPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $esxiPasswordExpiration
                    $esxiPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $esxiPasswordComplexity
                    $esxiPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $esxiAccountLockout
                    if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                        $wsaDirectoryPasswordPolicy = New-Object -TypeName psobject
                        $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $wsaDirectoryPasswordExpiration
                        $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $wsaDirectoryPasswordComplexity
                        $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $wsaDirectoryAccountLockout
                        $wsaLocalPasswordPolicy = New-Object -TypeName psobject
                        $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $wsaLocalPasswordExpiration
                        $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $wsaLocalPasswordComplexity
                        $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $wsaLocalAccountLockout
                    }

                    # Build Final Default Password Policy Object
                    $outputJsonObject = New-Object -TypeName psobject
                    $outputJsonObject | Add-Member -notepropertyname 'vcf' -notepropertyvalue $vcfVersion
                    $outputJsonObject | Add-Member -notepropertyname 'sddcManager' -notepropertyvalue $sddcManagerPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'sso' -notepropertyvalue $ssoPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'vcenterServer' -notepropertyvalue $vcenterPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'vcenterServerLocal' -notepropertyvalue $vcenterLocalPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'nsxManager' -notepropertyvalue $nsxManagerPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'nsxEdge' -notepropertyvalue $nsxEdgePasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'esxi' -notepropertyvalue $esxiPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'wsaDirectory' -notepropertyvalue $wsaDirectoryPasswordPolicy
                    $outputJsonObject | Add-Member -notepropertyname 'wsaLocal' -notepropertyvalue $wsaLocalPasswordPolicy
                    $jsonFile = ($reportFolder + "passwordPolicyManager" + ".json")
                    Write-LogMessage -Type INFO -Message "Generating the Final JSON and Saving to ($jsonFile)."
                    $outputJsonObject | ConvertTo-Json | Out-File -FilePath $jsonFile
                } else {
                    # Combine all information gathered into a single HTML report
                    if ($PsBoundParameters.ContainsKey("allDomains")) {
                        $reportData = "<h1>SDDC Manager: $sddcManagerFqdn</h1>"
                    } else{
                        $reportData = "<h1>Workload Domain: $workloadDomain</h1>"
                    }
                    $reportData += $sddcManagerPasswordExpiration
                    $reportData += $ssoPasswordExpiration
                    $reportData += $vcenterPasswordExpiration
                    $reportData += $vcenterLocalPasswordExpiration
                    $reportData += $nsxManagerPasswordExpiration
                    $reportData += $nsxEdgePasswordExpiration
                    $reportData += $esxiPasswordExpiration
                    if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                        $reportData += $wsaDirectoryPasswordExpiration
                        $reportData += $wsaLocalPasswordExpiration
                    } else {
                        $reportData += ($wsaDirectoryPasswordExpiration | ConvertTo-Html -Fragment -PreContent '<a id="wsa-directory-password-expiration"></a><h3>Workspace ONE Access Directory - Password Expiration</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                        $reportData += ($wsaLocalPasswordExpiration | ConvertTo-Html -Fragment -PreContent '<a id="wsa-local-password-expiration"></a><h3>Workspace ONE Access (Local Users) - Password Expiration</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                    }
                    $reportData += $sddcManagerPasswordComplexity
                    $reportData += $ssoPasswordComplexity
                    $reportData += $vcenterLocalPasswordComplexity
                    $reportData += $nsxManagerPasswordComplexity
                    $reportData += $nsxEdgePasswordComplexity
                    $reportData += $esxiPasswordComplexity
                    if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                        $reportData += $wsaDirectoryPasswordComplexity
                        $reportData += $wsaLocalPasswordComplexity
                    } else {
                        $reportData += ($wsaDirectoryPasswordComplexity | ConvertTo-Html -Fragment -PreContent '<a id="wsa-directory-password-complexity"></a><h3>Workspace ONE Access Directory - Password Complexity</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                        $reportData += ($wsaLocalPasswordComplexity | ConvertTo-Html -Fragment -PreContent '<a id="wsa-local-password-complexity"></a><h3>Workspace ONE Access (Local Users) - Password Complexity</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                    }
                    $reportData += $sddcManagerAccountLockout
                    $reportData += $ssoAccountLockout
                    $reportData += $vcenterLocalAccountLockout
                    $reportData += $nsxManagerAccountLockout
                    $reportData += $nsxEdgeAccountLockout
                    $reportData += $esxiAccountLockout
                    if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                        $reportData += $wsaDirectoryAccountLockout
                        $reportData += $wsaLocalAccountLockout
                    } else {
                        $reportData += ($wsaDirectoryAccountLockout | ConvertTo-Html -Fragment -PreContent '<a id="wsa-directory-account-lockout"></a><h3>Workspace ONE Access Directory - Account Lockout</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                        $reportData += ($wsaLocalAccountLockout | ConvertTo-Html -Fragment -PreContent '<a id="wsa-local-account-lockout"></a><h3>Workspace ONE Access (Local Users) - Account Lockout</h3>' -PostContent '<p>Workspace ONE Access Not Requested</p>')
                    }

                    if ($PsBoundParameters.ContainsKey("darkMode")) {
                        $reportHeader = Save-ClarityReportHeader -dark
                    } else {
                        $reportHeader = Save-ClarityReportHeader
                    }
                    $reportNavigation = Save-ClarityReportNavigation
                    $reportFooter = Save-ClarityReportFooter

                    $report = $reportHeader
                    $report += $reportNavigation
                    $report += $reportData
                    $report += $reportFooter

                    # Generate the report to an HTML file and then open it in the default browser
                    Write-LogMessage -Type INFO -Message "Generating the Final Report and Saving to ($reportName)."
                    $report | Out-File $reportName
                    if ($PSEdition -eq "Core" -and ($PSVersionTable.OS).Split(' ')[0] -ne "Linux") {
                        Invoke-Item $reportName
                    } elseif ($PSEdition -eq "Desktop") {
                        Invoke-Item $reportName
                    }
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Invoke-PasswordPolicyManager

Function Start-PasswordPolicyConfig {
    <#
        .SYNOPSIS
        Configures all Password Policies

        .DESCRIPTION
        The Start-PasswordPolicyConfig configures the password policies across all components of the VMware Cloud
        Foundation instance using the JSON configuration file procided.

        .EXAMPLE
        Start-PasswordPolicyConfig -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -policyFile passwordPolicyConfig.json
        This examples configures all password policies for all components across a VMware Cloud Foundation instance

        .EXAMPLE
        Start-PasswordPolicyConfig -sddcManagerFqdn sfo-vcf01.sfo.rainpole.io -sddcManagerUser admin@local -sddcManagerPass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -reportPath F:\Reporting -policyFile passwordPolicyConfig.json -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -wsaAdminPass VMw@re1!
        This example configures all password policies for all components across a VMware Cloud Foundation instance and Workspace ONE Access

        .PARAMETER sddcManagerFqdn
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER sddcManagerUser
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER sddcManagerPass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER sddcRootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the JSON file containing the policy configuration.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER wsaAdminPass
        The password for the Workspace ONE Access admin account.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerUser,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcRootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false, ParameterSetName = 'wsa')] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $false, ParameterSetName = 'wsa')] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $false, ParameterSetName = 'wsa')] [ValidateNotNullOrEmpty()] [String]$wsaAdminPass
    )

    Clear-Host; Write-Host ""

    Try {
        if (Test-VCFConnection -server $sddcManagerFqdn) {
            if (Test-VCFAuthentication -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass) {
                Start-SetupLogFile -Path $reportPath -ScriptName $MyInvocation.MyCommand.Name # Setup Log Location and Log File
                if (!(Test-Path -Path $reportPath)) {Write-Warning "Unable to locate report path $reportPath, enter a valid path and try again"; Write-Host ""; Break }
                if (!(Test-Path -Path $($reportPath + '\' + $policyFile))) {Write-Warning "Unable to locate policy file $policyFile, enter a valid path and try again"; Write-Host ""; Break }
                Write-LogMessage -Type INFO -Message "Starting the Process of Configuring Password Policies for SDDC Manager Instance ($sddcManagerFqdn)." -Colour Yellow
                $customPolicy = Get-Content -Path $($reportPath + '\' + $policyFile) | ConvertFrom-Json
                $sddcDomainMgmt = (Get-VCFWorkloadDomain | Where-Object {$_.type -eq "MANAGEMENT"}).name
                $allWorkloadDomains = Get-VCFWorkloadDomain

                # Configuring Password Policies for SDDC Manager
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for SDDC Manager Instance ($sddcManagerFqdn)" -Colour Yellow
                Write-LogMessage -Type INFO -Message "Configuring SDDC Manager Instance ($sddcManagerFqdn): Password Expiration Policy"
                $localUsers = @("vcf","root")
                foreach ($localUser in $localUsers) {
                    $StatusMsg = Update-LocalUserPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $sddcDomainMgmt -vmName ($sddcManagerFqdn.Split('.')[-0]) -guestUser root -guestPassword $sddcRootPass -localUser $localUser -minDays $customPolicy.sddcManager.passwordExpiration.minDays -maxDays $customPolicy.sddcManager.passwordExpiration.maxDays -warnDays $customPolicy.sddcManager.passwordExpiration.warningDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                }
                Write-LogMessage -Type INFO -Message "Configuring SDDC Manager Instance ($sddcManagerFqdn): Password Complexity Policy"
                $StatusMsg = Update-SddcManagerPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -rootPass $sddcRootPass -minLength $customPolicy.sddcManager.passwordComplexity.minLength -minLowercase $customPolicy.sddcManager.passwordComplexity.minLowercase -minUppercase $customPolicy.sddcManager.passwordComplexity.minUppercase -minNumerical $customPolicy.sddcManager.passwordComplexity.minNumerical -minSpecial $customPolicy.sddcManager.passwordComplexity.minSpecial -minUnique $customPolicy.sddcManager.passwordComplexity.minUnique -minClass $customPolicy.sddcManager.passwordComplexity.minClass -maxSequence $customPolicy.sddcManager.passwordComplexity.maxSequence -history $customPolicy.sddcManager.passwordComplexity.history -maxRetry $customPolicy.sddcManager.passwordComplexity.retries -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                Write-LogMessage -Type INFO -Message "Configuring SDDC Manager Instance ($sddcManagerFqdn): Account Lockout Policy"
                $StatusMsg = Update-SddcManagerAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -rootPass $sddcRootPass -failures $customPolicy.sddcManager.accountLockout.maxFailures -unlockInterval $customPolicy.sddcManager.accountLockout.unlockInterval -rootUnlockInterval $customPolicy.sddcManager.accountLockout.rootUnlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for SDDC Manager Instance ($sddcManagerFqdn)" -Colour Yellow

                # Configuring Password Policies for vCenter Single Sign-On
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for vCenter Single Sign-On" -Colour Yellow
                Write-LogMessage -Type INFO -Message "Configuring vCenter Single Sign-On: Password Expiration Policy"
                $StatusMsg = Update-SsoPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $sddcDomainMgmt -maxDays $customPolicy.sso.passwordExpiration.maxDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                Write-LogMessage -Type INFO -Message "Configuring vCenter Single Sign-On: Password Complexity Policy"
                $StatusMsg = Update-SsoPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $sddcDomainMgmt -minLength $customPolicy.sso.passwordComplexity.minLength -maxLength $customPolicy.sso.passwordComplexity.maxLength -minAlphabetic $customPolicy.sso.passwordComplexity.minAlphabetic -minLowercase $customPolicy.sso.passwordComplexity.minLowercase -minUppercase $customPolicy.sso.passwordComplexity.minUppercase -minNumeric $customPolicy.sso.passwordComplexity.minNumerical -minSpecial $customPolicy.sso.passwordComplexity.minSpecial -maxIdenticalAdjacent $customPolicy.sso.passwordComplexity.maxIdenticalAdjacent -history $customPolicy.sso.passwordComplexity.history -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                $StatusMsg = Write-LogMessage -Type INFO -Message "Configuring vCenter Single Sign-On: Account Lockout Policy"
                $StatusMsg = Update-SsoAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $sddcDomainMgmt -failures $customPolicy.sso.accountLockout.maxFailures -failureInterval $customPolicy.sso.accountLockout.failedAttemptInterval -unlockInterval $customPolicy.sso.accountLockout.unlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for vCenter Single Sign-On" -Colour Yellow

                # Configuring Password Policies for vCenter Server
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for vCenter Server" -Colour Yellow
                foreach ($workloadDomain in $allWorkloadDomains) {
                    Write-LogMessage -Type INFO -Message "Starting the Process of Configuring Password Policies for vCenter Server for Workload Domain ($($workloadDomain.name))" -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Configuring vCenter Server: Password Expiration Policy for Workload Domain ($($workloadDomain.name))"
                    $StatusMsg = Update-VcenterPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -maxDays $customPolicy.vcenterServer.passwordExpiration.maxDays -minDays $customPolicy.vcenterServer.passwordExpiration.minDays -warnDays $customPolicy.vcenterServer.passwordExpiration.warningDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring vCenter Server Local Users: Password Expiration Policy for Workload Domain ($($workloadDomain.name))"
                    $StatusMsg = Update-VcenterRootPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $workloadDomain.name -email $customPolicy.vcenterServerLocal.passwordExpiration.email -maxDays $customPolicy.vcenterServerLocal.passwordExpiration.maxDays -warnDays $customPolicy.vcenterServerLocal.passwordExpiration.warningDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring vCenter Server Local Users: Password Complexity Policy for Workload Domain ($($workloadDomain.name))"
                    $StatusMsg = Update-VcenterPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $workloadDomain.name -minLength $customPolicy.vcenterServerLocal.passwordComplexity.minLength -minLowercase $customPolicy.vcenterServerLocal.passwordComplexity.minLowercase -minUppercase $customPolicy.vcenterServerLocal.passwordComplexity.minUppercase -minNumerical $customPolicy.vcenterServerLocal.passwordComplexity.minNumerical -minSpecial $customPolicy.vcenterServerLocal.passwordComplexity.minSpecial -minUnique $customPolicy.vcenterServerLocal.passwordComplexity.minUnique -history $customPolicy.vcenterServerLocal.passwordComplexity.history -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring vCenter Server Local Users: Account Lockout Policy for Workload Domain ($($workloadDomain.name))"
                    $StatusMsg = Update-VcenterAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $workloadDomain.name -failures $customPolicy.vcenterServerLocal.accountLockout.maxFailures -unlockInterval $customPolicy.vcenterServerLocal.accountLockout.unlockInterval -rootUnlockInterval $customPolicy.vcenterServerLocal.accountLockout.rootUnlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for vCenter Server" -Colour Yellow

                # Configuring Password Policies for NSX Local Managers
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for NSX Local Managers" -Colour Yellow
                foreach ($workloadDomain in $allWorkloadDomains) {
                    Write-LogMessage -Type INFO -Message "Starting the Process of Configuring Password Policies for the NSX Local Manager for Workload Domain ($($workloadDomain.name))" -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Configuring NSX Local Managers: Password Expiration Policy ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtManagerPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -maxdays $customPolicy.nsxEdge.passwordExpiration.maxDays -detail false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring NSX Local Managers: Password Complexity Policy ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtManagerPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -minLength $customPolicy.nsxManager.passwordComplexity.minLength -minLowercase $customPolicy.nsxManager.passwordComplexity.minLowercase -minUppercase $customPolicy.nsxManager.passwordComplexity.minUppercase -minNumerical $customPolicy.nsxManager.passwordComplexity.minNumerical -minSpecial $customPolicy.nsxManager.passwordComplexity.minSpecial -minUnique $customPolicy.nsxManager.passwordComplexity.minUnique -maxRetry $customPolicy.nsxManager.passwordComplexity.retries -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Password Complexity Policy on NSX Local Managers for Workload Domain ($($workloadDomain.name)): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Password Complexity Policy on NSX Local Managers for Workload Domain ($($workloadDomain.name)), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring NSX Local Managers: Account Lockout Policy ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtManagerAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -cliFailures $customPolicy.nsxManager.accountLockout.cliMaxFailures -cliUnlockInterval $customPolicy.nsxManager.accountLockout.cliUnlockInterval -apiFailures $customPolicy.nsxManager.accountLockout.apiMaxFailures -apiFailureInterval $customPolicy.nsxManager.accountLockout.apiRestInterval -apiUnlockInterval $customPolicy.nsxManager.accountLockout.apiUnlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Account Lockout Policy on NSX Local Managers for Workload Domain ($($workloadDomain.name)): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Account Lockout Policy on NSX Local Managers for Workload Domain ($($workloadDomain.name)), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for NSX Local Managers" -Colour Yellow

                # Configuring Password Policies for NSX Edge Nodes
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for NSX Edge Nodes" -Colour Yellow
                foreach ($workloadDomain in $allWorkloadDomains) {
                    Write-LogMessage -Type INFO -Message "Starting the Process of Configuring Password Policies for the NSX Edge for Workload Domain ($($workloadDomain.name))" -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Configuring NSX Edge Nodes: Password Expiration Policy for Workload Domain ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtEdgePasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -maxdays $customPolicy.nsxEdge.passwordExpiration.maxDays -detail false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring NSX Edge Nodes: Password Complexity Policy ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtEdgePasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -minLength $customPolicy.nsxEdge.passwordComplexity.minLength -minLowercase $customPolicy.nsxEdge.passwordComplexity.minLowercase -minUppercase $customPolicy.nsxEdge.passwordComplexity.minUppercase -minNumerical $customPolicy.nsxEdge.passwordComplexity.minNumerical -minSpecial $customPolicy.nsxEdge.passwordComplexity.minSpecial -minUnique $customPolicy.nsxEdge.passwordComplexity.minUnique -maxRetry $customPolicy.nsxEdge.passwordComplexity.retries -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Password Complexity Policy on NSX Edge Nodes for Workload Domain ($($workloadDomain.name)): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Password Complexity Policy on NSX Edge Nodes for Workload Domain ($($workloadDomain.name)), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring NSX Edge Nodes: Account Lockout Policy ($($workloadDomain.name))"
                    $StatusMsg = Update-NsxtEdgeAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -cliFailures $customPolicy.nsxEdge.accountLockout.cliMaxFailures -cliUnlockInterval $customPolicy.nsxEdge.accountLockout.cliUnlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Password Complexity Policy on NSX Edge Nodes for Workload Domain ($($workloadDomain.name)): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Account Lockout Policy on NSX Edge Nodes for Workload Domain ($($workloadDomain.name)), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for NSX Edge Nodes" -Colour Yellow

                # Configuring Password Policies for ESXi Hosts
                Write-LogMessage -Type INFO -Message "Configuring Password Policies for ESXi Hosts" -Colour Yellow
                foreach ($workloadDomain in $allWorkloadDomains) {
                    Write-LogMessage -Type INFO -Message "Starting the Process of Configuring Password Policies for the ESXi Hosts for Workload Domain ($($workloadDomain.name))" -Colour Yellow
                    $clusters = $workloadDomain.clusters
                    Write-LogMessage -Type INFO -Message "Configuring ESXi Hosts: Password Expiration Policy for Workload Domain ($($workloadDomain.name))"
                    foreach ($cluster in $clusters) {
                        $clusterName = (Get-VCFCluster -id $cluster.id).name
                        $StatusMsg = Update-EsxiPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -cluster $clusterName -maxDays $customPolicy.esxi.passwordExpiration.maxDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                        if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Password Expiration Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Password Expiration Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    }
                    Write-LogMessage -Type INFO -Message "Configuring ESXi Hosts: Password Complexity Policy for Workload Domain ($($workloadDomain.name))"
                    foreach ($cluster in $clusters) {
                        $clusterName = (Get-VCFCluster -id $cluster.id).name
                        $StatusMsg = Update-EsxiPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -cluster $clusterName -policy $customPolicy.esxi.passwordComplexity.policy -history $customPolicy.esxi.passwordComplexity.history -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                        if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Password Complexity Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Password Complexity Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    }
                    Write-LogMessage -Type INFO -Message "Configuring ESXi Hosts: Account Lockout Policy for Workload Domain ($($workloadDomain.name))"
                    foreach ($cluster in $clusters) {
                        $clusterName = (Get-VCFCluster -id $cluster.id).name
                        $StatusMsg = Update-EsxiAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $($workloadDomain.name) -cluster $clusterName -failures $customPolicy.esxi.accountLockout.maxFailures -unlockInterval $customPolicy.esxi.accountLockout.unlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                        if ( $StatusMsg -match "SUCCESSFUL" ) { Write-LogMessage -Type INFO -Message "Update Account Lockout Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName): SUCCESSFUL" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message "Update Account Lockout Policy on ESXi Hosts for Worload Domain / Cluster ($($workloadDomain.name) / $clusterName), already set: SKIPPED" -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    }
                }
                Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for ESXi Hosts" -Colour Yellow

                # Configuring Password Policies for Workspace ONE Access
                if ($PsBoundParameters.ContainsKey("wsaFqdn")) {
                    # Workspace ONE Access Directory Password Policies
                    Write-LogMessage -Type INFO -Message "Configuring Password Policies for Workspace ONE Access Local Directory" -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Directory: Password Expiration Policy for instance ($($wsaFqdn))"
                    $StatusMsg = Update-WsaPasswordExpiration -server $wsaFqdn -user admin -pass $wsaAdminPass -maxDays $customPolicy.wsaDirectory.passwordExpiration.passwordLifetime -warnDays $customPolicy.wsaDirectory.passwordExpiration.passwordReminder -reminderDays $customPolicy.wsaDirectory.passwordExpiration.passwordReminderFrequency -tempPasswordHours $customPolicy.wsaDirectory.passwordExpiration.temporaryPassword -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Directory: Password Complexity Policy for instance ($($wsaFqdn))"
                    $StatusMsg = Update-WsaPasswordComplexity -server $wsaFqdn -user admin -pass $wsaAdminPass -minLength $customPolicy.wsaDirectory.passwordComplexity.minLength -minLowercase $customPolicy.wsaDirectory.passwordComplexity.minLowercase -minUppercase $customPolicy.wsaDirectory.passwordComplexity.minUppercase -minNumeric $customPolicy.wsaDirectory.passwordComplexity.minNumerical -minSpecial $customPolicy.wsaDirectory.passwordComplexity.minSpecial -maxIdenticalAdjacent $customPolicy.wsaDirectory.passwordComplexity.maxIdenticalAdjacent -maxPreviousCharacters $customPolicy.wsaDirectory.passwordComplexity.history -history $customPolicy.wsaDirectory.passwordComplexity.history -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Directory: Account Lockout Policy for instance ($($wsaFqdn))"
                    $StatusMsg = Update-WsaAccountLockout -server $wsaFqdn -user admin -pass $wsaAdminPass -failures $customPolicy.wsaDirectory.accountLockout.maxFailures -failureInterval $customPolicy.wsaDirectory.accountLockout.failedAttemptInterval -unlockInterval $customPolicy.wsaDirectory.accountLockout.unlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for Workspace ONE Access Local Directory" -Colour Yellow

                    # Workspace ONE Access Local User Password Policies
                    Write-LogMessage -Type INFO -Message "Configuring Password Policies for Workspace ONE Access Local Users" -Colour Yellow
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Users: Password Expiration Policy for instance ($($wsaFqdn))"
                    $localUsers = @("root","sshuser")
                    foreach ($localUser in $localUsers) {
                        $StatusMsg = Update-LocalUserPasswordExpiration -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -domain $sddcDomainMgmt -vmName ($wsaFqdn.Split('.')[-0]) -guestUser root -guestPassword $wsaRootPass -localUser $localUser -minDays $customPolicy.sddcManager.passwordExpiration.minDays -maxDays $customPolicy.sddcManager.passwordExpiration.maxDays -warnDays $customPolicy.sddcManager.passwordExpiration.warningDays -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                        if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    }
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Users: Password Complexity Policy for instance ($($wsaFqdn))"
                    $StatusMsg = Update-WsaLocalUserPasswordComplexity -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass -minLength $customPolicy.wsaLocal.passwordComplexity.minLength -history $customPolicy.wsaLocal.passwordComplexity.history -maxRetry $customPolicy.wsaLocal.passwordComplexity.retries -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Configuring Workspace ONE Access Local Users: Account Lockout Policy for instance ($($wsaFqdn))"
                    $StatusMsg = Update-WsaLocalUserAccountLockout -server $sddcManagerFqdn -user $sddcManagerUser -pass $sddcManagerPass -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass -failures $customPolicy.wsaLocal.accountLockout.maxFailures -unlockInterval $customPolicy.wsaLocal.accountLockout.unlockInterval -rootUnlockInterval $customPolicy.wsaLocal.accountLockout.rootUnlockInterval -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -WarningVariable WarnMsg -ErrorVariable ErrorMsg
                    if ( $StatusMsg ) { Write-LogMessage -Type INFO -Message "$StatusMsg" } if ( $WarnMsg ) { Write-LogMessage -Type WARNING -Message $WarnMsg -Colour Magenta } if ( $ErrorMsg ) { Write-LogMessage -Type ERROR -Message $ErrorMsg -Colour Red }
                    Write-LogMessage -Type INFO -Message "Completed Configuring Password Policies for Workspace ONE Access Local Users" -Colour Yellow
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Start-PasswordPolicyConfig

Function Get-PasswordPolicyDefault {
    <#
		.SYNOPSIS
        Get password policy default settings

        .DESCRIPTION
        The Get-PasswordPolicyDefault cmdlet returns the default password policy settings, it can also be used to
        generate the base JSON file used with Password Policy Manager. Default settings for VMware products include:
        - VMware SDDC Manager
        - VMware ESXi
        - VMware vCenter Single Sign-On
        - VMware vCenter Server
        - VMware NSX Manager
        - VMware NSX Edge
        - VMware Workspace ONE Access

        .EXAMPLE
        Get-PasswordPolicyDefault -version '5.0.0'
        This example returns the default password policy settings for the VMware Cloud Foundation version 5.0.0

        .EXAMPLE
        Get-PasswordPolicyDefault -generateJson -jsonFile passwordPolicyConfig.json -version '5.0.0'
        This example creates a JSON file named passwordPolicyConfig.json with the default password policy settings for the given version of VMware Cloud Foundation
        
        .EXAMPLE
        Get-PasswordPolicyDefault -generateJson -jsonFile passwordPolicyConfig.json -version '5.0.0'
        This example creates a JSON file named passwordPolicyConfig.json with the default password policy settings for the given version of VMware Cloud Foundation. 
        If passwordPolicyConfig.json is already present, it is overwritten due to 'force' parameter.

        .PARAMETER generateJson
        Switch to generate a JSON file.

        .PARAMETER version
        The VMware Cloud Foundation version to get policy defaults for the JSON file.

        .PARAMETER jsonFile
        The name of the JSON file to generate.
        
        .PARAMETER force
        The switch used to overwrite the JSON file if already exists.
    #>

    [CmdletBinding(DefaultParametersetName = "All")][OutputType('System.Management.Automation.PSObject')]

    Param (
        [Parameter (Mandatory = $false, ParameterSetName = 'json')] [ValidateNotNullOrEmpty()] [Switch]$generateJson,
        [Parameter (Mandatory = $true)] [ValidateSet('4.4.0','4.5.1','5.0.0')] [String]$version,
        [Parameter (Mandatory = $true, ParameterSetName = 'json')] [ValidateNotNullOrEmpty()] [String]$jsonFile,
        [Parameter (Mandatory = $false, ParameterSetName = 'json')] [ValidateNotNullOrEmpty()] [Switch]$force
    )
    if ($PSBoundParameters.ContainsKey('jsonFile')) {
        if (Test-Path -Path $jsonFile -PathType Container) {
            Write-Error "The -jsonfile parameter ($jsonfile) contains a folder name and no filename. Please retry."
            Break
        } else {
            if ((split-path -Path $jsonFile -leaf).split(".")[1] -ne "json") {
                Write-Error "The filename provided  doesn't contain a .json extension, please retry."
                Break
            } else {
                if(Test-Path $jsonFile -PathType leaf) {
                    if ($PSBoundParameters.ContainsKey('force')) {
                        Write-Warning "The filename provided ($jsonFile) already exists, the file will be overwritten."
                    } else {
                        Write-Error "The filename provided ($jsonFile) already exists. Delete or use the -force switch to replace the file."
                        Break
                    }
                }
            }
        }
    }



    # Add VCF version into JSON file
    $vcfVersion = New-Object -TypeName psobject
    $vcfVersion | Add-Member -notepropertyname 'vcfVersion' -notepropertyvalue $version

    # Build Default ESXi Password Policy Settings
    $esxiPasswordExpiration = New-Object -TypeName psobject
    $esxiPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "99999"
    $esxiPasswordComplexity = New-Object -TypeName psobject
    $esxiPasswordComplexity | Add-Member -notepropertyname 'policy' -notepropertyvalue "retry=3 min=disabled,disabled,disabled,7,7"
    $esxiPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "0"
    $esxiAccountLockout = New-Object -TypeName psobject
    $esxiAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "5"
    $esxiAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "900"
    $esxiPasswordPolicy = New-Object -TypeName psobject
    $esxiPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $esxiPasswordExpiration
    $esxiPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $esxiPasswordComplexity
    $esxiPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $esxiAccountLockout

    # Build Default vCenter Single Sign-On Password Policy Settings
    $ssoPasswordExpiration = New-Object -TypeName psobject
    $ssoPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $ssoPasswordComplexity = New-Object -TypeName psobject
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "8"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'maxLength' -notepropertyvalue "20"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minAlphabetic' -notepropertyvalue "2"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "1"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "1"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "1"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "1"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'maxIdenticalAdjacent' -notepropertyvalue "1"
    $ssoPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "5"
    $ssoAccountLockout = New-Object -TypeName psobject
    $ssoAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "5"
    $ssoAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "900"
    $ssoAccountLockout | Add-Member -notepropertyname 'failedAttemptInterval' -notepropertyvalue "180"
    $ssoPasswordPolicy = New-Object -TypeName psobject
    $ssoPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $ssoPasswordExpiration
    $ssoPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $ssoPasswordComplexity
    $ssoPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $ssoAccountLockout

    # Build Default vCenter Server Password Policy Settings
    $vcenterPasswordExpiration = New-Object -TypeName psobject
    $vcenterPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $vcenterPasswordExpiration | Add-Member -notepropertyname 'minDays' -notepropertyvalue "0"
    $vcenterPasswordExpiration | Add-Member -notepropertyname 'warningDays' -notepropertyvalue "7"
    $vcenterPasswordPolicy = New-Object -TypeName psobject
    $vcenterPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $vcenterPasswordExpiration

    # Build Default vCenter Server Local Users Password Policy Settings
    $vcenterLocalPasswordExpiration = New-Object -TypeName psobject
    $vcenterLocalPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $vcenterLocalPasswordExpiration | Add-Member -notepropertyname 'minDays' -notepropertyvalue "0"
    $vcenterLocalPasswordExpiration | Add-Member -notepropertyname 'warningDays' -notepropertyvalue "7"
    $vcenterLocalPasswordExpiration | Add-Member -notepropertyname 'email' -notepropertyvalue ""
    $vcenterLocalPasswordComplexity = New-Object -TypeName psobject
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "6"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "-1"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "-1"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "-1"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "-1"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'minUnique' -notepropertyvalue "4"
    $vcenterLocalPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "5"
    $vcenterLocalAccountLockout = New-Object -TypeName psobject
    $vcenterLocalAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "3"
    $vcenterLocalAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "900"
    $vcenterLocalAccountLockout | Add-Member -notepropertyname 'rootUnlockInterval' -notepropertyvalue "300"
    $vcenterLocalPasswordPolicy = New-Object -TypeName psobject
    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $vcenterLocalPasswordExpiration
    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $vcenterLocalPasswordComplexity
    $vcenterLocalPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $vcenterLocalAccountLockout

    # Build Default NSX Manager Local Users Password Policy Settings
    $nsxManagerPasswordExpiration = New-Object -TypeName psobject
    $nsxManagerPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $nsxManagerPasswordComplexity = New-Object -TypeName psobject
    if($version -ge "5.0") {
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "12"
    } else {
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "15"
    }    
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "-1"
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "-1"
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "-1"
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "-1"
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'minUnique' -notepropertyvalue "0"
    $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'retries' -notepropertyvalue "3"
    if($version -ge "5.0") {
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'maxLength' -notepropertyvalue "128"
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'maxSequence' -notepropertyvalue "0"
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'maxRepeat' -notepropertyvalue "0"
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'passwordRemembrance' -notepropertyvalue "0"
        $nsxManagerPasswordComplexity | Add-Member -notepropertyname 'hashAlgorithm' -notepropertyvalue "sha512"
    }
    $nsxManagerAccountLockout = New-Object -TypeName psobject
    $nsxManagerAccountLockout | Add-Member -notepropertyname 'apiMaxFailures' -notepropertyvalue "5"
    $nsxManagerAccountLockout | Add-Member -notepropertyname 'apiUnlockInterval' -notepropertyvalue "900"
    $nsxManagerAccountLockout | Add-Member -notepropertyname 'apiRestInterval' -notepropertyvalue "180"
    $nsxManagerAccountLockout | Add-Member -notepropertyname 'cliMaxFailures' -notepropertyvalue "5"
    $nsxManagerAccountLockout | Add-Member -notepropertyname 'cliUnlockInterval' -notepropertyvalue "900"
    $nsxManagerPasswordPolicy = New-Object -TypeName psobject
    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $nsxManagerPasswordExpiration
    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $nsxManagerPasswordComplexity
    $nsxManagerPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $nsxManagerAccountLockout

    # Build Default NSX Edge Local Users Password Policy Settings
    $nsxEdgePasswordExpiration = New-Object -TypeName psobject
    $nsxEdgePasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $nsxEdgePasswordComplexity = New-Object -TypeName psobject
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "15"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "-1"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "-1"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "-1"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "-1"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'minUnique' -notepropertyvalue "0"
    $nsxEdgePasswordComplexity | Add-Member -notepropertyname 'retries' -notepropertyvalue "3"
    $nsxEdgeAccountLockout = New-Object -TypeName psobject
    $nsxEdgeAccountLockout | Add-Member -notepropertyname 'cliMaxFailures' -notepropertyvalue "5"
    $nsxEdgeAccountLockout | Add-Member -notepropertyname 'cliUnlockInterval' -notepropertyvalue "900"
    $nsxEdgePasswordPolicy = New-Object -TypeName psobject
    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $nsxEdgePasswordExpiration
    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $nsxEdgePasswordComplexity
    $nsxEdgePasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $nsxEdgeAccountLockout

    # Build Default SDDC Manager Local Users Password Policy Settings
    $sddcManagerPasswordExpiration = New-Object -TypeName psobject
    $sddcManagerPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "90"
    $sddcManagerPasswordExpiration | Add-Member -notepropertyname 'minDays' -notepropertyvalue "0"
    $sddcManagerPasswordExpiration | Add-Member -notepropertyname 'warningDays' -notepropertyvalue "7"
    $sddcManagerPasswordComplexity = New-Object -TypeName psobject
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "8"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "-1"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "-1"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "-1"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "-1"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minUnique' -notepropertyvalue "4"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'minClass' -notepropertyvalue "4"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'maxSequence' -notepropertyvalue "0"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'retries' -notepropertyvalue "3"
    $sddcManagerPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "5"
    $sddcManagerAccountLockout = New-Object -TypeName psobject
    $sddcManagerAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "3"
    $sddcManagerAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "86400"
    $sddcManagerAccountLockout | Add-Member -notepropertyname 'rootUnlockInterval' -notepropertyvalue "300"
    $sddcManagerPasswordPolicy = New-Object -TypeName psobject
    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $sddcManagerPasswordExpiration
    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $sddcManagerPasswordComplexity
    $sddcManagerPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $sddcManagerAccountLockout

    # Build Default Workspace ONE Access Local Users Password Policy Settings
    $wsaLocalPasswordExpiration = New-Object -TypeName psobject
    $wsaLocalPasswordExpiration | Add-Member -notepropertyname 'maxDays' -notepropertyvalue "60"
    $wsaLocalPasswordExpiration | Add-Member -notepropertyname 'minDays' -notepropertyvalue "0"
    $wsaLocalPasswordExpiration | Add-Member -notepropertyname 'warningDays' -notepropertyvalue "7"
    $wsaLocalPasswordComplexity = New-Object -TypeName psobject
    $wsaLocalPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "1"
    $wsaLocalPasswordComplexity | Add-Member -notepropertyname 'retries' -notepropertyvalue "3"
    $wsaLocalPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "5"
    $wsaLocalAccountLockout = New-Object -TypeName psobject
    $wsaLocalAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "3"
    $wsaLocalAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "900"
    $wsaLocalAccountLockout | Add-Member -notepropertyname 'rootUnlockInterval' -notepropertyvalue "900"
    $wsaLocalPasswordPolicy = New-Object -TypeName psobject
    $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $wsaLocalPasswordExpiration
    $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $wsaLocalPasswordComplexity
    $wsaLocalPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $wsaLocalAccountLockout

    # Build Default Workspace ONE Access Directory Users Password Policy Settings
    $wsaDirectoryPasswordExpiration = New-Object -TypeName psobject
    $wsaDirectoryPasswordExpiration | Add-Member -notepropertyname 'passwordLifetime' -notepropertyvalue "0"
    $wsaDirectoryPasswordExpiration | Add-Member -notepropertyname 'passwordReminder' -notepropertyvalue "0"
    $wsaDirectoryPasswordExpiration | Add-Member -notepropertyname 'passwordReminderFrequency' -notepropertyvalue "0"
    $wsaDirectoryPasswordExpiration | Add-Member -notepropertyname 'temporaryPassword' -notepropertyvalue "168"
    $wsaDirectoryPasswordComplexity = New-Object -TypeName psobject
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'minLength' -notepropertyvalue "8"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'minLowercase' -notepropertyvalue "0"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'minUppercase' -notepropertyvalue "0"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'minNumerical' -notepropertyvalue "0"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'minSpecial' -notepropertyvalue "0"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'maxIdenticalAdjacent' -notepropertyvalue "0"
    $wsaDirectoryPasswordComplexity | Add-Member -notepropertyname 'history' -notepropertyvalue "0"
    $wsaDirectoryAccountLockout = New-Object -TypeName psobject
    $wsaDirectoryAccountLockout | Add-Member -notepropertyname 'maxFailures' -notepropertyvalue "5"
    $wsaDirectoryAccountLockout | Add-Member -notepropertyname 'unlockInterval' -notepropertyvalue "900"
    $wsaDirectoryAccountLockout | Add-Member -notepropertyname 'failedAttemptInterval' -notepropertyvalue "900"
    $wsaDirectoryPasswordPolicy = New-Object -TypeName psobject
    $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'passwordExpiration' -notepropertyvalue $wsaDirectoryPasswordExpiration
    $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'passwordComplexity' -notepropertyvalue $wsaDirectoryPasswordComplexity
    $wsaDirectoryPasswordPolicy | Add-Member -notepropertyname 'accountLockout' -notepropertyvalue $wsaDirectoryAccountLockout

    # Build Final Default Password Policy Object
    $defaultConfig = New-Object -TypeName psobject
    $defaultConfig | Add-Member -notepropertyname 'vcf' -notepropertyvalue $vcfVersion
    $defaultConfig | Add-Member -notepropertyname 'esxi' -notepropertyvalue $esxiPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'sso' -notepropertyvalue $ssoPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'vcenterServer' -notepropertyvalue $vcenterPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'vcenterServerLocal' -notepropertyvalue $vcenterLocalPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'nsxManager' -notepropertyvalue $nsxManagerPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'nsxEdge' -notepropertyvalue $nsxEdgePasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'sddcManager' -notepropertyvalue $sddcManagerPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'wsaLocal' -notepropertyvalue $wsaLocalPasswordPolicy
    $defaultConfig | Add-Member -notepropertyname 'wsaDirectory' -notepropertyvalue $wsaDirectoryPasswordPolicy

    if ($PSBoundParameters.ContainsKey('generateJson')) {
        $defaultConfig | ConvertTo-Json | Out-File -FilePath $jsonFile
        Write-Output "Generated JSON File ($jsonFile) with Product Password Policy Default Values"
    } else {
        $defaultConfig
    }
}
Export-ModuleMember -Function Get-PasswordPolicyDefault

Function Get-PasswordPolicyConfig {
    Param (
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $true)] [ValidateSet('4.4.0','4.5.1','5.0.0')] [String]$version,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
    )

    if ($policyFile) {
        $policyFilePath = $reportPath + '\' + $policyFile
        if (Test-Path $policyFilePath) {
            Write-Output "Found the Password Policy Configuration File ($policyFilePath)."
            $customConfig = Get-Content -Path $policyFilePath | ConvertFrom-Json
            if ($customConfig.vcf.vcfVersion -eq $version) {
                $result = Test-PasswordPolicyConfig -customConfig $customConfig -version $version
                if ($result -eq "true") {
                    Write-Output "Validation of Password Policy Configuration File: PASSED"
                } else {
                    Write-Error "Validation of Password Policy Configuration File: FAILED"
                    Break
                }
            } else {
                Write-Error "Password Policy Configuration File version is $($customConfig.vcf.vcfVersion) and version provided is $version : FAILED "
                Break
            }
        } else {
            Write-Error "Unable to Locate Password Policy Configuration File. Check the path ($policyFilePath)."
            Break
        }
    } else {
        $customConfig = Get-PasswordPolicyDefault -version $version
    }
    $customConfig
}
Export-ModuleMember -Function Get-PasswordPolicyConfig

Function checkRange {
	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$name,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [int]$value,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [int]$minRange,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [int]$maxRange,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Bool]$required
	)

	if (($value -eq "Null") -and ($required -eq $true)) {
		Write-Error "$name parameter has not been configured."
		return $false
	} elseif (($value -lt $minRange) -or ($value -gt $maxRange)) {
		Write-Error "The recommended range for $name should be between $minRange and $maxRange. [$value]"
		return $false
	} else {
		return $true
	}
}

Function checkEmailString {
	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$name,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$address,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Bool]$required
	)

	if (($address -eq "Null") -and ($required -eq $true)) {
		Write-Error "$name variable has not been configured."
		return $false
	}
	$checkStatement = $address -match "^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$"
	if ($checkStatement -eq $true) {
		return $true
	} else {
		Write-Error "Please input a valid email address for $name "
		return $false
	}
}

Function Test-PasswordPolicyConfig {
    Param (
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [psobject]$customConfig,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [psobject]$version
    )

    # Import default configuration JSON for compare parameters
    $defaultConfig = Get-PasswordPolicyDefault -version $version
    $encounterError = "False"

    # Validating Product Types in the Password Policy Configuration File
    $defaultProductList = $defaultConfig | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
    $customProductList = $customConfig | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
    $defaultSection = "passwordExpiration", "passwordComplexity", "accountLockout", "vcfVersion"

    foreach ($product in $customProductList) {
        if (-Not $defaultProductList.Name.Contains($product.Name)) {
            Write-Error "Found Unknown Product ($($product.Name)), Please check the Password Policy Configuration File and Run Again"
            $encounterError = "True"
            Break
        }
        # Validating Product Sections in the Password Policy Configuration File
        if ($encounterError -ne "True") {
            $customSectionList = $customConfig.($product.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
            foreach ($section in $customSectionList) {
                if (-Not $defaultSection.Contains($section.Name)) {
                    Write-Error "Found Unknown Password Policy Section ($($section.Name)) Under Product ($($product.Name)), Please Check the Password Policy Configuration File and Run Again"
                    $encounterError = "True"
                    Break
                }
                # Validate parameters in customConfig file
                if ($encounterError -ne "True") {
                    $defaultParameterList = $defaultConfig.($product.Name).($section.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
                    $customParameterList = $customConfig.($product.Name).($section.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
                    foreach ( $parameterName in $customParameterList) {
                        if ( -Not $defaultParameterList.Name.Contains($parameterName.Name)) {
                            Write-Error "Found Unknown Parameter ($($parameterName.Name)) Under Section ($($section.Name)) for Product ($($product.Name)), Please Check the Password Policy Configuration File and Run Again"
                            $encounterError = "True"
                            Break
                        } elseif ($parameterName.Name -ne "email" -and $customConfig.($product.Name).($section.Name).($parameterName.Name) -eq "") {
                            Write-Error "Parameter ($($product.Name):$($section.Name):$($parameterName.Name)) Not Configured, Please Check the Password Policy Configuration File and Run Again."
                            $encounterError = "True"
                            Break
                        }
                    }
                }
            }
        }
    }

    # Validating parameter values
    if ($encounterError -ne "True") {
        foreach ($product in $customProductList) {
            $customSectionList = $customConfig.($product.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
            foreach ($section in $customSectionList) {
                $defaultParameterList = $defaultConfig.($product.Name).($section.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
                $customParameterList = $customConfig.($product.Name).($section.Name) | Get-Member | Where-Object {$_.MemberType -match "NoteProperty"} | Select-Object Name
                foreach ( $parameterName in $customParameterList) {
                    # Validating parameter values
                    Switch ($parameterName.Name)  {
                        # Password Expiration Section
                        "maxDays"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxDays" -value $customConfig.($product.Name).($section.Name)."maxDays" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minDays"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minDays" -value $customConfig.($product.Name).($section.Name)."minDays" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "warningDays"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):warningDays" -value $customConfig.($product.Name).($section.Name)."warningDays" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "email"
                        {
                            $emailVariable = $customConfig.($product.Name).($section.Name)."email"
                            if($emailVariable) {
                                $checkReturn = checkEmailString -name "$($product.Name):$($section.Name):email" -address $customConfig.($product.Name).($section.Name)."email" -required $false
                                if (-Not $checkReturn) { $encounterError = "True" }
                            }
                        }
                        "passwordLifetime"
                        {
                            if ($product.Name -eq "wsaDirectory") {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordLifetime" -value $customConfig.($product.Name).($section.Name)."passwordLifetime" -minRange 0 -maxRange 99999 -required $true
                            } else {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordLifetime" -value $customConfig.($product.Name).($section.Name)."passwordLifetime" -minRange 1 -maxRange 99999 -required $true
                            }
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "passwordReminder"
                        {
                            if ($product.Name -eq "wsaDirectory") {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordReminder" -value $customConfig.($product.Name).($section.Name)."passwordReminder" -minRange 0 -maxRange 99999 -required $true
                            } else {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordReminder" -value $customConfig.($product.Name).($section.Name)."passwordReminder" -minRange 1 -maxRange 99999 -required $true
                            }
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "passwordReminderFrequency"
                        {
                            if ($product.Name -eq "wsaDirectory") {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordReminderFrequency" -value $customConfig.($product.Name).($section.Name)."passwordReminderFrequency" -minRange 0 -maxRange 99999 -required $true
                            } else {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):passwordReminderFrequency" -value $customConfig.($product.Name).($section.Name)."passwordReminderFrequency" -minRange 1 -maxRange 99999 -required $true
                            }
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "temporaryPassword"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):temporaryPassword" -value $customConfig.($product.Name).($section.Name)."temporaryPassword" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        # Password Complexity section
                        "policy"
                        {
							$policyString = $customConfig.($product.Name).($section.Name)."policy"
                            $customConfig.($product.Name).($section.Name)."policy" | Select-String -Pattern "^retry=(\d+)\s+min=(.+),(.+),(.+),(.+),(.+)" | Foreach-Object {$PasswdPolicyRetryValue, $PasswdPolicyMinValue1, $PasswdPolicyMinValue2, $PasswdPolicyMinValue3, $PasswdPolicyMinValue4, $PasswdPolicyMinValue5 = $_.Matches[0].Groups[1..6].Value}
                            if ($PasswdPolicyRetryValue -eq "" -or $PasswdPolicyMinValue1 -eq "" -or $PasswdPolicyMinValue2 -eq "" -or $PasswdPolicyMinValue3 -eq "" -or $PasswdPolicyMinValue4 -eq "" -or $PasswdPolicyMinValue5 -eq "") {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "The custom policy file shows $policyString"
                                $encounterError = "True"
                            }
                            if (($PasswdPolicyRetryValue -lt 0) -or ($PasswdPolicyRetryValue -gt 9999)) {
                                Write-Error "The recommended range for retry should be between 0 and 9999"
                                $encounterError = "True"
                            }
                            if ((($PasswdPolicyMinValue1 -lt 7) -or ($PasswdPolicyMinValue1 -gt 999)) -and ($PasswdPolicyMinValue1 -ine "disabled")) {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "Password Policy Configuration File Defined as ($policyString)"
                                $encounterError = "True"
                            } elseif ((($PasswdPolicyMinValue2 -lt 7) -or ($PasswdPolicyMinValue2 -gt 999)) -and ($PasswdPolicyMinValue2 -ine "disabled")) {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "Password Policy Configuration File Defined as ($policyString)"
                                $encounterError = "True"
                            } elseif ((($PasswdPolicyMinValue3 -lt 7) -or ($PasswdPolicyMinValue3 -gt 999)) -and ($PasswdPolicyMinValue3 -ine "disabled")) {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "Password Policy Configuration File Defined as ($policyString)"
                                $encounterError = "True"
                            } elseif ((($PasswdPolicyMinValue4 -lt 7) -or ($PasswdPolicyMinValue4 -gt 999)) -and ($PasswdPolicyMinValue4 -ine "disabled")) {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "Password Policy Configuration File Defined as ($policyString)"
                                $encounterError = "True"
                            } elseif ((($PasswdPolicyMinValue5 -lt 7) -or ($PasswdPolicyMinValue5 -gt 999)) -and ($PasswdPolicyMinValue5 -ine "disabled")) {
                                Write-Error "The recommended policy configuration should be retry=3 min=disabled,disabled,disabled,disbled,15"
								Write-Error "Password Policy Configuration File Defined as ($policyString)"
                                $encounterError = "True"
                            }
                        }
                        "history"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):history" -value $customConfig.($product.Name).($section.Name)."history" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minLength"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minLength" -value $customConfig.($product.Name).($section.Name)."minLength" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "maxLength"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxLength" -value $customConfig.($product.Name).($section.Name)."maxLength" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minAlphabetic"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minAlphabetic" -value $customConfig.($product.Name).($section.Name)."minAlphabetic" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minLowercase"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minLowercase" -value $customConfig.($product.Name).($section.Name)."minLowercase" -minRange -1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minUppercase"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minUppercase" -value $customConfig.($product.Name).($section.Name)."minUppercase" -minRange -1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minNumerical"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minNumerical" -value $customConfig.($product.Name).($section.Name)."minNumerical" -minRange -1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minSpecial"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minSpecial" -value $customConfig.($product.Name).($section.Name)."minSpecial" -minRange -1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "maxIdenticalAdjacent"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxIdenticalAdjacent" -value $customConfig.($product.Name).($section.Name)."maxIdenticalAdjacent" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minUnique"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minUnique" -value $customConfig.($product.Name).($section.Name)."minUnique" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "minClass"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):minClass" -value $customConfig.($product.Name).($section.Name)."minClass" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "maxSequence"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxSequence" -value $customConfig.($product.Name).($section.Name)."maxSequence" -minRange 0 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "retries"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):retries" -value $customConfig.($product.Name).($section.Name)."retries" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "maxIdenticalAdjacent"
                        {
                            if ($product.Name -eq "wsaDirectory") {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxIdenticalAdjacent" -value $customConfig.($product.Name).($section.Name)."maxIdenticalAdjacent" -minRange 0 -maxRange 99999 -required $true
                            } else {
                                $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxIdenticalAdjacent" -value $customConfig.($product.Name).($section.Name)."maxIdenticalAdjacent" -minRange 1 -maxRange 99999 -required $true
                            }
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        # Account Lockout section
                        "maxFailures"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):maxFailures" -value $customConfig.($product.Name).($section.Name)."maxFailures" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "unlockInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):unlockInterval" -value $customConfig.($product.Name).($section.Name)."unlockInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "failedAttemptInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):failedAttemptInterval" -value $customConfig.($product.Name).($section.Name)."failedAttemptInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "rootUnlockInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):rootUnlockInterval" -value $customConfig.($product.Name).($section.Name)."rootUnlockInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "apiMaxFailures"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):apiMaxFailures" -value $customConfig.($product.Name).($section.Name)."apiMaxFailures" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "apiUnlockInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):apiUnlockInterval" -value $customConfig.($product.Name).($section.Name)."apiUnlockInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "apiRestInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):apiRestInterval" -value $customConfig.($product.Name).($section.Name)."apiRestInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "cliMaxFailures"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):cliMaxFailures" -value $customConfig.($product.Name).($section.Name)."cliMaxFailures" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                        "cliUnlockInterval"
                        {
                            $checkReturn = checkRange -name "$($product.Name):$($section.Name):cliUnlockInterval" -value $customConfig.($product.Name).($section.Name)."cliUnlockInterval" -minRange 1 -maxRange 99999 -required $true
                            if (-Not $checkReturn) { $encounterError = "True" }
                        }
                    }
                }
            }
        }
    }
    # Check to see if there are any validation errors and exit if any found
    if ($encounterError -eq "True") {
        Write-Error "Validate Errors Found in the Password Policy Configuration File"
        Return $false
    } else {
        Return $true
    }
}

Function Set-CreateReportDirectory {
    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$path,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcManagerFqdn
    )

    $filetimeStamp = Get-Date -Format "MM-dd-yyyy_hh_mm_ss"
    $Global:reportFolder = $path + '\PasswordPolicyManager\'
    if ($PSEdition -eq "Core" -and ($PSVersionTable.OS).Split(' ')[0] -eq "Linux") {
        $reportFolder = ($reportFolder).split('\') -join '/' | Split-Path -NoQualifier
    }
    if (!(Test-Path -Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType "directory" | Out-Null
    }
    $reportName = $reportFolder + $filetimeStamp + "-passwordPolicyManager" + ".htm"
    $reportName
}

Function Save-ClarityReportHeader {
    Param (
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$dark
    )

    # Define the default Clarity Cascading Style Sheets (CSS) for the HTML report Header
    if ($PsBoundParameters.ContainsKey("dark")) {
        $clarityCssHeader = '
        <head>
        <style>
            <!--- Used Clarify CSS components for this project --->
            article, aside, details, figcaption, figure, footer, header, main, menu, nav, section, summary { display: block; }
            .main-container { display: flex; flex-direction: column; height: 100vh; background: var(--clr-global-app-background, #21333b); }
            header.header-6, .header.header-6 { background-color: #0e161b; }
            header, .header { display: flex; color: #fafafa; background-color: #0e161b; height: 3rem; white-space: nowrap; }
            .nav { display: flex; height: 1.8rem; list-style-type: none; align-items: center; margin: 0; width: 100%; white-space: nowrap; box-shadow: 0 -0.05rem 0 #495865 inset; }
            .nav .nav-item { display: inline-block; margin-right: 1.2rem; }
            .nav .nav-item.active > .nav-link { color: white; box-shadow: 0 -0.05rem 0 #495865 inset; }
            .nav .nav-link { color: #acbac3; font-size: 0.7rem; font-weight: 400; letter-spacing: normal; line-height: 1.8rem; display: inline-block; padding: 0 0.15rem; box-shadow: none; }
            .nav .nav-link.btn { text-transform: none; margin: 0; margin-bottom: -0.05rem; border-radius: 0; }
            .nav .nav-link:hover, .nav .nav-link:focus, .nav .nav-link:active { color: inherit; }
            .nav .nav-link:hover, .nav .nav-link.active { box-shadow: 0 -0.15rem 0 #4aaed9 inset; transition: box-shadow 0.2s ease-in; }
            .nav .nav-link:hover, .nav .nav-link:focus, .nav .nav-link:active, .nav .nav-link.active { text-decoration: none; }
            .nav .nav-link.active { color: white; font-weight: 400; }
            .nav .nav-link.nav-item { margin-right: 1.2rem; }
            .sub-nav, .subnav { display: flex; box-shadow: 0 -0.05rem 0 #cccccc inset; justify-content: space-between; align-items: center; background-color: #17242b; height: 1.8rem; }
            .sub-nav .nav, .subnav .nav { flex: 1 1 auto; padding-left: 1.2rem; }
            .sub-nav aside, .subnav aside { flex: 0 0 auto; display: flex; align-items: center; height: 1.8rem; padding: 0 1.2rem; }
            .sub-nav aside > :last-child, .subnav aside > :last-child { margin-right: 0; padding-right: 0; }
            .sidenav { line-height: 1.2rem; max-width: 15.6rem; min-width: 10.8rem; width: 18%; border-right: 0.05rem solid #152228; display: flex; flex-direction: column; }
            .sidenav .sidenav-content { flex: 1 1 auto; overflow-x: hidden; padding-bottom: 1.2rem; }
            .sidenav .sidenav-content .nav-link { border-radius: 0; border-top-left-radius: 0.15rem; border-bottom-left-radius: 0.15rem; display: inline-block; color: inherit; cursor: pointer; text-decoration: none; width: 100%; }
            .sidenav .sidenav-content > .nav-link { margin: 1.2rem 0 0 1.5rem; padding-left: 0.6rem; color: #acbac3; font-weight: 500; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 0.7rem; line-height: 1.2rem; letter-spacing: normal; }
            .sidenav .sidenav-content > .nav-link:hover { background: #324f62; }
            .sidenav .sidenav-content > .nav-link.active { background: #324f62; color: black; }
            .sidenav .nav-group { color: #acbac3; font-weight: 400; font-size: 0.7rem; letter-spacing: normal; margin-top: 1.2rem; width: 100%; }
            .sidenav .nav-group .nav-list, .sidenav .nav-group label { padding: 0 0 0 1.8rem; cursor: pointer; display: inline-block; width: 100%; margin: 0 0.3rem; }
            .sidenav .nav-group .nav-list { list-style: none; margin-top: 0; }
            .sidenav .nav-group .nav-list .nav-link { line-height: 0.8rem; padding: 0.2rem 0 0.2rem 0.6rem; }
            .sidenav .nav-group .nav-list .nav-link:hover { background: #324f62; }
            .sidenav .nav-group .nav-list .nav-link.active { background: #324f62; color: black; }
            .sidenav .nav-group label { color: #acbac3; font-weight: 500; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 0.7rem; line-height: 1.2rem; letter-spacing: normal; }
            .sidenav .nav-group input[type=checkbox] { position: absolute; clip: rect(1px, 1px, 1px, 1px); clip-path: inset(50%); padding: 0; border: 0; height: 1px; width: 1px; overflow: hidden; white-space: nowrap; top: 0; left: 0; }
            .sidenav .nav-group input[type=checkbox]:focus + label { outline: #3b99fc auto 0.25rem; }
            .sidenav .collapsible label { padding: 0 0 0 1.3rem; }
            .sidenav .collapsible label:after { content: ""; float: left; height: 0.5rem; width: 0.5rem; transform: translateX(-0.4rem) translateY(0.35rem); background-image: url("data:image/svg+xml;charset=utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%2012%2012%22%3E%0A%20%20%20%20%3Cdefs%3E%0A%20%20%20%20%20%20%20%20%3Cstyle%3E.cls-1%7Bfill%3A%239a9a9a%3B%7D%3C%2Fstyle%3E%0A%20%20%20%20%3C%2Fdefs%3E%0A%20%20%20%20%3Ctitle%3ECaret%3C%2Ftitle%3E%0A%20%20%20%20%3Cpath%20class%3D%22cls-1%22%20d%3D%22M6%2C9L1.2%2C4.2a0.68%2C0.68%2C0%2C0%2C1%2C1-1L6%2C7.08%2C9.84%2C3.24a0.68%2C0.68%2C0%2C1%2C1%2C1%2C1Z%22%2F%3E%0A%3C%2Fsvg%3E%0A"); background-repeat: no-repeat; background-size: contain; vertical-align: middle; margin: 0; }
            .sidenav .collapsible input[type=checkbox]:checked ~ .nav-list, .sidenav .collapsible input[type=checkbox]:checked ~ ul { height: 0; display: none; }
            .sidenav .collapsible input[type=checkbox] ~ .nav-list, .sidenav .collapsible input[type=checkbox] ~ ul { height: auto; }
            .sidenav .collapsible input[type=checkbox]:checked ~ label:after { transform: rotate(-90deg) translateX(-0.35rem) translateY(-0.4rem); }
            body:not([cds-text]) { color: #acbac3; font-weight: 400; font-size: 0.7rem; letter-spacing: normal; line-height: 1.2rem; margin-bottom: 0px; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; margin-top: 0px !important; }
            html:not([cds-text]) { color: #eaedf0; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 125%; }
            a:link { color: #4aaed9; text-decoration: none; }
            h1:not([cds-text]) { color: #eaedf0; font-weight: 200; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 1.6rem; letter-spacing: normal; line-height: 2.4rem; margin-top: 1.2rem; margin-bottom: 0; }
            h2:not([cds-text]) { color: #eaedf0; font-weight: 200; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 1.4rem; letter-spacing: normal; line-height: 2.4rem; margin-top: 1.2rem; margin-bottom: 0; }
            h3:not([cds-text]) { color: #eaedf0; font-weight: 200; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 1.1rem; letter-spacing: normal; line-height: 1.2rem; margin-top: 1.2rem; margin-bottom: 0; }
            h4:not([cds-text]) { color: #eaedf0; font-weight: 200; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 0.9rem; letter-spacing: normal; line-height: 1.2rem; margin-top: 1.2rem; margin-bottom: 0; }
            .table th { color: #eaedf0; font-size: 0.55rem; font-weight: 600; letter-spacing: 0.03em; background-color: #1b2a32; vertical-align: bottom; border-bottom-style: solid; border-bottom-width: 0.05rem; border-bottom-color: #495865; border-top: 0 none; }
            .table { border-collapse: separate; border-style: solid; border-width: 0.05rem; border-color: #495865; border-radius: 0.15rem; background-color: #21333b; color: #acbac3; margin: 0; margin-top: 1.2rem; max-width: 100%; width: 100%; }

            h3 { display: block; font-size: 1.17em; margin-block-start: 1em; margin-block-end: 1em; margin-inline-start: 0px; margin-inline-end: 0px; font-weight: bold; }
            h4 { display: block; margin-block-start: 1.33em; margin-block-end: 1.33em; margin-inline-start: 0px; margin-inline-end: 0px; font-weight: bold; }
            .table th, .table td {font-size: 0.65rem; line-height: 0.7rem; border-top-style: solid; border-top-width: 0.05rem; border-top-color: #495865; padding: 0.55rem 0.6rem 0.55rem; text-align: left; vertical-align: top; }
            th { display: table-cell; vertical-align: inherit; font-weight: bold; text-align: -internal-center; }
            table { display: table; border-collapse: separate; box-sizing: border-box; text-indent: initial; border-spacing: 2px; border-color: gray; }
        '
    } else {
        $clarityCssHeader = '
        <head>
		<style>
			<!--- Used Clarify CSS components for this project --->
            article, aside, details, figcaption, figure, footer, header, main, menu, nav, section, summary { display: block; }
            .main-container { display: flex; flex-direction: column; height: 100vh; background: var(--clr-global-app-background, #fafafa); }
            header.header-6, .header.header-6 { background-color: var(--clr-header-6-bg-color, #00364d); }
            header, .header { display: flex; color: var(--clr-header-font-color, #fafafa); background-color: var(--clr-header-bg-color, #333333); height: 3rem; white-space: nowrap; }
            .nav {display: flex; height: 1.8rem; list-style-type: none; align-items: center; margin: 0; width: 100%; white-space: nowrap; box-shadow: 0 -0.05rem 0 #cccccc inset; box-shadow: 0 -0.05rem 0 var(--clr-nav-box-shadow-color, #cccccc) inset; }
            .nav .nav-item { display: inline-block; margin-right: 1.2rem; }
            .nav .nav-item.active > .nav-link { color: black; color: var(--clr-nav-link-active-color, black); box-shadow: 0 -0.05rem 0 #cccccc inset; box-shadow: 0 -0.05rem 0 var(--clr-nav-box-shadow-color, #cccccc) inset; }
            .nav .nav-link { color: #666666; color: var(--clr-nav-link-color, #666666); font-size: 0.7rem; font-weight: 400; font-weight: var(--clr-nav-link-font-weight, 400); letter-spacing: normal; line-height: 1.8rem; display: inline-block; padding: 0 0.15rem; box-shadow: none; }
            .nav .nav-link.btn { text-transform: none; margin: 0; margin-bottom: -0.05rem; border-radius: 0; }
            .nav .nav-link:hover, .nav .nav-link:focus, .nav .nav-link:active { color: inherit; }
            .nav .nav-link:hover, .nav .nav-link.active { box-shadow: 0 -0.15rem 0 #0072a3 inset; box-shadow: 0 -0.15rem 0 var(--clr-nav-active-box-shadow-color, #0072a3) inset; transition: box-shadow 0.2s ease-in; }
            .nav .nav-link:hover, .nav .nav-link:focus, .nav .nav-link:active, .nav .nav-link.active { text-decoration: none; }
            .nav .nav-link.active { color: black; color: var(--clr-nav-link-active-color, black); font-weight: 400; font-weight: var(--clr-nav-link-active-font-weight, 400); }
            .nav .nav-link.nav-item { margin-right: 1.2rem; }
            .sub-nav, .subnav { display: flex; box-shadow: 0 -0.05rem 0 #cccccc inset; box-shadow: 0 -0.05rem 0 var(--clr-nav-box-shadow-color, #cccccc) inset; justify-content: space-between; align-items: center; background-color: white; background-color: var(--clr-subnav-bg-color, white); height: 1.8rem; }
            .sub-nav .nav, .subnav .nav { flex: 1 1 auto; padding-left: 1.2rem; }
            .sub-nav aside, .subnav aside { flex: 0 0 auto; display: flex; align-items: center; height: 1.8rem; padding: 0 1.2rem; }
            .sub-nav aside > :last-child, .subnav aside > :last-child { margin-right: 0; padding-right: 0; }
            .sidenav { line-height: 1.2rem; max-width: 15.6rem; min-width: 10.8rem; width: 18%; border-right: 0.05rem solid #cccccc; display: flex; flex-direction: column; }
            .sidenav .collapsible label padding: 0 0 0 1.3rem; }
            .sidenav .nav-group label {color: #333333; color: var(--clr-sidenav-header-color, #333333); font-weight: 500; font-weight: var(--clr-sidenav-header-font-weight, 500); font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-family: var(--clr-sidenav-header-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 0.7rem; line-height: 1.2rem; letter-spacing: normal; }
            .sidenav { line-height: 1.2rem; max-width: 15.6rem; min-width: 10.8rem; width: 18%; border-right: 0.05rem solid #cccccc; display: flex; flex-direction: column; }
            .sidenav .sidenav-content { flex: 1 1 auto; overflow-x: hidden; padding-bottom: 1.2rem; }
            .sidenav .sidenav-content .nav-link { border-radius: 0; border-top-left-radius: 0.15rem; border-top-left-radius: var(--clr-sidenav-link-active-border-radius, 0.15rem); border-bottom-left-radius: 0.15rem; border-bottom-left-radius: var(--clr-sidenav-link-active-border-radius, 0.15rem); display: inline-block; color: inherit; cursor: pointer; text-decoration: none; width: 100%; }
            .sidenav .sidenav-content > .nav-link { margin: 1.2rem 0 0 1.5rem; padding-left: 0.6rem; color: #333333; color: var(--clr-sidenav-header-color, #333333); font-weight: 500; font-weight: var(--clr-sidenav-header-font-weight, 500); font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-family: var(--clr-sidenav-header-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif);font-size: 0.7rem; line-height: 1.2rem; letter-spacing: normal; }
            .sidenav .sidenav-content > .nav-link:hover { background: #e8e8e8; background: var(--clr-sidenav-link-hover-color, #e8e8e8); }
            .sidenav .sidenav-content > .nav-link.active { background: #d8e3e9; background: var(--clr-sidenav-link-active-bg-color, #d8e3e9); color: black; color: var(--clr-sidenav-link-active-color, black); }
            .sidenav .nav-group { color: #666666; color: var(--clr-sidenav-color, #666666); font-weight: 400; font-weight: var(--clr-sidenav-font-weight, 400); font-size: 0.7rem; letter-spacing: normal; margin-top: 1.2rem; width: 100%; }
            .sidenav .nav-group .nav-list, .sidenav .nav-group label { padding: 0 0 0 1.8rem; cursor: pointer; display: inline-block; width: 100%; margin: 0 0.3rem; }
            .sidenav .nav-group .nav-list { list-style: none; margin-top: 0; }
            .sidenav .nav-group .nav-list .nav-link { line-height: 0.8rem; padding: 0.2rem 0 0.2rem 0.6rem; }
            .sidenav .nav-group .nav-list .nav-link:hover { background: #e8e8e8; background: var(--clr-sidenav-link-hover-color, #e8e8e8); }
            .sidenav .nav-group .nav-list .nav-link.active { background: #d8e3e9; background: var(--clr-sidenav-link-active-bg-color, #d8e3e9); color: black; color: var(--clr-sidenav-link-active-color, black); }
            .sidenav .nav-group label { color: #333333; color: var(--clr-sidenav-header-color, #333333); font-weight: 500; font-weight: var(--clr-sidenav-header-font-weight, 500); font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-family: var(--clr-sidenav-header-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 0.7rem; line-height: 1.2rem; letter-spacing: normal; }
            .sidenav .nav-group input[type=checkbox] { position: absolute; clip: rect(1px, 1px, 1px, 1px); clip-path: inset(50%); padding: 0; border: 0; height: 1px; width: 1px; overflow: hidden; white-space: nowrap; top: 0; left: 0; }
            .sidenav .nav-group input[type=checkbox]:focus + label { outline: #3b99fc auto 0.25rem; }
            .sidenav .collapsible label { padding: 0 0 0 1.3rem; }
            .sidenav .collapsible label:after { content: ""; float: left; height: 0.5rem; width: 0.5rem; transform: translateX(-0.4rem) translateY(0.35rem); background-image: url("data:image/svg+xml;charset=utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%2012%2012%22%3E%0A%20%20%20%20%3Cdefs%3E%0A%20%20%20%20%20%20%20%20%3Cstyle%3E.cls-1%7Bfill%3A%239a9a9a%3B%7D%3C%2Fstyle%3E%0A%20%20%20%20%3C%2Fdefs%3E%0A%20%20%20%20%3Ctitle%3ECaret%3C%2Ftitle%3E%0A%20%20%20%20%3Cpath%20class%3D%22cls-1%22%20d%3D%22M6%2C9L1.2%2C4.2a0.68%2C0.68%2C0%2C0%2C1%2C1-1L6%2C7.08%2C9.84%2C3.24a0.68%2C0.68%2C0%2C1%2C1%2C1%2C1Z%22%2F%3E%0A%3C%2Fsvg%3E%0A"); background-repeat: no-repeat; background-size: contain; vertical-align: middle; margin: 0; }
            .sidenav .collapsible input[type=checkbox]:checked ~ .nav-list, .sidenav .collapsible input[type=checkbox]:checked ~ ul { height: 0; display: none; }
            .sidenav .collapsible input[type=checkbox] ~ .nav-list, .sidenav .collapsible input[type=checkbox] ~ ul { height: auto; }
            .sidenav .collapsible input[type=checkbox]:checked ~ label:after { transform: rotate(-90deg) translateX(-0.35rem) translateY(-0.4rem); }
            body:not([cds-text]) { color: var(--clr-p1-color, #666666); font-weight: var(--clr-p1-font-weight, 400); font-size: 0.7rem; letter-spacing: normal; line-height: 1.2rem; margin-bottom: 0px; font-family: var(--clr-font, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); margin-top: 0px !important; }
            html:not([cds-text]) { color: var(--clr-global-font-color, #666666); font-family: var(--clr-font, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 125%; }
            a:link { color: var(--clr-link-color, #0072a3); text-decoration: none; }
            h1:not([cds-text]) { color: var(--clr-h1-color, black); font-weight: var(--clr-h1-font-weight, 200); font-family: var(--clr-h1-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 1.6rem; letter-spacing: normal; line-height: 2.4rem; margin-top: 1.2rem; margin-bottom: 0px; }
			h2:not([cds-text]) { color: var(--clr-h2-color, black); font-weight: var(--clr-h2-font-weight, 200); font-family: var(--clr-h2-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 1.4rem; letter-spacing: normal; line-height: 2.4rem; margin-top: 1.2rem; margin-bottom: 0px; }
			h3:not([cds-text]) { color: var(--clr-h3-color, black); font-weight: var(--clr-h3-font-weight, 200); font-family: var(--clr-h3-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 1.1rem; letter-spacing: normal; line-height: 1.2rem; margin-top: 1.2rem; margin-bottom: 0px; }
			h4:not([cds-text]) { color: var(--clr-h4-color, black); font-weight: var(--clr-h4-font-weight, 200); font-family: var(--clr-h4-font-family, ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif); font-size: 0.9rem; letter-spacing: normal; line-height: 1.2rem; margin-top: 1.2rem; margin-bottom: 0px; }
            .table th { color: var(--clr-thead-color, #666666); font-size: 0.55rem; font-weight: 600; letter-spacing: 0.03em; background-color: var(--clr-thead-bgcolor, #fafafa); vertical-align: bottom; border-bottom-style: solid; border-bottom-width: var(--clr-table-borderwidth, 0.05rem); border-bottom-color: var(--clr-table-border-color, #cccccc); border-top: 0px none; }
            .table { border-collapse: separate; border-style: solid; border-width: var(--clr-table-borderwidth, 0.05rem); border-color: var(--clr-table-border-color, #cccccc); border-radius: var(--clr-table-border-radius, 0.15rem); background-color: var(--clr-table-bgcolor, white); color: var(--clr-table-font-color, #666666); margin: 1.2rem 0px 0px; max-width: 100%; width: 100%; }

			a { background-color: transparent; }
			abbr[title] { border-bottom: none; text-decoration: underline dotted; }
			b, strong { font-weight: inherit; }
			b, strong { font-weight: bolder; }
			[type="checkbox"], [type="radio"] { box-sizing: border-box; padding: 0px; }
			pre { border-color: var(--clr-color-neutral-400, #cccccc); border-width: var(--clr-global-borderwidth, 0.05rem); border-style: solid; border-radius: var(--clr-global-borderradius, 0.15rem); }
			ul:not([cds-list]), ol:not([cds-list]) { list-style-position: inside; margin-left: 0px; margin-top: 0px; margin-bottom: 0px; padding-left: 0px; }
			li > ul:not([cds-list]) { margin-top: 0px; margin-left: 1.1em; }
			body p:not([cds-text]) { color: var(--clr-p1-color, #666666); font-weight: var(--clr-p1-font-weight, 400); font-size: 0.7rem; letter-spacing: normal; line-height: 1.2rem; margin-top: 1.2rem; margin-bottom: 0px; }
			a:visited { color: var(--clr-link-visited-color, #5659b8); text-decoration: none; }
			.main-container .content-container .content-area > :first-child { margin-top: 0px; }
			.nav .nav-link:hover, .nav .nav-link.active { box-shadow: 0 -0.15rem 0 var(--clr-nav-active-box-shadow-color, #0072a3) inset; transition: box-shadow 0.2s ease-in 0s; }
			.nav .nav-link.active { color: var(--clr-nav-link-active-color, black); font-weight: var(--clr-nav-link-active-font-weight, 400); }
			:root { --clr-subnav-bg-color:var(--clr-color-neutral-0); --clr-nav-box-shadow-color:var(--clr-color-neutral-400); }
			:root { --clr-sidenav-border-color:var(--clr-color-neutral-400); --clr-sidenav-border-width:var(--clr-global-borderwidth); --clr-sidenav-link-hover-color:var(--clr-color-neutral-200); --clr-sidenav-link-active-color:var(--clr-color-neutral-1000); --clr-sidenav-link-active-bg-color:var(--clr-global-selection-color); --clr-sidenav-link-active-border-radius:var(--clr-global-borderradius); --clr-sidenav-header-color:var(--clr-h6-color); --clr-sidenav-header-font-weight:var(--clr-h6-font-weight); --clr-sidenav-header-font-family:var(--clr-h6-font-family); --clr-sidenav-color:var(--clr-p1-color); --clr-sidenav-font-weight:var(--clr-p1-font-weight); }
			.table th, .table td { font-size: 0.65rem; line-height: 0.7rem; border-top-style: solid; border-top-width: var(--clr-table-borderwidth, 0.05rem); border-top-color: var(--clr-tablerow-bordercolor, #e8e8e8); padding: 0.55rem 0.6rem; text-align: left; vertical-align: top; }
        '
    }
    $clarityCssShared = '
            .alertOK { color: #61B715; font-weight: bold }
            .alertWarning { color: #FDD008; font-weight: bold }
            .alertCritical { color: #F55047; font-weight: bold }
            .table th, .table td { text-align: left; }

            :root { --cds-global-base: 20; }
            body { margin: 0px; }
            .main-container .content-container .sidenav { flex: 0 0 auto; order: -1; overflow: hidden; }
            .main-container .content-container .content-area > :first-child { margin-top: 0; }
            .main-container .content-container .content-area { flex: 1 1 auto; overflow-y: auto; -webkit-overflow-scrolling: touch; padding: 1.2rem 1.2rem 1.2rem 1.2rem; }
            .main-container header, .main-container .header { flex: 0 0 3rem; }
            .main-container .header .branding { max-width: auto; min-width: 0px; overflow: hidden; }
            .main-container .sub-nav, .main-container .subnav { flex: 0 0 1.8rem; }
            .main-container .content-container { display: flex; flex: 1 1 auto; min-height: 0.05rem; }
            header .branding, .header .branding { display: flex; flex: 0 0 auto; min-width: 10.2rem; padding: 0px 1.2rem; height: 3rem; }
            header .branding .title, .header .branding .title { color: #fafafa; font-weight: 400; font-family: ClarityCityRegular, "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 0.8rem; letter-spacing: 0.01em; line-height: 3rem; text-decoration: none; }
            header .branding > a, header .branding > .nav-link, .header .branding > a, .header .branding > .nav-link { display: inline-flex; align-items: center; height: 3rem; }
            header .branding .clr-icon, header .branding cds-icon, header .branding clr-icon, .header .branding .clr-icon, .header .branding cds-icon, .header .branding clr-icon { flex-grow: 0; flex-shrink: 0; height: 1.8rem; width: 1.8rem; margin-right: 0.45rem; }

            ul:not([cds-list]), ol:not([cds-list]) { list-style-position: inside; margin-left: 0; margin-top: 0; margin-bottom: 0; padding-left: 0; }
            a { background-color: transparent; -webkit-text-decoration-skip: objects; }
            h1 { font-size: 2em; margin: 0.67em 0px; }
            img { border-style: none; }
            img { vertical-align: middle; }
            *, ::before, ::after { box-sizing: border-box; }
            *, ::before, ::after { box-sizing: inherit; }
            table { border-spacing: 0px; }
            pre { margin: 0.6rem 0px; }
            html { box-sizing: border-box; }
			html { -webkit-tap-highlight-color: transparent; }
            html { -ms-overflow-style: scrollbar; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); }
            html { font-family: sans-serif; line-height: 1.15; -ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%; }
            .table tbody tr:first-child td { border-top: 0px none; }
			.table thead th:first-child { border-top-right-radius: 0px; border-bottom-right-radius: 0px; border-bottom-left-radius: 0px; border-top-left-radius: var(--clr-table-cornercellradius, 0.1rem); }
			.table thead th:last-child { border-top-left-radius: 0px; border-bottom-right-radius: 0px; border-bottom-left-radius: 0px; border-top-right-radius: var(--clr-table-cornercellradius, 0.1rem); }
			.table tbody:last-child tr:last-child td:first-child { border-top-left-radius: 0px; border-top-right-radius: 0px; border-bottom-right-radius: 0px; border-bottom-left-radius: var(--clr-table-cornercellradius, 0.1rem); }
			.table tbody:last-child tr:last-child td:last-child { border-top-left-radius: 0px; border-top-right-radius: 0px; border-bottom-left-radius: 0px; border-bottom-right-radius: var(--clr-table-cornercellradius, 0.1rem); }

            @font-face {font-family: ClarityCityRegular;src: url(data:font/ttf;base64,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AvQAWwLlABkEKwAeBCsAHgQrAB4EKwAeBCsAHgKlABwCoQATAqEAEwKhABMCoQATAqEAEwJlACwCZQAsAmUALAJlACwCLQAkAi0AJAItACQCLQAkAi0AJAItACQCLQAkAi0AJAItACQCLQAkA7IAJAJ7AFcCBwApAgcAKQIHACkCBwApAnsALwJZACsCpQAvAnsALwJHACwCRwAsAkcALAJHACwCRwAsAkcALAJYACwCRwAsAkcALAJYACwCRwAsAT0AGAJ2ACoCdgAqAnYAKgJZAFcA+QBLAPkAVwD5AFcA+f/2APn/7wD5/9IA+f/iAPkAMADv/84A7//OAiUAVwIlAFcA+QBXAPkAVwEWAFcBJwAcA4kAVwJZAFcCWQBXAlkAVwJZAFcCWQBXAmkAKgJpACoCaQAqAmkAKgJpACoCaQAqAmkAKgKBADMCaQAqBCAAKgJ7AFcCfABYAnsALwGMAFcBjABXAYwAVgGMAFcB3gAhAd4AIQHeACEB3gAhAkMAVwFZABUBuQAVAVkAFQJZAEsCWQBLAlkASwJZAEsCWQBLAlkASwJZAEsCWQBLAlkASwIRAAoDHQAQAx0AEAMdABADHQAQAx0AEAH/AAwCGAAJAhgACQIYAAkCGAAJAhgACQHbACEB2wAhAdsAIQHbACECewAvAnsALwJ7AC8CewAvAnsALwJ7AC8CewAvAnsALwJ7AC8CewAvArMAPAFlABQCNQAiAkYAHgJMABsCUQA3AmgAPwIDABYCbQA7AmgAMgFEAGwBOgBlATMAYwE1AGMC1ABsAT0AaAE9AGkCCQAiAgkAMwFBAG0BrgBfAc8AVgKxAC8BtAAAAbQAAAFIADUBSAAaAWIAFgFiABsBcgBpAXIAHQGvAFYCfQBWA64AVgMAAFYB4ABUAeAAUAHgAFQBGABQARgAVAIBACICAAAsATsAIgE6ACwBygBdARYAXQPoAAAB9AAAAPoAAAETAAAApgAAAU0AAAJcAFECkgBGAzkAUAKcAFUC8QA6Ak8AQgLPAIICFgBOAlMARALRAIMCUQBPAlEAOwIbAG0B/AA/A0YAPwS6AD8DqABJAsIAPwKYAD0DrQBKApUAVANBAFMBQgCDAAD/UgAA/10BBwAeAZEANQFbACYBJQAwAVsAJgGxAEsA8QBLAQMAHQHOAB0B4gBWASYAQwFNAD8BxABC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)
        </style>
        </head>
            <body>
                <div class="main-container">
                    <header class="header header-6">
                        <div class="branding">
                            <a href="">
                                <cds-icon shape="vm-bug">
                                    <img height="36px" width="36px" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDI2LjIuMSwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCAzNiAzNiIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgMzYgMzY7IiB4bWw6c3BhY2U9InByZXNlcnZlIj4KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4KCS5zdDB7ZmlsbDojMDA5MURBO30KCS5zdDF7ZmlsbDojMUQ0MjhBO30KCS5zdDJ7ZmlsbDojMDBDMUQ1O30KPC9zdHlsZT4KPHBhdGggY2xhc3M9InN0MCIgZD0iTTI4LjIsMzAuNGMtMC4zLDAtMC41LTAuMi0wLjYtMC40Yy0wLjItMC40LDAtMC44LDAuMy0wLjljMy45LTEuOCw2LjQtNS43LDYuNC05LjljMC0yLjMtMC43LTQuNC0yLTYuMwoJYy0xLjMtMS44LTMtMy4yLTUuMS00Yy0wLjQtMC4xLTAuNi0wLjYtMC40LTAuOWMwLjEtMC40LDAuNi0wLjYsMC45LTAuNGMyLjMsMC45LDQuMywyLjQsNS44LDQuNWMxLjUsMi4xLDIuMyw0LjUsMi4zLDcuMQoJYzAsNC44LTIuOCw5LjItNy4yLDExLjJDMjguNCwzMC40LDI4LjMsMzAuNCwyOC4yLDMwLjR6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik0yMy4yLDExLjNjLTAuMSwwLTAuMiwwLTAuMywwYy0wLjUtMS44LTEuNi0zLjMtMy4xLTQuNWMtMS43LTEuMy0zLjctMi01LjgtMmMtNS4xLDAtOS4zLDQuMS05LjMsOS4yCgljMCwwLDAsMC4xLDAsMC4xYy0zLjUsMS4xLTUuNCw0LjktNC4zLDguNGMwLjYsMS44LDEuOSwzLjMsMy43LDQuMXYtMS42Yy0yLjUtMS41LTMuNC00LjctMS45LTcuMmMwLjctMS4zLDItMi4yLDMuNC0yLjVsMC42LTAuMQoJbDAtMC42YzAtMC4yLDAtMC40LDAtMC42YzAtNC4zLDMuNS03LjcsNy44LTcuN2MzLjYsMCw2LjgsMi41LDcuNiw2bDAuMSwwLjZsMC42LTAuMWMwLjIsMCwwLjUsMCwwLjcsMGMzLjYsMCw2LjUsMi45LDYuNSw2LjUKCWMwLDEuOS0wLjgsMy43LTIuMiw0Ljl2MS44YzIuMy0xLjQsMy43LTMuOSwzLjctNi42QzMxLjEsMTQuOCwyNy41LDExLjMsMjMuMiwxMS4zeiIvPgo8cGF0aCBjbGFzcz0ic3QyIiBkPSJNMS4yLDEyLjJjMCwwLTAuMSwwLTAuMSwwYy0wLjQtMC4xLTAuNi0wLjQtMC42LTAuOEMxLjcsNC45LDcuNCwwLjIsMTQsMC4yYzMuMSwwLDYuMiwxLjEsOC42LDMKCWMwLjksMC43LDEuNiwxLjUsMi4zLDIuM2MwLjIsMC4zLDAuMiwwLjgtMC4xLDFjLTAuMywwLjItMC44LDAuMi0xLTAuMWMtMC42LTAuOC0xLjMtMS41LTItMi4xYy0yLjItMS44LTUtMi43LTcuOC0yLjcKCWMtNiwwLTExLjEsNC4yLTEyLjIsMTBDMS44LDEyLDEuNSwxMi4yLDEuMiwxMi4yeiBNMTguMywxOGMtMC40LDAtMC43LDAuMy0wLjgsMC43YzAsMC40LDAuMywwLjcsMC43LDAuOGMwLDAsMCwwLDAuMSwwaDMuOQoJbC04LjUsOC4xYy0wLjMsMC4zLTAuMywwLjcsMCwxYzAuMywwLjMsMC43LDAuMywxLDBsOC41LTh2My45YzAsMC40LDAuNCwwLjcsMC44LDAuN2MwLjQsMCwwLjctMC4zLDAuNy0wLjdWMThMMTguMywxOEwxOC4zLDE4egoJIE0xNC43LDIzLjFWMThIOS42Yy0wLjQsMC0wLjcsMC40LTAuNywwLjhjMCwwLjQsMC4zLDAuNywwLjcsMC43aDIuNkw3LDI0LjJjLTAuMywwLjMtMC4zLDAuNywwLDFjMC4zLDAuMywwLjcsMC4zLDEsMGw1LjItNC44djIuNwoJYzAsMC40LDAuNCwwLjcsMC44LDAuN0MxNC40LDIzLjgsMTQuNywyMy41LDE0LjcsMjMuMUwxNC43LDIzLjF6IE0xOC44LDI4LjZjMCwwLjQsMC4zLDAuNywwLjcsMC43aDIuN2wtNC43LDUuMQoJYy0wLjMsMC4zLTAuMywwLjcsMCwxYzAuMywwLjMsMC43LDAuMywxLDBjMCwwLDAsMCwwLjEtMC4xbDQuNi01VjMzYzAsMC40LDAuMywwLjcsMC43LDAuOGMwLjQsMCwwLjctMC4zLDAuOC0wLjdjMCwwLDAsMCwwLTAuMQoJdi01LjFoLTUuMUMxOS4xLDI3LjksMTguOCwyOC4yLDE4LjgsMjguNkwxOC44LDI4LjZ6Ii8+Cjwvc3ZnPgo=" alt="VMware Cloud Foundation"/>
                                </cds-icon>
                                <span class="title">VMware Cloud Foundation</span>
                            </a>
                        </div>
                    </header>
    '
    $clarityCssHeader += $clarityCssShared
    $clarityCssHeader
}

Function Save-ClarityReportNavigation {
    $clarityCssNavigation = '
            <nav class="subnav">
            <ul class="nav">
            <li class="nav-item">
                <a class="nav-link active" href="">Password Policy Manager</a>
            </li>
            </ul>
        </nav>
        <div class="content-container">
        <nav class="sidenav">
        <section class="sidenav-content">
            <section class="nav-group collapsible">
                <input id="expiration" type="checkbox"/>
                <label for="expiration">Password Expiration</label>
                <ul class="nav-list">
                    <li><a class="nav-link" href="#sddcmanager-password-expiration">SDDC Manager</a></li>
                    <li><a class="nav-link" href="#sso-password-expiration">vCenter Single Sign-On</a></li>
                    <li><a class="nav-link" href="#vcenter-password-expiration">vCenter Server</a></li>
                    <li><a class="nav-link" href="#vcenter-password-expiration-local">vCenter Server (Local)</a></li>
                    <li><a class="nav-link" href="#nsxmanager-password-expiration">NSX Manager</a></li>
                    <li><a class="nav-link" href="#nsxedge-password-expiration">NSX  Edge</a></li>
                    <li><a class="nav-link" href="#esxi-password-expiration">ESXi</a></li>
                    <li><a class="nav-link" href="#wsa-directory-password-expiration">Workspace ONE (Directory)</a></li>
                    <li><a class="nav-link" href="#wsa-local-password-expiration">Workspace ONE (Local)</a></li>
                </ul>
            </section>
            <section class="nav-group collapsible">
                <input id="complexity" type="checkbox"/>
                <label for="complexity">Password Complexity</label>
                <ul class="nav-list">
                    <li><a class="nav-link" href="#sddcmanager-password-complexity">SDDC Manager</a></li>
                    <li><a class="nav-link" href="#sso-password-complexity">vCenter Single Sign-On</a></li>
                    <li><a class="nav-link" href="#vcenter-password-complexity-local">vCenter Server (Local)</a></li>
                    <li><a class="nav-link" href="#nsxmanager-password-complexity">NSX Manager</a></li>
                    <li><a class="nav-link" href="#nsxedge-password-complexity">NSX Edge</a></li>
                    <li><a class="nav-link" href="#esxi-password-complexity">ESXi</a></li>
                    <li><a class="nav-link" href="#wsa-directory-password-complexity">Workspace ONE (Directory)</a></li>
                    <li><a class="nav-link" href="#wsa-local-password-complexity">Workspace ONE (Local)</a></li>
                </ul>
            </section>
            <section class="nav-group collapsible">
                <input id="lockout" type="checkbox"/>
                <label for="lockout">Account Lockout</label>
                <ul class="nav-list">
                    <li><a class="nav-link" href="#sddcmanager-account-lockout">SDDC Manager</a></li>
                    <li><a class="nav-link" href="#sso-account-lockout">vCenter Single Sign-On</a></li>
                    <li><a class="nav-link" href="#vcenter-account-lockout-local">vCenter Server (Local)</a></li>
                    <li><a class="nav-link" href="#nsxmanager-account-lockout">NSX Manager</a></li>
                    <li><a class="nav-link" href="#nsxedge-account-lockout">NSX Edge</a></li>
                    <li><a class="nav-link" href="#esxi-account-lockout">ESXi</a></li>
                    <li><a class="nav-link" href="#wsa-directory-account-lockout">Workspace ONE (Directory)</a></li>
                    <li><a class="nav-link" href="#wsa-local-account-lockout">Workspace ONE (Local)</a></li>
                </ul>
            </section>
        </section>
        </nav>
            <div class="content-area">
                <div class="content-area">'
    $clarityCssNavigation
}

Function Save-ClarityReportFooter {
    # Define the default Clarity Cascading Style Sheets (CSS) for the HTML report Footer
    $clarityCssFooter = '
                </div>
            </div>
        </div>
    </body>
    </html>'
    $clarityCssFooter
}

Function Convert-CssClassStyle {
    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [PSCustomObject]$htmlData
    )

    # Function to replace CSS Style
    $oldTable = '<table>'
    $newTable = '<table class="table">'
    $oldAddLine = ':-: '
    $newNewLine = '<br/>'

    $htmlData = $htmlData -replace $oldTable,$newTable
    $htmlData = $htmlData -replace $oldAddLine,$newNewLine
    $htmlData
}

#EndRegion  End Password Policy Manager Functions                   ######
##########################################################################

##########################################################################
#Region     Begin SDDC Manager Password Management Function         ######

Function Request-SddcManagerPasswordComplexity {
    <#
		.SYNOPSIS
		Retrieve the password complexity policy for SDDC Manager

        .DESCRIPTION
        The Request-SddcManagerPasswordComplexity cmdlet retrieves the password complexity policy for SDDC Manager.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
		- Retrieves the password complexity policy

        .EXAMPLE
        Request-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1!
        This example retrieves the password complexity policy for SDDC Manager

        .EXAMPLE
        Request-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for SDDC Manager and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Request-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -drift
        This example retrieves the password complexity policy for SDDC Manager and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER rootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the password policy file to compare against.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$rootPass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            if ($drift) {
                                $version = ""
                                if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                                    $version = $Matches[0]
                                } 
                                if ($PsBoundParameters.ContainsKey('policyFile')) {
                                    Get-LocalPasswordComplexity -version $version -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager -drift -reportPath $reportPath -policyFile $policyFile
                                } else {
                                    Get-LocalPasswordComplexity -version $version -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager -drift
                                }
                            } else {
                                Get-LocalPasswordComplexity -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false -WarningAction SilentlyContinue
        }
    }
}
Export-ModuleMember -Function Request-SddcManagerPasswordComplexity

Function Request-SddcManagerAccountLockout {
    <#
		.SYNOPSIS
		Retrieve the account lockout policy for SDDC Manager

        .DESCRIPTION
        The Request-SddcManagerAccountLockout cmdlet retrieves the account lockout policy for SDDC Manager.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrieves the account lockout policy of SDDC Manager

        .EXAMPLE
        Request-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1!
        This example retrieves the account lockout policy for SDDC Manager

        .EXAMPLE
        Request-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the account lockout policy for SDDC Manager and and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Request-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -drift
        This example retrieves the account lockout policy for SDDC Manager and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER rootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the password policy file to compare against.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$rootPass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            if ($drift) {
                                $version = ""
                                if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                                    $version = $Matches[0]
                                } 
                                if ($PsBoundParameters.ContainsKey('policyFile')) {
                                    Get-LocalAccountLockout -version $version -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager -drift -reportPath $reportPath -policyFile $policyFile
                                } else {
                                    Get-LocalAccountLockout -version $version -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager -drift
                                }
                            } else {
                                Get-LocalAccountLockout -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-SddcManagerAccountLockout

Function Update-SddcManagerPasswordComplexity {
    <#
		.SYNOPSIS
		Update the password complexity policy for SDDC Manager

        .DESCRIPTION
        The Update-SddcManagerPasswordComplexity cmdlet configures the password complexity policy for SDDC Manager.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
		- Configures the password complexity policy

        .EXAMPLE
        Update-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -minLength 6 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -minClass 4 -maxSequence 0 -history 5 -maxRetry 3
        This example configures the password complexity policy for SDDC Manager

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER rootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER minLength
        The minimum length of the password.

        .PARAMETER minLowercase
        The minimum number of lowercase characters in the password.

        .PARAMETER minUppercase
        The minimum number of uppercase characters in the password.

        .PARAMETER minNumerical
        The minimum number of numerical characters in the password.

        .PARAMETER minSpecial
        The minimum number of special characters in the password.

        .PARAMETER minUnique
        The minimum number of unique characters in the password.

        .PARAMETER minClass
        The minimum number of character classes in the password.

        .PARAMETER maxSequence
        The maximum number of sequential characters in the password.

        .PARAMETER history
        The number of previous passwords that a password cannot match.

        .PARAMETER maxRetry
        The number of failed login attempts before the account is locked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$rootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minNumerical,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUnique,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minClass,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxSequence,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$history,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxRetry
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            $existingConfiguration = Get-LocalPasswordComplexity -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass
                            $chkExistingConfig = $existingConfiguration.'Min Length' -ne $minLength -or $existingConfiguration.'Min Lowercase' -ne $minLowercase -or $existingConfiguration.'Min Uppercase' -ne $minUppercase -or $existingConfiguration.'Min Numerical' -ne $minNumerical -or $existingConfiguration.'Min Special' -ne $minSpecial -or $existingConfiguration.'Min Unique' -ne $minUnique -or  $existingConfiguration.'History' -ne $history -or $existingConfiguration.'Max Retries' -ne $maxRetry
                            if($existingConfiguration.'Max Sequence') {
                                $chkExistingConfig = $chkExistingConfig -or $existingConfiguration.'Max Sequence' -ne $maxSequence
                            }
                            if($existingConfiguration.'Min Classes') {
                                $chkExistingConfig = $chkExistingConfig -or $existingConfiguration.'Min Classes' -ne $minClass
                            }
                            if ($chkExistingConfig) {
                                Set-LocalPasswordComplexity -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -minLength $minLength -uppercase $minUppercase -lowercase $minLowercase -numerical $minNumerical -special $minSpecial -unique $minUnique -class $minClass -sequence $maxSequence -history $history -retry $maxRetry | Out-Null
                                $updatedConfiguration = Get-LocalPasswordComplexity -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass
                                $chkUpdatedConfig = $updatedConfiguration.'Min Length' -eq $minLength -and $updatedConfiguration.'Min Lowercase' -eq $minLowercase -and $updatedConfiguration.'Min Uppercase' -eq $minUppercase -and $updatedConfiguration.'Min Numerical' -eq $minNumerical -and $updatedConfiguration.'Min Special' -eq $minSpecial -and $updatedConfiguration.'Min Unique' -eq $minUnique  -and $updatedConfiguration.'History' -eq $history -and $updatedConfiguration.'Max Retries' -eq $maxRetry
                                if($updatedConfiguration.'Max Sequence') {
                                    $chkUpdatedConfig = $chkUpdatedConfig -and $updatedConfiguration.'Max Sequence' -eq $maxSequence
                                }
                                if($updatedConfiguration.'Min Classes') {
                                    $chkUpdatedConfig = $chkUpdatedConfig -and $updatedConfiguration.'Min Classes' -eq $minClass
                                }
                                if ($chkUpdatedConfig) {
                                    Write-Output "Update Password Complexity Policy on SDDC Manasger ($server): SUCCESSFUL"
                                } else {
                                    Write-Error "Update Password Complexity Policy on SDDC Manager ($server): POST_VALIDATION_FAILED"
                                }
                            } else {
                                Write-Warning "Update Password Complexity Policy on SDDC Manager ($server), already set: SKIPPED"
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-SddcManagerPasswordComplexity

Function Update-SddcManagerAccountLockout {
    <#
		.SYNOPSIS
		Update the account lockout policy of SDDC Manager

        .DESCRIPTION
        The Update-SddcManagerAccountLockout cmdlet configures the account lockout policy of SDDC Manager. The cmdlet
        connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the account lockout policy

        .EXAMPLE
        Update-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -rootPass VMw@re1! -failures 3 -unlockInterval 86400 -rootUnlockInterval 300
        This example configures the account lockout policy for SDDC Manager

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER rootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER unlockInterval
        The number of seconds before a locked account is unlocked.

        .PARAMETER rootUnlockInterval
        The number of seconds before a locked root account is unlocked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$rootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$rootUnlockInterval
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            $existingConfiguration = Get-LocalAccountLockout -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager
                            if ($existingConfiguration.'Max Failures' -ne $failures -or $existingConfiguration.'Unlock Interval (sec)' -ne $unlockInterval -or $existingConfiguration.'Root Unlock Interval (sec)' -ne $rootUnlockInterval) {
                                Set-LocalAccountLockout -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -failures $failures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval | Out-Null
                                $updatedConfiguration = Get-LocalAccountLockout -vmName ($server.Split("."))[-0] -guestUser root -guestPassword $rootPass -product sddcManager
                                if ($updatedConfiguration.'Max Failures' -eq $failures -and $updatedConfiguration.'Unlock Interval (sec)' -eq $unlockInterval -and $updatedConfiguration.'Root Unlock Interval (sec)' -eq $rootUnlockInterval) {
                                    Write-Output "Update Account Lockout Policy on SDDC Manager ($server): SUCCESSFUL"
                                } else {
                                    Write-Error "Update Account Lockout Policy on SDDC Manager ($server): POST_VALIDATION_FAILED"
                                }
                            } else {
                                Write-Warning "Update Account Lockout Policy on SDDC Manager ($server), already set: SKIPPED"
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-SddcManagerAccountLockout

Function Publish-SddcManagerPasswordExpiration {
    <#
        .SYNOPSIS
        Publish password expiration policy for SDDC Manager.

        .DESCRIPTION
        The Publish-SddcManagerPasswordExpiration cmdlet returns password expiration policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password expiration policy for each local user of SDDC Manager

        .EXAMPLE
        Publish-SddcManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -allDomains
        This example will return password expiration policy for each local user of SDDC Manager

        .EXAMPLE
        Publish-SddcManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-w01
        This example will NOT return the password expiration policy for each local user of SDDC Manager as the Workload Domain provided is not the Management Domain

        .EXAMPLE
        Publish-SddcManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return the password expiration policy for each local user of SDDC Manager and compare the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Publish-SddcManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift
        This example will return the password expiration policy for each local user of SDDC Manager and compare the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER sddcRootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcRootPass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command to be Executed
    [Array]$localUsers = '"root","vcf","backup"'
    $command = "Request-LocalUserPasswordExpiration -server $server -user $user -pass $pass -domain $((Get-VCFWorkloadDomain | Where-Object {$_.type -eq "MANAGEMENT"}).name) -vmName $(($server.Split("."))[-0]) -guestUser root -guestPassword $sddcRootPass -localUser $localUsers -product sddcManager"
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $command = $command + " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $command = $command + " -drift" }}

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $allSddcManagerPasswordExpirationObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $workloadDomain -and $_.type -eq "MANAGEMENT"}) {
                        $userPasswordExpiration = Invoke-Expression $command ;  $allSddcManagerPasswordExpirationObject += $userPasswordExpiration
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if ($domain | Where-Object {$_.type -eq "MANAGEMENT"}) {
                            $userPasswordExpiration = Invoke-Expression $command ;  $allSddcManagerPasswordExpirationObject += $userPasswordExpiration
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $allSddcManagerPasswordExpirationObject
                } else {
                    if ($allSddcManagerPasswordExpirationObject.Count -eq 0) { $notManagement = $true }
                    if ($notManagement) {
                        $allSddcManagerPasswordExpirationObject = $allSddcManagerPasswordExpirationObject | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-password-expiration"></a><h3>SDDC Manager - Password Expiration</h3>' -PostContent '<p>Management Domain not requested.</p>'
                    } else {
                        $allSddcManagerPasswordExpirationObject = $allSddcManagerPasswordExpirationObject | Sort-Object 'Workload Domain', 'System', 'User' | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-password-expiration"></a><h3>SDDC Manager - Password Expiration</h3>' -As Table
                    }
                    $allSddcManagerPasswordExpirationObject = Convert-CssClassStyle -htmldata $allSddcManagerPasswordExpirationObject
                    $allSddcManagerPasswordExpirationObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-SddcManagerPasswordExpiration

Function Publish-SddcManagerPasswordComplexity {
    <#
        .SYNOPSIS
        Publish password complexity policy for SDDC Manager.

        .DESCRIPTION
        The Publish-SddcManagerPasswordComplexity cmdlet returns password complexity policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password complexity policy for SDDC Manager

        .EXAMPLE
        Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -allDomains
        This example will return password complexity policy for SDDC Manager

        .EXAMPLE
        Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-w01
        This example will NOT return the password complexity policy for SDDC Manager as the Workload Domain provided is not the Management Domain

        .EXAMPLE
        Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return the password complexity policy for SDDC Manager and compare the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Publish-SddcManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift
        This example will return the password complexity policy for SDDC Manager and compare the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER sddcRootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER allDomains
        Switch to return the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to return the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcRootPass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command to be Executed
    $command = "Request-SddcManagerPasswordComplexity -server $server -user $user -pass $pass -rootPass $sddcRootPass"
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $command = $command + " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $command = $command + " -drift" }}

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $sddcManagerPasswordComplexityObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $workloadDomain -and $_.type -eq "MANAGEMENT"}) {
                        $sddcManagerPasswordComplexity = Invoke-Expression $command ; $sddcManagerPasswordComplexityObject += $sddcManagerPasswordComplexity
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if ($domain | Where-Object {$_.type -eq "MANAGEMENT"}) {
                            $sddcManagerPasswordComplexity = Invoke-Expression $command ; $sddcManagerPasswordComplexityObject += $sddcManagerPasswordComplexity
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $sddcManagerPasswordComplexityObject
                } else {
                    if ($sddcManagerPasswordComplexityObject.Count -eq 0) { $notManagement = $true }
                    if ($notManagement) {
                        $sddcManagerPasswordComplexityObject = $sddcManagerPasswordComplexityObject | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-password-complexity"></a><h3>SDDC Manager - Password Complexity</h3>' -PostContent '<p>Management Domain not requested.</p>'
                    } else {
                        $sddcManagerPasswordComplexityObject = $sddcManagerPasswordComplexityObject | Sort-Object 'System' | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-password-complexity"></a><h3>SDDC Manager - Password Complexity</h3>' -As Table
                    }
                    $sddcManagerPasswordComplexityObject = Convert-CssClassStyle -htmldata $sddcManagerPasswordComplexityObject
                    $sddcManagerPasswordComplexityObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-SddcManagerPasswordComplexity

Function Publish-SddcManagerAccountLockout {
    <#
        .SYNOPSIS
        Publish password complexity policy for SDDC Manager.

        .DESCRIPTION
        The Publish-SddcManagerAccountLockout cmdlet returns account lockout policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects account lockout policy forSDDC Manager

        .EXAMPLE
        Publish-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -allDomains
        This example will return account lockout policy for SDDC Manager

        .EXAMPLE
        Publish-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-w01
        This example will NOT return the account lockout policy for SDDC Manager as the Workload Domain provided is not the Management Domain

        .EXAMPLE
        Publish-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return the account lockout policy for SDDC Manager and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Publish-SddcManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -sddcRootPass VMw@re1! -workloadDomain sfo-m01 -drift
        This example will return the account lockout policy for SDDC Manager and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER sddcRootPass
        The password for the SDDC Manager appliance root account.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$sddcRootPass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command to be Executed
    $command = "Request-SddcManagerAccountLockout -server $server -user $user -pass $pass -rootPass $sddcRootPass"
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $command = $command + " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $command = $command + " -drift" }}

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $sddcManagerAccountLockoutObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $workloadDomain -and $_.type -eq "MANAGEMENT"}) {
                        $sddcManagerAccountlockout = Invoke-Expression $command ; $sddcManagerAccountLockoutObject += $sddcManagerAccountlockout
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if ($domain | Where-Object {$_.type -eq "MANAGEMENT"}) {
                            $sddcManagerAccountlockout = Invoke-Expression $command ; $sddcManagerAccountLockoutObject += $sddcManagerAccountlockout
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $sddcManagerAccountLockoutObject
                } else {
                    if ($sddcManagerAccountLockoutObject.Count -eq 0) { $notManagement = $true }
                    if ($notManagement) {
                        $sddcManagerAccountLockoutObject = $sddcManagerAccountLockoutObject | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-account-lockout"></a><h3>SDDC Manager - Account Lockout</h3>' -PostContent '<p>Management Domain not requested.</p>'
                    } else {
                        $sddcManagerAccountLockoutObject = $sddcManagerAccountLockoutObject | Sort-Object 'System' | ConvertTo-Html -Fragment -PreContent '<a id="sddcmanager-account-lockout"></a><h3>SDDC Manager - Account Lockout</h3>' -As Table
                    }
                    $sddcManagerAccountLockoutObject = Convert-CssClassStyle -htmldata $sddcManagerAccountLockoutObject
                    $sddcManagerAccountLockoutObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-SddcManagerAccountLockout

#EndRegion  End SDDC Manager Password Management Functions          ######
##########################################################################

##########################################################################
#Region     Begin SSO Password Management Functions                 ######

Function Request-SsoPasswordExpiration {
    <#
		.SYNOPSIS
		Retrieve the password expiration policy

        .DESCRIPTION
        The Request-SsoPasswordExpiration cmdlet retrieves the password expiration policy for a vCenter Single Sign-On
        domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrives the global password expiration policy

        .EXAMPLE
        Request-SsoPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password expiration policy for the vCenter Single Sign-On domain

        .EXAMPLE
        Request-SsoPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password expiration policy for the vCenter Single Sign-On domain and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Request-SsoPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password expiration policy for the vCenter Single Sign-On domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)



	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).sso.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).sso.passwordExpiration
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                if ($SsoPasswordExpiration = Get-SsoPasswordPolicy -server $ssoAdminServer) {
                                    $SsoPasswordExpirationObject = New-Object -TypeName psobject
                                    $SsoPasswordExpirationObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $SsoPasswordExpirationObject | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfVcenterDetails.fqdn)
                                    $SsoPasswordExpirationObject | Add-Member -notepropertyname "Max Days" -notepropertyvalue  $(if ($drift) { if ($SsoPasswordExpiration.PasswordLifetimeDays -ne $requiredConfig.maxDays) { "$($SsoPasswordExpiration.PasswordLifetimeDays) [ $($requiredConfig.maxDays) ]" } else { "$($SsoPasswordExpiration.PasswordLifetimeDays)" }} else { "$($SsoPasswordExpiration.PasswordLifetimeDays)" })
                                } else {
                                    Write-Error "Unable to retrieve password expiration policy from vCenter Single Sign-On ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
                                }
                                return $SsoPasswordExpirationObject
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    } 
}
Export-ModuleMember -Function Request-SsoPasswordExpiration

Function Request-SsoPasswordComplexity {
	<#
        .SYNOPSIS
        Retrieves vCenter Single Sign-On domain password complexity

        .DESCRIPTION
        The Request-SsoPasswordComplexity cmdlet retrieves the vCenter Single Sign-On domain password complexity
        policy. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Single Sign-On domain
        - Retrieve the password complexity policy

        .EXAMPLE
        Request-SsoPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password complexity policy for vCenter Single Sign-On domain of workload domain sfo-m01

        .EXAMPLE
        Request-SsoPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for vCenter Single Sign-On domain of workload domain sfo-m01 and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Request-SsoPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password complexity policy for vCenter Single Sign-On domain of workload domain sfo-m01 and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)


	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {              
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).sso.passwordComplexity
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).sso.passwordComplexity
                    }
                }
				if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                if ($SsoPasswordComplexity = Get-SsoPasswordPolicy -server $ssoAdminServer) {
                                    $SsoPasswordComplexityObject = New-Object -TypeName psobject
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfVcenterDetails.fqdn)
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Length" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinLength -ne $requiredConfig.minLength) { "$($SsoPasswordComplexity.MinLength) [ $($requiredConfig.minLength) ]" } else { "$($SsoPasswordComplexity.MinLength)" }} else { "$($SsoPasswordComplexity.MinLength)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Max Length" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MaxLength -ne $requiredConfig.maxLength) { "$($SsoPasswordComplexity.MaxLength) [ $($requiredConfig.maxLength) ]" } else { "$($SsoPasswordComplexity.MaxLength)" }} else { "$($SsoPasswordComplexity.MaxLength)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Alphabetic" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinAlphabeticCount -ne $requiredConfig.minAlphabetic) { "$($SsoPasswordComplexity.MinAlphabeticCount) [ $($requiredConfig.minAlphabetic) ]" } else { "$($SsoPasswordComplexity.MinAlphabeticCount)" }} else { "$($SsoPasswordComplexity.MinAlphabeticCount)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Lowercase" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinLowercaseCount -ne $requiredConfig.minLowercase) { "$($SsoPasswordComplexity.MinLowercaseCount) [ $($requiredConfig.minLowercase) ]" } else { "$($SsoPasswordComplexity.MinLowercaseCount)" }} else { "$($SsoPasswordComplexity.MinLowercaseCount)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Uppercase" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinUppercaseCount -ne $requiredConfig.minUppercase) { "$($SsoPasswordComplexity.MinUppercaseCount) [ $($requiredConfig.minUppercase) ]" } else { "$($SsoPasswordComplexity.MinUppercaseCount)" }} else { "$($SsoPasswordComplexity.MinUppercaseCount)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Numberic" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinNumericCount -ne $requiredConfig.minNumerical) { "$($SsoPasswordComplexity.MinNumericCount) [ $($requiredConfig.minNumerical) ]" } else { "$($SsoPasswordComplexity.MinNumericCount)" }} else { "$($SsoPasswordComplexity.MinNumericCount)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Min Special" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MinSpecialCharCount -ne $requiredConfig.minSpecial) { "$($SsoPasswordComplexity.MinSpecialCharCount) [ $($requiredConfig.minSpecial) ]" } else { "$($SsoPasswordComplexity.MinSpecialCharCount)" }} else { "$($SsoPasswordComplexity.MinSpecialCharCount)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "Max Identical Adjacent" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.MaxIdenticalAdjacentCharacters -ne $requiredConfig.maxIdenticalAdjacent) { "$($SsoPasswordComplexity.MaxIdenticalAdjacentCharacters) [ $($requiredConfig.maxIdenticalAdjacent) ]" } else { "$($SsoPasswordComplexity.MaxIdenticalAdjacentCharacters)" }} else { "$($SsoPasswordComplexity.MaxIdenticalAdjacentCharacters)" })
                                    $SsoPasswordComplexityObject | Add-Member -notepropertyname "History" -notepropertyvalue $(if ($drift) { if ($SsoPasswordComplexity.ProhibitedPreviousPasswordsCount -ne $requiredConfig.history) { "$($SsoPasswordComplexity.ProhibitedPreviousPasswordsCount) [ $($requiredConfig.history) ]" } else { "$($SsoPasswordComplexity.ProhibitedPreviousPasswordsCount)" }} else { "$($SsoPasswordComplexity.ProhibitedPreviousPasswordsCount)" })
                                } else {
                                    Write-Error "Unable to retrieve password complexity policy from vCenter Single Sign-On ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
                                }
                                return $SsoPasswordComplexityObject
                            }
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    }
}
Export-ModuleMember -Function Request-SsoPasswordComplexity

Function Request-SsoAccountLockout {
	<#
        .SYNOPSIS
        Retrieves vCenter Single Sign-On domain account lockout policy

        .DESCRIPTION
        The Request-SsoAccountLockout cmdlet retrieves the vCenter Single Sign-On domain account lockout policy.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Single Sign-On domain
        - Retrieve the account lockout policy

        .EXAMPLE
        Request-SsoAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the account lockout policy for vCenter Single Sign-On domain of workload domain sfo-m01

        .EXAMPLE
        Request-SsoAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the account lockout policy for vCenter Single Sign-On domain of workload domain sfo-m01 and compares the configuration against passwordPolicyConfig.json

        .EXAMPLE
        Request-SsoAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the account lockout policy for vCenter Single Sign-On domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)



	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).sso.accountLockout
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).sso.accountLockout
                    }
                }
				if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                if ($SsoAccountLockout = Get-SsoLockoutPolicy -server $ssoAdminServer) {
                                    $SsoAccountLockoutObject = New-Object -TypeName psobject
                                    $SsoAccountLockoutObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $SsoAccountLockoutObject | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfVcenterDetails.fqdn)
                                    $SsoAccountLockoutObject | Add-Member -notepropertyname "Max Failures" -notepropertyvalue $(if ($drift) { if ($SsoAccountLockout.MaxFailedAttempts -ne $requiredConfig.maxFailures) { "$($SsoAccountLockout.MaxFailedAttempts) [ $($requiredConfig.maxFailures) ]" } else { "$($SsoAccountLockout.MaxFailedAttempts)" }} else { "$($SsoAccountLockout.MaxFailedAttempts)" })
                                    $SsoAccountLockoutObject | Add-Member -notepropertyname "Unlock Interval (sec)" -notepropertyvalue $(if ($drift) { if ($SsoAccountLockout.AutoUnlockIntervalSec -ne $requiredConfig.unlockInterval) { "$($SsoAccountLockout.AutoUnlockIntervalSec) [ $($requiredConfig.unlockInterval) ]" } else { "$($SsoAccountLockout.AutoUnlockIntervalSec)" }} else { "$($SsoAccountLockout.AutoUnlockIntervalSec)" })
                                    $SsoAccountLockoutObject | Add-Member -notepropertyname "Failed Attempt Interval (sec)" -notepropertyvalue $(if ($drift) { if ($SsoAccountLockout.FailedAttemptIntervalSec -ne $requiredConfig.failedAttemptInterval) { "$($SsoAccountLockout.FailedAttemptIntervalSec) [ $($requiredConfig.failedAttemptInterval) ]" } else { "$($SsoAccountLockout.FailedAttemptIntervalSec)" }} else { "$($SsoAccountLockout.FailedAttemptIntervalSec)" })
                                } else {
                                    Write-Error "Unable to retrieve account lockout policy from vCenter Single Sign-On ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
                                }
                                return $SsoAccountLockoutObject
                            }
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    }
}
Export-ModuleMember -Function Request-SsoAccountLockout

Function Update-SsoPasswordExpiration {
    <#
		.SYNOPSIS
		Update the vCenter Single Sign-On password expiration policy

        .DESCRIPTION
        The Update-SsoPasswordExpiration cmdlet configures the password expiration policy of a vCenter Single Sign-On
        domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the vCenter Single Sign-On password expiration policy

        .EXAMPLE
        Update-SsoPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -maxDays 999
        This example configures the password expiration policy for a vCenter Single Sign-On domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER maxDays
        The maximum number of days that a password is valid for.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxDays
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                if ((Get-SsoPasswordPolicy -server $ssoAdminServer).PasswordLifetimeDays -ne $maxDays) {
                                    Get-SsoPasswordPolicy -server $ssoAdminServer | Set-SsoPasswordPolicy -PasswordLifetimeDays $maxDays | Out-Null
                                    if ((Get-SsoPasswordPolicy -server $ssoAdminServer).PasswordLifetimeDays -eq $maxDays) {
                                        Write-Output "Update Single Sign-On Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Single Sign-On Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Single Sign-On Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    }
}
Export-ModuleMember -Function Update-SsoPasswordExpiration

Function Update-SsoPasswordComplexity {
    <#
		.SYNOPSIS
		Update the vCenter Single Sign-On password complexity policy

        .DESCRIPTION
        The Update-SsoPasswordComplexity cmdlet configures the password complexity policy of a vCenter Single Sign-On
        domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the vCenter Single Sign-On password complexity policy

        .EXAMPLE
        Update-SsoPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 15 -maxLength 20 -minAlphabetic 2 -minLowercase 1 -minUppercase 1 -minNumeric 1 -minSpecial 1 -maxIdenticalAdjacent 1 -history 5
        This example configures the password complexity policy for a vCenter Single Sign-On domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER minLength
        The minimum length of the password.

        .PARAMETER maxLength
        The maximum length of the password.

        .PARAMETER minAlphabetic
        The minimum number of alphabetic characters in the password.

        .PARAMETER minLowercase
        The minimum number of lowercase characters in the password.

        .PARAMETER minUppercase
        The minimum number of uppercase characters in the password.

        .PARAMETER minNumeric
        The minimum number of numeric characters in the password.

        .PARAMETER minSpecial
        The minimum number of special characters in the password.

        .PARAMETER maxIdenticalAdjacent
        The maximum number of identical adjacent characters in the password.

        .PARAMETER history
        The number of previous passwords that a password cannot match.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxLength,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minAlphabetic,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minNumeric,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxIdenticalAdjacent,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$history
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                $passwordComplexityConfigBefore =  Get-SsoPasswordPolicy -server $ssoAdminServer
                                if ($passwordComplexityConfigBefore.MinLength -ne $minLength -or $passwordComplexityConfigBefore.MaxLength -ne $maxLength -or $passwordComplexityConfigBefore.MinAlphabeticCount -ne $minAlphabetic -or $passwordComplexityConfigBefore.MinLowercaseCount -ne $minLowercase -or $passwordComplexityConfigBefore.MinUppercaseCount -ne $minUppercase -or $passwordComplexityConfigBefore.MinNumericCount -ne $minNumeric -or $passwordComplexityConfigBefore.MinSpecialCharCount -ne $minSpecial -or $passwordComplexityConfigBefore.MaxIdenticalAdjacentCharacters -ne $maxIdenticalAdjacent -or $passwordComplexityConfigBefore.ProhibitedPreviousPasswordsCount -ne $history) {
                                    Get-SsoPasswordPolicy -server $ssoAdminServer| Set-SsoPasswordPolicy -MinLength $minLength -MaxLength $maxLength -MinAlphabeticCount $minAlphabetic -MinLowercaseCount $minLowercase -MinUppercaseCount $minUppercase -MinNumericCount $minNumeric -MinSpecialCharCount $minSpecial -MaxIdenticalAdjacentCharacters $maxIdenticalAdjacent -ProhibitedPreviousPasswordsCount $history | Out-Null
                                    $passwordComplexityConfigAfter =  Get-SsoPasswordPolicy -server $ssoAdminServer
                                    if ($passwordComplexityConfigAfter.MinLength -eq $minLength -and $passwordComplexityConfigAfter.MaxLength -eq $maxLength -and $passwordComplexityConfigAfter.MinAlphabeticCount -eq $minAlphabetic -and $passwordComplexityConfigAfter.MinLowercaseCount -eq $minLowercase -and $passwordComplexityConfigAfter.MinUppercaseCount -eq $minUppercase -and $passwordComplexityConfigAfter.MinNumericCount -eq $minNumeric -and $passwordComplexityConfigAfter.MinSpecialCharCount -eq $minSpecial -and $passwordComplexityConfigAfter.MaxIdenticalAdjacentCharacters -eq $maxIdenticalAdjacent -and $passwordComplexityConfigAfter.ProhibitedPreviousPasswordsCount -eq $history) {
                                        Write-Output "Update Single Sign-On Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Single Sign-On Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Single Sign-On Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    }
}
Export-ModuleMember -Function Update-SsoPasswordComplexity

Function Update-SsoAccountLockout {
    <#
		.SYNOPSIS
		Update the vCenter Single Sign-On account lockout policy

        .DESCRIPTION
        The Update-SsoAccountLockout cmdlet configures the account lockout policy of a vCenter Single Sign-On domain.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the vCenter Single Sign-On account lockout policy

        .EXAMPLE
        Update-SsoAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -failures 5 -failureInterval 180 -unlockInterval 900
        This example configures the account lockout policy for a vCenter Single Sign-On domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER failureInterval
        The number of seconds before the failed login attempts counter is reset.

        .PARAMETER unlockInterval
        The number of seconds before a locked account is unlocked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failureInterval,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval

	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-SsoConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-SsoAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                Try {
                                    $certificateValidator = New-Object 'VMware.vSphere.SsoAdmin.Utils.AcceptAllX509CertificateValidator'
                                    $securePass = ConvertTo-SecureString $vcfVcenterDetails.ssoAdminPass -AsPlainText -Force
                                    $ssoAdminServer = New-Object `
                                    'VMware.vSphere.SsoAdminClient.DataTypes.SsoAdminServer' `
                                    -ArgumentList @(
                                        $vcfVcenterDetails.fqdn,
                                        $vcfVcenterDetails.ssoAdmin,
                                        $securePass,
                                    $certificateValidator)
                                } Catch {
                                    Write-Error $_.Exception
                                }
                                $lockoutPolicyBefore =  Get-SsoLockoutPolicy -server $ssoAdminServer
                                if ($lockoutPolicyBefore.MaxFailedAttempts -ne $failures -or $lockoutPolicyBefore.FailedAttemptIntervalSec -ne $failureInterval -or $lockoutPolicyBefore.AutoUnlockIntervalSec -ne $unlockInterval) {
                                    Get-SsoLockoutPolicy -server $ssoAdminServer | Set-SsoLockoutPolicy  -AutoUnlockIntervalSec $unlockInterval -FailedAttemptIntervalSec $failureInterval -MaxFailedAttempts $failures | Out-Null
                                    $lockoutPolicyAfter =  Get-SsoLockoutPolicy -server $ssoAdminServer
                                    if ($lockoutPolicyAfter.MaxFailedAttempts -eq $failures -and $lockoutPolicyAfter.FailedAttemptIntervalSec -eq $failureInterval -and $lockoutPolicyAfter.AutoUnlockIntervalSec -eq $unlockInterval) {
                                        Write-Output "Update Single Sign-On Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Single Sign-On Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Single Sign-On Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($Global:DefaultSsoAdminServers) {
            Disconnect-SsoAdminServer -Server $Global:DefaultSsoAdminServers
        }
    }
}
Export-ModuleMember -Function Update-SsoAccountLockout

Function Publish-SsoPasswordPolicy {
    <#
        .SYNOPSIS
        Publish password policies for vCenter Single Sign-On

        .DESCRIPTION
        The Publish-SsoPasswordPolicy cmdlet retrieves the requested password policy for vCenter Single Sign-On and
        converts the output to HTML. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Retrieves the requested password policy for vCenter Single Sign-On and converts to HTML

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -allDomains
        This example will return password expiration policy for vCenter Single Sign-On across all Workload Domains

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-w01
        This example will return password expiration policy for vCenter Single Sign-On for a Workload Domain

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -allDomains
        This example will return password complexity policy for vCenter Single Sign-On across all Workload Domains

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -workloadDomain sfo-w01
        This example will return password complexity policy for vCenter Single Sign-On for a Workload Domain

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -allDomains
        This example will return account lockout policy for vCenter Single Sign-On across all Workload Domains

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -workloadDomain sfo-w01
        This example will return account lockout policy for vCenter Single Sign-On for a Workload Domain

        .EXAMPLE
        Publish-SsoPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for vCenter Single Sign-On across for a Workload Domains and compare the configuration against the passwordPolicyConfig.json

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER policy
        The policy to publish. One of: PasswordExpiration, PasswordComplexity, AccountLockout.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateSet('PasswordExpiration','PasswordComplexity','AccountLockout')] [String]$policy,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    if ($policy -eq "PasswordExpiration") { $pvsCmdlet = "Request-SsoPasswordExpiration"; $preHtmlContent = '<a id="sso-password-expiration"></a><h3>vCenter Single Sign-On - Password Expiration</h3>' }
    if ($policy -eq "PasswordComplexity") { $pvsCmdlet = "Request-SsoPasswordComplexity"; $preHtmlContent = '<a id="sso-password-complexity"></a><h3>vCenter Single Sign-On - Password Complexity</h3>' }
    if ($policy -eq "AccountLockout") { $pvsCmdlet = "Request-SsoAccountLockout"; $preHtmlContent = '<a id="sso-account-lockout"></a><h3>vCenter Single Sign-On - Account Lockout</h3>' }

    # Define the Command
    $command = $pvsCmdlet + " -server $server -user $user -pass $pass"
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $ssoPasswordPolicyObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $workloadDomain}) {
                        $command = $command + " -domain " + $workloadDomain + $commandSwitch
                        $ssoPolicy = Invoke-Expression $command ; $ssoPasswordPolicyObject += $ssoPolicy
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if ($domain | Where-Object {$_.type -eq "MANAGEMENT"}) {
                            $command = $command + " -domain " + $($domain.name) + $commandSwitch
                            $ssoPolicy = Invoke-Expression $command ; $ssoPasswordPolicyObject += $ssoPolicy
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $ssoPasswordPolicyObject
                } else {
                    if ($ssoPasswordPolicyObject.Count -eq 0) { $notManagement = $true }
                    if ($notManagement) {
                        $ssoPasswordPolicyObject = $ssoPasswordPolicyObject | ConvertTo-Html -Fragment -PreContent $preHtmlContent -PostContent '<p>Management Domain not requested.</p>'
                    } else {
                        $ssoPasswordPolicyObject = $ssoPasswordPolicyObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent $preHtmlContent -As Table
                    }
                    $ssoPasswordPolicyObject = Convert-CssClassStyle -htmldata $ssoPasswordPolicyObject
                    $ssoPasswordPolicyObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-SsoPasswordPolicy

#EndRegion  End SSO Password Management Functions                   ######
##########################################################################

##########################################################################
#Region     Begin vCenter Password Management Function              ######

Function Request-VcenterPasswordExpiration {
    <#
		.SYNOPSIS
		Retrieve the global password expiration policy

        .DESCRIPTION
        The Request-VcenterPasswordExpiration cmdlet retrieves the global password expiration policy for a vCenter
        Server. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrives the global password expiration policy

        .EXAMPLE
        Request-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the global password expiration policy for the vCenter Server

        .EXAMPLE
        Request-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the global password expiration policy for the vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the global password expiration policy for the vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).vcenterServer.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).vcenterServer.passwordExpiration
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereApiConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereApiAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ($VcenterPasswordExpiration = Get-VcenterPasswordExpiration) {
                                    $VcenterPasswordExpirationObject = New-Object -TypeName psobject
                                    $VcenterPasswordExpirationObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $VcenterPasswordExpirationObject | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfVcenterDetails.fqdn)
                                    $VcenterPasswordExpirationObject | Add-Member -notepropertyname "Min Days" -notepropertyvalue $(if ($drift) { if ($VcenterPasswordExpiration.min_days -ne $requiredConfig.minDays) { "$($VcenterPasswordExpiration.min_days) [ $($requiredConfig.minDays) ]" } else { "$($VcenterPasswordExpiration.min_days)" }} else { "$($VcenterPasswordExpiration.min_days)" })
                                    $VcenterPasswordExpirationObject | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($VcenterPasswordExpiration.max_days -ne $requiredConfig.maxDays) { "$($VcenterPasswordExpiration.max_days) [ $($requiredConfig.maxDays) ]" } else { "$($VcenterPasswordExpiration.max_days)" }} else { "$($VcenterPasswordExpiration.max_days)" })
                                    $VcenterPasswordExpirationObject | Add-Member -notepropertyname "Warning Days" -notepropertyvalue $(if ($drift) { if ($VcenterPasswordExpiration.warn_days -ne $requiredConfig.warningDays) { "$($VcenterPasswordExpiration.warn_days) [ $($requiredConfig.warningDays) ]" } else { "$($VcenterPasswordExpiration.warn_days)" }} else { "$($VcenterPasswordExpiration.warn_days)" })
                                } else {
                                    Write-Error "Unable to retrieve password expiration policy from vCenter Server ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
                                }
                                return $VcenterPasswordExpirationObject
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-VcenterPasswordExpiration

Function Request-VcenterPasswordComplexity {
    <#
		.SYNOPSIS
		Retrieve the password complexity policy

        .DESCRIPTION
        The Request-VcenterPasswordComplexity cmdlet retrieves the password complexity policy of a vCenter Server.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrieves the password complexity policy

        .EXAMPLE
        Request-VcenterPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password complexity policy for the vCenter Server based on the workload domain

        .EXAMPLE
        Request-VcenterPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for the vCenter Server based on the workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-VcenterPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password complexity policy for the vCenter Server based on the workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        $mgmtConnected = $false
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        $vcenterDomain = $vcfVcenterDetails.type
                        if ($vcenterDomain -ne "MANAGEMENT") {
                            if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                    if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                        if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                            $mgmtConnected = $true
                                        }
                                    }
                                }
                            } else {
                                Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                            }
                        }
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ($drift) {
                                    $version = ""
                                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                                        $version = $Matches[0]
                                    } 
                                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                                        Get-LocalPasswordComplexity -version $version -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal -drift -reportPath $reportPath -policyFile $policyFile
                                    } else {
                                        Get-LocalPasswordComplexity -version $version -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal -drift
                                    }
                                } else {
                                    Get-LocalPasswordComplexity -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-VcenterPasswordComplexity

Function Request-VcenterAccountLockout {
    <#
		.SYNOPSIS
		Retrieve the account lockout policy for vCenter Server

        .DESCRIPTION
        The Request-VcenterAccountLockout cmdlet retrieves the account lockout policy of a vCenter Server.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrieves the account lockout policy

        .EXAMPLE
        Request-VcenterAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the account lockout policy for the vCenter Server based on the workload domain

        .EXAMPLE
        Request-VcenterAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the account lockout policy for the vCenter Server based on the workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-VcenterAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the account lockout policy for the vCenter Server based on the workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        $mgmtConnected = $false
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {                
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        $vcenterDomain = $vcfVcenterDetails.type
                        if ($vcenterDomain -ne "MANAGEMENT") {
                            if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                    if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                        if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                            $mgmtConnected = $true
                                        }
                                    }
                                }
                            } else {
                                Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                            }
                        }
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ($drift) {
                                    $version = ""
                                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                                        $version = $Matches[0]
                                    } 
                                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                                        Get-LocalAccountLockout -version $version -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal -drift -reportPath $reportPath -policyFile $policyFile
                                    } else {
                                        Get-LocalAccountLockout -version $version -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal -drift
                                    }
                                } else {
                                    Get-LocalAccountLockout -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal
                                }
                            }

                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-VcenterAccountLockout

Function Update-VcenterPasswordExpiration {
    <#
		.SYNOPSIS
		Update the global password expiration policy

        .DESCRIPTION
        The Update-VcenterPasswordExpiration cmdlet configures the global password expiration policy of a vCenter Server.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the global password expiration policy

        .EXAMPLE
        Update-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -maxDays 999 -minDays 0 -warnDays 14
        This example configures the global password expiration policy for the vCenter Server

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER maxDays
        The maximum number of days that a password is valid.

        .PARAMETER minDays
        The minimum number of days that a password is valid.

        .PARAMETER warnDays
        The number of days before a password expires that a warning is issued.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$warnDays
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereApiConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereApiAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ((Get-VcenterPasswordExpiration).max_days -ne $maxDays -or (Get-VcenterPasswordExpiration).min_days -ne $minDays -or (Get-VcenterPasswordExpiration).warn_days -ne $warnDays) {
                                    Set-VcenterPasswordExpiration -maxDays $maxDays -minDays $minDays -warnDays $warnDays | Out-Null
                                    if ((Get-VcenterPasswordExpiration).max_days -eq $maxDays -and (Get-VcenterPasswordExpiration).min_days -eq $minDays -and (Get-VcenterPasswordExpiration).warn_days -eq $warnDays) {
                                        Write-Output "Update Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-VcenterPasswordExpiration

Function Update-VcenterPasswordComplexity {
    <#
		.SYNOPSIS
		Update the password complexity policy

        .DESCRIPTION
        The Update-VcenterPasswordComplexity cmdlet configures the password complexity policy of a vCenter Server.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the password complexity policy

        .EXAMPLE
        Update-VcenterPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 6 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -history 5
        This example configures the password complexity policy for the vCenter Server based on the workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER minLength
        The minimum length of a password.

        .PARAMETER minLowercase
        The minimum number of lowercase characters in a password.

        .PARAMETER minUppercase
        The minimum number of uppercase characters in a password.

        .PARAMETER minNumerical
        The minimum number of numerical characters in a password.

        .PARAMETER minSpecial
        The minimum number of special characters in a password.

        .PARAMETER minUnique
        The minimum number of unique characters in a password.

        .PARAMETER history
        The number of previous passwords that a password cannot match.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minNumerical,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUnique,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$history
	)

	Try {
        $mgmtConnected = $false
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        $vcenterDomain = $vcfVcenterDetails.type
                        if ($vcenterDomain -ne "MANAGEMENT") {
                            if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                    if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                        if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                            $mgmtConnected = $true
                                        }
                                    }
                                }
                            } else {
                                Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                            }
                        }
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                $existingConfiguration = Get-LocalPasswordComplexity -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass
                                if ($existingConfiguration.'Min Length' -ne $minLength  -or $existingConfiguration.'Min Lowercase' -ne $minLowercase -or $existingConfiguration.'Min Uppercase' -ne $minUppercase -or $existingConfiguration.'Min Numerical' -ne $minNumerical -or $existingConfiguration.'Min Special' -ne $minSpecial -or $existingConfiguration.'Min Unique' -ne $minUnique -or $existingConfiguration.'History' -ne $history) {
                                    Set-LocalPasswordComplexity -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -minLength $minLength -uppercase $minUppercase -lowercase $minLowercase -numerical $minNumerical -special $minSpecial -unique $minUnique -history $history | Out-Null
                                    $updatedConfiguration = Get-LocalPasswordComplexity -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass
                                    if ($updatedConfiguration.'Min Length' -eq $minLength  -and $updatedConfiguration.'Min Lowercase' -eq $minLowercase -and $updatedConfiguration.'Min Uppercase' -eq $minUppercase -and $updatedConfiguration.'Min Numerical' -eq $minNumerical -and $updatedConfiguration.'Min Special' -eq $minSpecial -and $updatedConfiguration.'Min Unique' -eq $minUnique -and $updatedConfiguration.'History' -eq $history) {
                                        Write-Output "Update Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Password Complexity Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-VcenterPasswordComplexity

Function Update-VcenterAccountLockout {
    <#
		.SYNOPSIS
		Update the account lockout policy of vCenter Server

        .DESCRIPTION
        The Update-VcenterAccountLockout cmdlet configures the account lockout policy of a vCenter Server. The cmdlet
        connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the account lockout policy

        .EXAMPLE
        Update-VcenterAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -failures 3 -unlockInterval 900 -rootUnlockInterval 300
        This example configures the account lockout policy for the vCenter Server based on the workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER unlockInterval
        The number of seconds before a locked out account is unlocked.

        .PARAMETER rootUnlockInterval
        The number of seconds before a locked out root account is unlocked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$rootUnlockInterval
	)

	Try {
        $mgmtConnected = $false
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        $vcenterDomain = $vcfVcenterDetails.type
                        if ($vcenterDomain -ne "MANAGEMENT") {
                            if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                    if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                        if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                            $mgmtConnected = $true
                                        }
                                    }
                                }
                            } else {
                                Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                            }
                        }
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                $existingConfiguration = Get-LocalAccountLockout -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal
                                if ($existingConfiguration.'Max Failures' -ne $failures -or $existingConfiguration.'Unlock Interval (sec)' -ne $unlockInterval -or $existingConfiguration.'Root Unlock Interval (sec)' -ne $rootUnlockInterval) {
                                    Set-LocalAccountLockout -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -failures $failures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval | Out-Null
                                    $updatedConfiguration = Get-LocalAccountLockout -vmName ($vcfVcenterDetails.fqdn.Split("."))[-0] -guestUser $vcfVcenterDetails.root -guestPassword $vcfVcenterDetails.rootPass -product vcenterServerLocal
                                    if ($updatedConfiguration.'Max Failures' -eq $failures -and $updatedConfiguration.'Unlock Interval (sec)' -eq $unlockInterval -and $updatedConfiguration.'Root Unlock Interval (sec)' -eq $rootUnlockInterval) {
                                        Write-Output "Update Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                    } else {
                                        Write-Error "Update Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                    }
                                } else {
                                    Write-Warning "Update Account Lockout Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-VcenterAccountLockout

Function Request-VcenterRootPasswordExpiration {
    <#
		.SYNOPSIS
		Retrieves the root user password expiration policy

        .DESCRIPTION
        The Request-VcenterRootPasswordExpiration cmdlet retrieves the root user password expiration policy for a
        vCenter Server. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrives the root user password expiration policy

        .EXAMPLE
        Request-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the root user password expiration policy for the vCenter Server

        .EXAMPLE
        Request-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the root user password expiration policy for the vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the root user password expiration policy for the vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).vcenterServerLocal.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).vcenterServerLocal.passwordExpiration
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereApiConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereApiAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ($VcenterRootPasswordExpiration = Get-VcenterRootPasswordExpiration) {
                                    $VcenterRootPasswordExpirationObject = New-Object -TypeName psobject
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfVcenterDetails.fqdn)
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "User" -notepropertyvalue "root"
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "Min Days" -notepropertyvalue $(if ($drift) { if ($VcenterRootPasswordExpiration.min_days_between_password_change -ne $requiredConfig.minDays) { "$($VcenterRootPasswordExpiration.min_days_between_password_change) [ $($requiredConfig.minDays) ]" } else { "$($VcenterRootPasswordExpiration.min_days_between_password_change)" }} else { "$($VcenterRootPasswordExpiration.min_days_between_password_change)" })
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($VcenterRootPasswordExpiration.max_days_between_password_change -ne $requiredConfig.maxDays) { "$($VcenterRootPasswordExpiration.max_days_between_password_change) [ $($requiredConfig.maxDays) ]" } else { "$($VcenterRootPasswordExpiration.max_days_between_password_change)" }} else { "$($VcenterRootPasswordExpiration.max_days_between_password_change)" })
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "Warning Days" -notepropertyvalue $(if ($drift) { if ($VcenterRootPasswordExpiration.warn_days_before_password_expiration -ne $requiredConfig.warningDays) { "$($VcenterRootPasswordExpiration.warn_days_before_password_expiration) [ $($requiredConfig.warningDays) ]" } else { "$($VcenterRootPasswordExpiration.warn_days_before_password_expiration)" }} else { "$($VcenterRootPasswordExpiration.warn_days_before_password_expiration)" })
                                    $VcenterRootPasswordExpirationObject | Add-Member -notepropertyname "Email" -notepropertyvalue $(if ($drift) { if ($VcenterRootPasswordExpiration.email -ne $requiredConfig.email) { "$($VcenterRootPasswordExpiration.email) [ $($requiredConfig.email) ]" } else { "$($VcenterRootPasswordExpiration.email)" }} else { "$($VcenterRootPasswordExpiration.email)" })
                                } else {
                                    Write-Error "Unable to retrieve root password expiration policy from vCenter Server ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
                                }
                                return $VcenterRootPasswordExpirationObject
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-VcenterRootPasswordExpiration

Function Update-VcenterRootPasswordExpiration {
    <#
		.SYNOPSIS
		Update the root user password expiration policy

        .DESCRIPTION
        The Update-VcenterRootPasswordExpiration cmdlet configures the root user password expiration policy of a
        vCenter Server. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the root user password expiration policy

        .EXAMPLE
        Update-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -email "admin@rainpole.io" -maxDays 999 -warnDays 14
        This example configures the configures password expiration settings for the vCenter Server root account to expire after 999 days with email for warning set to "admin@rainpole.io"

        .EXAMPLE
        Update-VcenterRootPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -neverexpire
        This example configures the configures password expiration settings for the vCenter Server root account to never expire

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER email
        The email address to send password expiration warnings to.

        .PARAMETER maxDays
        The maximum number of days before the root user password expires.

        .PARAMETER warnDays
        The number of days before the root user password expires in which to send a warning email.

        .PARAMETER neverexpire
        Switch to configure the root user password to never expire.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'expire')] [ValidateNotNullOrEmpty()] [String]$email,
        [Parameter (Mandatory = $false, ParameterSetName = 'expire')] [ValidateNotNullOrEmpty()] [String]$maxDays,
        [Parameter (Mandatory = $false, ParameterSetName = 'expire')] [ValidateNotNullOrEmpty()] [String]$warnDays,
        [Parameter (Mandatory = $false, ParameterSetName = 'neverexpire')] [ValidateNotNullOrEmpty()] [Switch]$neverexpire
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereApiConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereApiAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if ($PsBoundParameters.ContainsKey("neverexpire")) {
                                    if ((Get-VcenterRootPasswordExpiration).max_days_between_password_change -ne -1) {
                                        Set-VcenterRootPasswordExpiration -neverexpire | Out-Null
                                        if ((Get-VcenterRootPasswordExpiration).max_days_between_password_change -ne -1) {
                                            Write-Output "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                        } else {
                                            Write-Error "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                        }
                                    } else {
                                        Write-Warning "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                    }
                                } else {
                                    if ((Get-VcenterRootPasswordExpiration).max_days_between_password_change -ne $maxDays -or (Get-VcenterRootPasswordExpiration).email -ne $email -or (Get-VcenterRootPasswordExpiration).warn_days_before_password_expiration -ne $warnDays) {
                                        Set-VcenterRootPasswordExpiration -email $email -maxDays $maxDays -warnDays $warnDays | Out-Null
                                        if ((Get-VcenterRootPasswordExpiration).max_days_between_password_change -eq $maxDays -or (Get-VcenterRootPasswordExpiration).min_days_between_password_change -eq $minDays -or (Get-VcenterRootPasswordExpiration).warn_days_before_password_expiration -eq $warnDays) {
                                            Write-Output "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): SUCCESSFUL"
                                        } else {
                                            Write-Error "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)): POST_VALIDATION_FAILED"
                                        }
                                    } else {
                                        Write-Warning "Update Root Password Expiration Policy on vCenter Server ($($vcfVcenterDetails.fqdn)), already set: SKIPPED"
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-VcenterRootPasswordExpiration

Function Publish-VcenterPasswordExpiration {
    <#
        .SYNOPSIS
        Publish password expiration policy for vCenter Server.

        .DESCRIPTION
        The Publish-VcenterPasswordExpiration cmdlet returns password expiration policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password expiration policy for vCenter Server

        .EXAMPLE
        Publish-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password expiration policy for each vCenter Server

        .EXAMPLE
        Publish-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for a vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Publish-VcenterPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password expiration policy for a vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command
    $GLobal:command = "Request-VcenterPasswordExpiration -server $server -user $user -pass $pass"
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $vcenterPasswordExpirationObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $vcenterPasswordExpiration = Invoke-Expression $command ; $vcenterPasswordExpirationObject += $vcenterPasswordExpiration
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $vcenterPasswordExpiration = Invoke-Expression $command ; $vcenterPasswordExpirationObject += $vcenterPasswordExpiration
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $vcenterPasswordExpirationObject
                } else {
                    $vcenterPasswordExpirationObject = $vcenterPasswordExpirationObject | Sort-Object 'Workload Domain', 'System', 'User' | ConvertTo-Html -Fragment -PreContent '<a id="vcenter-password-expiration"></a><h3>vCenter Server - Password Expiration</h3>' -As Table
                    $vcenterPasswordExpirationObject = Convert-CssClassStyle -htmldata $vcenterPasswordExpirationObject
                    $vcenterPasswordExpirationObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-VcenterPasswordExpiration

Function Publish-VcenterLocalPasswordExpiration {
    <#
        .SYNOPSIS
        Publish password expiration policy for each local user of vCenter Server.

        .DESCRIPTION
        The Publish-VcenterLocalPasswordExpiration cmdlet returns password expiration policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password expiration policy for each local user of vCenter Server

        .EXAMPLE
        Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password expiration policy for each local user of vCenter Server for all Workload Domains

        .EXAMPLE
        Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for each local user of vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Publish-VcenterLocalPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password expiration policy for each local user of vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $vcenterLocalPasswordExpirationObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $vcenterLocalPasswordExpiration = Invoke-Expression $command ; $vcenterLocalPasswordExpirationObject += $vcenterLocalPasswordExpiration
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $vcenterLocalPasswordExpiration = Invoke-Expression $command ; $vcenterLocalPasswordExpirationObject += $vcenterLocalPasswordExpiration
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $vcenterLocalPasswordExpirationObject
                } else {
                    $vcenterLocalPasswordExpirationObject = $vcenterLocalPasswordExpirationObject | Sort-Object 'Workload Domain', 'System', 'User' | ConvertTo-Html -Fragment -PreContent '<a id="vcenter-password-expiration-local"></a><h3>vCenter Server - Password Expiration (Local Users)</h3>' -As Table
                    $vcenterLocalPasswordExpirationObject = Convert-CssClassStyle -htmldata $vcenterLocalPasswordExpirationObject
                    $vcenterLocalPasswordExpirationObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-VcenterLocalPasswordExpiration

Function Publish-VcenterLocalPasswordComplexity {
    <#
        .SYNOPSIS
        Publish password complexity policy for each vCenter Server.

        .DESCRIPTION
        The Publish-VcenterLocalPasswordComplexity cmdlet returns password complexity policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password complexity policy for each vCenter Server

        .EXAMPLE
        Publish-VcenterLocalPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password complexity policy for each vCenter Server for all Workload Domains

        .EXAMPLE
        Publish-VcenterLocalPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password complexity policy for a vCenter Server

        .EXAMPLE
        Publish-VcenterLocalPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password complexity policy for a vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Publish-VcenterLocalPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password complexity policy for a vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $vcenterLocalPasswordComplexityObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $vcenterLocalPasswordComplexity = Invoke-Expression $command ; $vcenterLocalPasswordComplexityObject += $vcenterLocalPasswordComplexity
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $vcenterLocalPasswordComplexity = Invoke-Expression $command ; $vcenterLocalPasswordComplexityObject += $vcenterLocalPasswordComplexity
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $vcenterLocalPasswordComplexityObject
                } else {
                    $vcenterLocalPasswordComplexityObject = $vcenterLocalPasswordComplexityObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="vcenter-password-complexity-local"></a><h3>vCenter Server - Password Complexity (Local Users)</h3>' -As Table
                    $vcenterLocalPasswordComplexityObject = Convert-CssClassStyle -htmldata $vcenterLocalPasswordComplexityObject
                    $vcenterLocalPasswordComplexityObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-VcenterLocalPasswordComplexity

Function Publish-VcenterLocalAccountLockout {
    <#
        .SYNOPSIS
        Publish account lockout policy for each vCenter Server.

        .DESCRIPTION
        The Publish-VcenterLocalAccountLockout cmdlet returns account lockout policy for SDDC Manager.
        The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password account lockout for each vCenter Server

        .EXAMPLE
        Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password account lockout for each vCenter Server for all Workload Domains

        .EXAMPLE
        Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password account lockout for a vCenter Server

        .EXAMPLE
        Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password account lockout for a vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Publish-VcenterLocalAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password account lockout for a vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift " }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $vcenterLocalAccountLockoutObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-VcenterAccountLockout -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $vcenterLocalAccountLockout = Invoke-Expression $command ; $vcenterLocalAccountLockoutObject += $vcenterLocalAccountLockout
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-VcenterAccountLockout -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $vcenterLocalAccountLockout = Invoke-Expression $command ; $vcenterLocalAccountLockoutObject += $vcenterLocalAccountLockout
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $vcenterLocalAccountLockoutObject
                } else {
                    $vcenterLocalAccountLockoutObject = $vcenterLocalAccountLockoutObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="vcenter-account-lockout-local"></a><h3>vCenter Server - Account Lockout (Local Users)</h3>' -As Table
                    $vcenterLocalAccountLockoutObject = Convert-CssClassStyle -htmldata $vcenterLocalAccountLockoutObject
                    $vcenterLocalAccountLockoutObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-VcenterLocalAccountLockout

#EndRegion  End vCenter Password Management Functions               ######
##########################################################################

##########################################################################
#Region     Begin NSX Manager Password Management Function          ######

Function Request-NsxtManagerPasswordExpiration {
    <#
		.SYNOPSIS
		Retrieve the password expiration policy for NSX Local Manager Users

        .DESCRIPTION
        The Request-NsxtManagerPasswordExpiration cmdlet retrieves the password complexity policy for all NSX Local
        Manager cluster users for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and
        -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Retrieves the password expiration policy for all users

        .EXAMPLE
        Request-NsxtManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password expiration policy for all users for the NSX Local Manager cluster for a workload domain

        .EXAMPLE
        Request-NsxtManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password expiration policy for all users for the NSX Local Manager cluster for a workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password expiration policy for all users for the NSX Local Manager cluster for a workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxManager.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxManager.passwordExpiration
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $($vcfNsxDetails.fqdn)) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $nsxtPasswordExpirationPolicy = New-Object System.Collections.ArrayList
                                $localUsers = Get-NsxtApplianceUser
                                foreach ($localUser in $localUsers) {
                                    $localUserPasswordExpirationPolicy = New-Object -TypeName psobject
                                    $localUserPasswordExpirationPolicy | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                    $localUserPasswordExpirationPolicy | Add-Member -notepropertyname "System" -notepropertyvalue $($vcfNsxDetails.fqdn)
                                    $localUserPasswordExpirationPolicy | Add-Member -notepropertyname "User" -notepropertyvalue $($localUser.username)
                                    $localUserPasswordExpirationPolicy | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($localUser.password_change_frequency -ne $requiredConfig.maxDays) { "$($localUser.password_change_frequency) [ $($requiredConfig.maxDays) ]" } else { "$($localUser.password_change_frequency)" }} else { "$($localUser.password_change_frequency)" })
                                    $nsxtPasswordExpirationPolicy += $localUserPasswordExpirationPolicy
                                }
                                Return $nsxtPasswordExpirationPolicy
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } 
}
Export-ModuleMember -Function Request-NsxtManagerPasswordExpiration

Function Request-NsxtManagerPasswordComplexity {
    <#
		.SYNOPSIS
		Retrieve the password complexity policy for NSX Local Manager

        .DESCRIPTION
        The Request-NsxtManagerPasswordComplexity cmdlet retrieves the password complexity policy for each NSX Local Manager
        node for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Retrieves the password complexity policy

        .EXAMPLE
        Request-NsxtManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password complexity policy for each NSX Local Manager node for a workload domain

        .EXAMPLE
        Request-NsxtManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for each NSX Local Manager node for a workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password complexity policy for each NSX Local Manager node for a workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)



	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {   
                $version = ""
                if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                    $version = $Matches[0]
                }             
                if ($drift) { 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxManager.passwordComplexity
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxManager.passwordComplexity
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                                    $vcenterDomain = $vcfVcenterDetails.type
                                    if ($vcenterDomain -ne "MANAGEMENT") {
                                        if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                            if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                                if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                                    if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                                        $mgmtConnected = $true
                                                    }
                                                }
                                            }
                                        } else {
                                            Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                                        }
                                    }
                                
                                }
                                if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                                    $nsxtPasswordComplexityPolicy = New-Object System.Collections.ArrayList
                                    foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                                        if (Test-NSXTConnection -server $nsxtManagerNode.fqdn) {
                                            if (Test-NSXTAuthentication -server $nsxtManagerNode.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                                if ($version -lt "5.0") {
                                                    if ($nsxtManagerNodePolicy = Get-LocalPasswordComplexity -vmName ($nsxtManagerNode.fqdn.Split("."))[-0] -guestUser $vcfNsxDetails.rootUser -guestPassword $vcfNsxDetails.rootPass -nsx ) {
                                                        $NsxtManagerPasswordComplexityObject = New-Object -TypeName psobject
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "System" -notepropertyvalue $($nsxtManagerNode.fqdn)
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Length" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Length' -ne $requiredConfig.minLength) { "$($nsxtManagerNodePolicy.'Min Length') [ $($requiredConfig.minLength) ]" } else { "$($nsxtManagerNodePolicy.'Min Length')" }} else { "$($nsxtManagerNodePolicy.'Min Length')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Lowercase" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Lowercase' -ne $requiredConfig.minLowercase) { "$($nsxtManagerNodePolicy.'Min Lowercase') [ $($requiredConfig.minLowercase) ]" } else { "$($nsxtManagerNodePolicy.'Min Lowercase')" }} else { "$($nsxtManagerNodePolicy.'Min Lowercase')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Uppercase" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Uppercase' -ne $requiredConfig.minUppercase) { "$($nsxtManagerNodePolicy.'Min Uppercase') [ $($requiredConfig.minUppercase) ]" } else { "$($nsxtManagerNodePolicy.'Min Uppercase')" }} else { "$($nsxtManagerNodePolicy.'Min Uppercase')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Numerical" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Numerical' -ne $requiredConfig.minNumerical) { "$($nsxtManagerNodePolicy.'Min Numerical') [ $($requiredConfig.minNumerical) ]" } else { "$($nsxtManagerNodePolicy.'Min Numerical')" }} else { "$($nsxtManagerNodePolicy.'Min Numerical')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Special" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Special' -ne $requiredConfig.minSpecial) { "$($nsxtManagerNodePolicy.'Min Special') [ $($requiredConfig.minSpecial) ]" } else { "$($nsxtManagerNodePolicy.'Min Special')" }} else { "$($nsxtManagerNodePolicy.'Min Special')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Unique" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Min Unique' -ne $requiredConfig.minUnique) { "$($nsxtManagerNodePolicy.'Min Unique') [ $($requiredConfig.minUnique) ]" } else { "$($nsxtManagerNodePolicy.'Min Unique')" }} else { "$($nsxtManagerNodePolicy.'Min Unique')" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Max Retries" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.'Max Retries' -ne $requiredConfig.retries) { "$($nsxtManagerNodePolicy.'Max Retries') [ $($requiredConfig.retries) ]" } else { "$($nsxtManagerNodePolicy.'Max Retries')" }} else { "$($nsxtManagerNodePolicy.'Max Retries')" })
                                                        $nsxtPasswordComplexityPolicy += $NsxtManagerPasswordComplexityObject
                                                    } else {
                                                        Write-Error "Unable to retrieve Password Complexity Policy from NSX Local Manager node ($($nsxtManagerNode.fqdn)): PRE_VALIDATION_FAILED"
                                                    }
                                                } else {
                                                    if ($nsxtManagerNodePolicy = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn) {
                                                        $NsxtManagerPasswordComplexityObject = New-Object -TypeName psobject
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "System" -notepropertyvalue $($nsxtManagerNode.fqdn)
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Length" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.minimum_password_length -ne $requiredConfig.minLength) { "$($nsxtManagerNodePolicy.minimum_password_length) [ $($requiredConfig.minLength) ]" } else { "$($nsxtManagerNodePolicy.minimum_password_length)" }} else { "$($nsxtManagerNodePolicy.minimum_password_length)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Max Length" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.maximum_password_length -ne $requiredConfig.maxLength) { "$($nsxtManagerNodePolicy.maximum_password_length) [ $($requiredConfig.maxLength) ]" } else { "$($nsxtManagerNodePolicy.maximum_password_length)" }} else { "$($nsxtManagerNodePolicy.maximum_password_length)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Lowercase" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.lower_chars -ne $requiredConfig.minLowercase) { "$($nsxtManagerNodePolicy.lower_chars) [ $($requiredConfig.minLowercase) ]" } else { "$($nsxtManagerNodePolicy.lower_chars)" }} else { "$($nsxtManagerNodePolicy.lower_chars)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Uppercase" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.upper_chars -ne $requiredConfig.minUppercase) { "$($nsxtManagerNodePolicy.upper_chars) [ $($requiredConfig.minUppercase) ]" } else { "$($nsxtManagerNodePolicy.upper_chars)" }} else { "$($nsxtManagerNodePolicy.upper_chars)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Numerical" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.digits -ne $requiredConfig.minNumerical) { "$($nsxtManagerNodePolicy.digits) [ $($requiredConfig.minNumerical) ]" } else { "$($nsxtManagerNodePolicy.digits)" }} else { "$($nsxtManagerNodePolicy.digits)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Special" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.special_chars -ne $requiredConfig.minSpecial) { "$($nsxtManagerNodePolicy.special_chars) [ $($requiredConfig.minSpecial) ]" } else { "$($nsxtManagerNodePolicy.special_chars)" }} else { "$($nsxtManagerNodePolicy.special_chars)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Min Unique" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.minimum_unique_chars -ne $requiredConfig.minUnique) { "$($nsxtManagerNodePolicy.minimum_unique_chars) [ $($requiredConfig.minUnique) ]" } else { "$($nsxtManagerNodePolicy.minimum_unique_chars)" }} else { "$($nsxtManagerNodePolicy.minimum_unique_chars)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Max Repeats" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.max_repeats -ne $requiredConfig.maxRepeat) { "$($nsxtManagerNodePolicy.max_repeats) [ $($requiredConfig.maxRepeat) ]" } else { "$($nsxtManagerNodePolicy.max_repeats)" }} else { "$($nsxtManagerNodePolicy.max_repeats)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Max Sequence" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.max_sequence -ne $requiredConfig.maxSequence) { "$($nsxtManagerNodePolicy.max_sequence) [ $($requiredConfig.maxSequence) ]" } else { "$($nsxtManagerNodePolicy.max_sequence)" }} else { "$($nsxtManagerNodePolicy.max_sequence)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "History" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.password_remembrance -ne $requiredConfig.passwordRemembrance) { "$($nsxtManagerNodePolicy.password_remembrance) [ $($requiredConfig.passwordRemembrance) ]" } else { "$($nsxtManagerNodePolicy.password_remembrance)" }} else { "$($nsxtManagerNodePolicy.password_remembrance)" })
                                                        $NsxtManagerPasswordComplexityObject | Add-Member -notepropertyname "Hash Algorithm" -notepropertyvalue $(if ($drift) { if ($nsxtManagerNodePolicy.hash_algorithm -ne $requiredConfig.hashAlgorithm) { "$($nsxtManagerNodePolicy.hash_algorithm) [ $($requiredConfig.hashAlgorithm) ]" } else { "$($nsxtManagerNodePolicy.hash_algorithm)" }} else { "$($nsxtManagerNodePolicy.hash_algorithm)" })
                                                        $nsxtPasswordComplexityPolicy += $NsxtManagerPasswordComplexityObject
                                                    } else {
                                                        Write-Error "Unable to retrieve Account Lockout Policy from NSX Local Manager node ($($nsxtManagerNode.fqdn)): PRE_VALIDATION_FAILED"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    return $nsxtPasswordComplexityPolicy
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-NsxtManagerPasswordComplexity

Function Request-NsxtManagerAccountLockout {
    <#
		.SYNOPSIS
        Retrieve account lockout policy for NSX Local Manager

        .DESCRIPTION
        The Request-NsxtManagerAccountLockout cmdlet retrieves the account lockout policy for each NSX Local Manager node for
        a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Retrieves the account lockpout policy

        .EXAMPLE
        Request-NsxtManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the account lockout policy for the NSX Local Manager nodes in sfo-m01 workload domain

        .EXAMPLE
        Request-NsxtManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the account lockout policy for the NSX Local Manager nodes in sfo-m01 workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the account lockout policy for the NSX Local Manager nodes in sfo-m01 workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxManager.accountLockout
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxManager.accountLockout
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        $nsxtAccountLockoutPolicy = New-Object System.Collections.ArrayList
                        foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                            if (Test-NSXTConnection -server $nsxtManagerNode.fqdn) {
                                if (Test-NSXTAuthentication -server $nsxtManagerNode.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                    if ($NsxtManagerAccountLockout = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn) {
                                        $NsxtManagerAccountLockoutObject = New-Object -TypeName psobject
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "System" -notepropertyvalue $($nsxtManagerNode.fqdn)
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "CLI Max Failures" -notepropertyvalue $(if ($drift) { if ($NsxtManagerAccountLockout.cli_max_auth_failures -ne $requiredConfig.cliMaxFailures) { "$($NsxtManagerAccountLockout.cli_max_auth_failures) [ $($requiredConfig.cliMaxFailures) ]" } else { "$($NsxtManagerAccountLockout.cli_max_auth_failures)" }} else { "$($NsxtManagerAccountLockout.cli_max_auth_failures)" })
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "CLI Unlock Interval (sec)" -notepropertyvalue $(if ($drift) { if ($NsxtManagerAccountLockout.cli_failed_auth_lockout_period -ne $requiredConfig.cliUnlockInterval) { "$($NsxtManagerAccountLockout.cli_failed_auth_lockout_period) [ $($requiredConfig.cliUnlockInterval) ]" } else { "$($NsxtManagerAccountLockout.cli_failed_auth_lockout_period)" }} else { "$($NsxtManagerAccountLockout.cli_failed_auth_lockout_period)" })
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "API Max Failures" -notepropertyvalue $(if ($drift) { if ($NsxtManagerAccountLockout.api_max_auth_failures -ne $requiredConfig.apiMaxFailures) { "$($NsxtManagerAccountLockout.api_max_auth_failures) [ $($requiredConfig.apiMaxFailures) ]" } else { "$($NsxtManagerAccountLockout.api_max_auth_failures)" }} else { "$($NsxtManagerAccountLockout.api_max_auth_failures)" })
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "API Unlock Interval (sec)" -notepropertyvalue $(if ($drift) { if ($NsxtManagerAccountLockout.api_failed_auth_lockout_period -ne $requiredConfig.apiUnlockInterval) { "$($NsxtManagerAccountLockout.api_failed_auth_lockout_period) [ $($requiredConfig.apiUnlockInterval) ]" } else { "$($NsxtManagerAccountLockout.api_failed_auth_lockout_period)" }} else { "$($NsxtManagerAccountLockout.api_failed_auth_lockout_period)" })
                                        $NsxtManagerAccountLockoutObject | Add-Member -notepropertyname "API Reset Interval (sec)" -notepropertyvalue $(if ($drift) { if ($NsxtManagerAccountLockout.api_failed_auth_reset_period -ne $requiredConfig.apiRestInterval) { "$($NsxtManagerAccountLockout.api_failed_auth_reset_period) [ $($requiredConfig.apiRestInterval) ]" } else { "$($NsxtManagerAccountLockout.api_failed_auth_reset_period)" }} else { "$($NsxtManagerAccountLockout.api_failed_auth_reset_period)" })
                                        $nsxtAccountLockoutPolicy += $NsxtManagerAccountLockoutObject
                                    } else {
                                        Write-Error "Unable to retrieve Account Lockout Policy from NSX Local Manager node ($($nsxtManagerNode.fqdn)): PRE_VALIDATION_FAILED"
                                    }
                                }
                            }
                        }
                        return $nsxtAccountLockoutPolicy
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Request-NsxtManagerAccountLockout

Function Update-NsxtManagerPasswordExpiration {
    <#
		.SYNOPSIS
        Configure password expiration policy for NSX Local Manager Users

        .DESCRIPTION
        The Update-NsxtManagerPasswordExpiration cmdlet configures the password expiration policy for NSX Local Manager
        local users for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Configure the password expiration policy

        .EXAMPLE
        Update-NsxtManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -maxdays 999
        This example configures the password expiration policy in NSX Local Manager for all local users in the sfo-m01 workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER maxdays
        The maximum number of days that a password is valid for.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateRange(0,9999)] [Int]$maxDays,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $($vcfNsxDetails.fqdn)) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $localUsers = Get-NsxtApplianceUser
                                foreach ($localUser in $localUsers) {
                                    if ($localUser.password_change_frequency -ne $maxDays) {
                                        Set-NsxtApplianceUserExpirationPolicy -userId $localUser.userid -maxDays $maxDays | Out-Null
                                        $updatedConfiguration = Get-NsxtApplianceUser | Where-Object {$_.userid -eq $localUser.userid }
                                        if (($updatedConfiguration).password_change_frequency -eq $maxDays ) {
                                            if ($detail -eq "true") {
                                                Write-Output "Update Password Expiration Policy on NSX Local Manager ($($vcfNsxDetails.fqdn)) for Local User ($($localUser.username)): SUCCESSFUL"
                                            }
                                        } else {
                                            Write-Error "Update Password Expiration Policy on NSX Local Manager ($($vcfNsxDetails.fqdn)) for Local User ($($localUser.username)): POST_VALIDATION_FAILED"
                                        }
                                    } else {
                                        if ($detail -eq "true") {
                                            Write-Warning "Update Password Expiration Policy on NSX Local Manager ($($vcfNsxDetails.fqdn)) for Local User ($($localUser.username)):, already set: SKIPPED"
                                        }
                                    }
                                }
                                if ($detail -eq "false") {
                                    Write-Output "Update Password Expiration Policy for all NSX Local Manager Local Users in Workload Domain ($domain): SUCCESSFUL"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-NsxtManagerPasswordExpiration

Function Update-NsxtManagerPasswordComplexity {
    <#
		.SYNOPSIS
		Configure the password complexity policy for NSX Local Manager

        .DESCRIPTION
        The Update-NsxtManagerPasswordComplexity cmdlet updates the password complexity policy for each NSX Local Manager
        node for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Updates the password complexity policy

        .EXAMPLE
        Update-NsxtManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 15 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -maxRetry 3 
        This example updates the password complexity policy for each NSX Local Manager node for a workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER minLength
        The minimum length of a password.

        .PARAMETER maxLength
        The maximum length of a password.

        .PARAMETER minLowercase
        The minimum number of lowercase characters in a password.

        .PARAMETER minUppercase
        The minimum number of uppercase characters in a password.

        .PARAMETER minNumerical
        The minimum number of numerical characters in a password.

        .PARAMETER minSpecial
        The minimum number of special characters in a password.

        .PARAMETER minUnique
        The minimum number of unique characters in a password.

        .PARAMETER maxRetry
        The maximum number of retries for a password.

        .PARAMETER maxRepeats
        The maximum number of times a single charecter may be repeated in a password.

        .PARAMETER maxSequence
        The maximum number of monotonic sequence in a password.

        .PARAMETER history
        The maximum number of passwords the system remembers.
        
        .PARAMETER hash_algorithm
        The hash/cryptographic algorithm type for new passwords.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minNumerical,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUnique,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxRetry,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$history,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxRepeats,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxSequence,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [string]$hash_algorithm,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
	)

	Try {
        $chkVersion = $false
        $error_presence = $false
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "MANAGEMENT")) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                                    $chkVersion = ((Get-VCFManager).version -gt "5.0") -and ((Get-VCFNsxtcluster | where-object {$_.vipFqdn -eq $vcfNsxDetails.fqdn}).version -gt "4.0")
                                    foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                                        if (Test-NSXTConnection -server $nsxtManagerNode.fqdn) {
                                            if (Test-NSXTAuthentication -server $nsxtManagerNode.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                                if ($chkVersion) {
                                                    $existingConfiguration = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn
                                                    if (!$PsBoundParameters.ContainsKey("minLength")){
                                                        $minLength = [int]$existingConfiguration.minimum_password_length
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("maxLength")){
                                                        $maxLength = [int]$existingConfiguration.maximum_password_length
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("minNumerical")){
                                                        $minNumerical = [int]$existingConfiguration.digits
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("minLowercase")){
                                                        $minLowercase = [int]$existingConfiguration.lower_chars
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("minUppercase")){
                                                        $minUppercase = [int]$existingConfiguration.upper_chars
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("minSpecial")){
                                                        $minSpecial = [int]$existingConfiguration.special_chars
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("history")){
                                                        $history = [int]$existingConfiguration.password_remembrance
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("minUnique")){
                                                        $minUnique = [int]$existingConfiguration.minimum_unique_chars
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("maxRepeats")){
                                                        $maxRepeats = [int]$existingConfiguration.max_repeats
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("maxSequence")){
                                                        $maxSequence = [int]$existingConfiguration.max_sequence
                                                    }
                                                    if (!$PsBoundParameters.ContainsKey("hash_algorithm")){
                                                        $hash_algorithm = $existingConfiguration.hash_algorithm
                                                    }
                                                    if ($PsBoundParameters.ContainsKey("maxRetry")){
                                                        Write-Warning "'maxRetry' on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain) is not configurable for VCF5.0"
                                                    }                                                                                                    
                                                    if (($existingConfiguration).hash_algorithm -ne $hash_algorithm -or ($existingConfiguration).minimum_password_length -ne $minLength -or ($existingConfiguration).maximum_password_length -ne $maxLength -or ($existingConfiguration).digits -ne $minNumerical -or ($existingConfiguration).lower_chars -ne $minLowercase -or ($existingConfiguration).upper_chars -ne $minUppercase -or ($existingConfiguration).special_chars -ne $minSpecial -or ($existingConfiguration).max_repeats -ne $maxRepeats -or ($existingConfiguration).max_sequence -ne $maxSequence -or ($existingConfiguration).minimum_unique_chars -ne $minUnique -or ($existingConfiguration).password_remembrance -ne $history) {
                                                        Set-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn -hash_algorithm $hash_algorithm -min_passwd_length $minLength -maximum_password_length $maxLength -digits $minNumerical -lower_chars $minLowercase -upper_chars $minUppercase -special_chars $minSpecial -max_repeats $maxRepeats -max_sequence $maxSequence -minimum_unique_chars $minUnique -password_remembrance $history | Out-Null
                                                        $updatedConfiguration = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn
                                                        if (($updatedConfiguration).hash_algorithm -eq $hash_algorithm -and ($updatedConfiguration).minimum_password_length -eq $minLength -and ($updatedConfiguration).maximum_password_length -eq $maxLength -and ($updatedConfiguration).digits -eq $minNumerical -and ($updatedConfiguration).lower_chars -eq $minLowercase -and ($updatedConfiguration).upper_chars -eq $minUppercase -and ($updatedConfiguration).special_chars -eq $minSpecial -and ($updatedConfiguration).max_repeats -eq $maxRepeats -and ($updatedConfiguration).max_sequence -eq $maxSequence -and ($updatedConfiguration).minimum_unique_chars -eq $minUnique -and ($updatedConfiguration).password_remembrance -eq $history) {
                                                            if ($detail -eq "true") {
                                                                Write-Output "Update Password Complexity Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain): SUCCESSFUL"
                                                            }
                                                        } else {
                                                            $error_presence = $true
                                                            Write-Error "Update Password Complexity Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain): POST_VALIDATION_FAILED"
                                                        }
                                                    } else {
                                                        if ($detail -eq "true") {
                                                            Write-Warning "Update Password Complexity Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain):, already set: SKIPPED"
                                                        }
                                                    }
                                                } else {
                                                    if($PsBoundParameters.ContainsKey("maxSequence") -or $PsBoundParameters.ContainsKey("maxRepeats") -or $PsBoundParameters.ContainsKey("history") -or $PsBoundParameters.ContainsKey("maxLength")) {
                                                        Write-Warning "Update for 'maxSequence' or 'maxRepeats' or 'history' or 'maxLength' parameters on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain) is not supported. Requires VMware Cloud Foundation 5.0 or later: SKIPPING"
                                                    }
                                                    $existingConfiguration = Get-LocalPasswordComplexity -vmName ($nsxtManagerNode.fqdn.Split("."))[-0] -guestUser $vcfNsxDetails.rootUser -guestPassword $vcfNsxDetails.rootPass -nsx
                                                    if ($existingConfiguration.'Min Length' -ne $minLength  -or $existingConfiguration.'Min Lowercase' -ne $minLowercase -or $existingConfiguration.'Min Uppercase' -ne $minUppercase -or $existingConfiguration.'Min Numerical' -ne $minNumerical -or $existingConfiguration.'Min Special' -ne $minSpecial -or $existingConfiguration.'Min Unique' -ne $minUnique -or $existingConfiguration.'Max Retries' -ne $maxRetry) {
                                                        Set-LocalPasswordComplexity -vmName ($nsxtManagerNode.fqdn.Split("."))[-0] -guestUser $vcfNsxDetails.rootUser -guestPassword $vcfNsxDetails.rootPass -nsx -minLength $minLength -uppercase $minUppercase -lowercase $minLowercase -numerical $minNumerical -special $minSpecial -unique $minUnique -retry $maxRetry| Out-Null
                                                        $updatedConfiguration = Get-LocalPasswordComplexity -vmName ($nsxtManagerNode.fqdn.Split("."))[-0] -guestUser $vcfNsxDetails.rootUser -guestPassword $vcfNsxDetails.rootPass -nsx
                                                        if ($updatedConfiguration.'Min Length' -eq $minLength -and $updatedConfiguration.'Min Lowercase' -eq $minLowercase -and $updatedConfiguration.'Min Uppercase' -eq $minUppercase -and $updatedConfiguration.'Min Numerical' -eq $minNumerical -and $updatedConfiguration.'Min Special' -eq $minSpecial -and $updatedConfiguration.'Min Unique' -eq $minUnique -and $updatedConfiguration.'Max Retries' -eq $maxRetry) {
                                                            if ($detail -eq "true") {
                                                                Write-Output "Update Password Complexity Policy on NSX Local Manager Node ($($nsxtManagerNode.fqdn)): SUCCESSFUL"
                                                            }
                                                        } else {
                                                            $error_presence = $true
                                                            Write-Error "Update Password Complexity Policy on NSX Local Manager Node ($($nsxtManagerNode.fqdn)): POST_VALIDATION_FAILED"
                                                        }
                                                    } else {
                                                        if ($detail -eq "true") {
                                                            Write-Warning "Update Password Complexity Policy on NSX Local Manager Node ($($nsxtManagerNode.fqdn)), already set: SKIPPED"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (($detail -eq "true") -and ($error_presence-eq $false)) {
                                        Write-Output "Update Password Complexity Policy for all NSX Local Manager Nodes in Workload Domain ($domain): SUCCESSFUL"
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-NsxtManagerPasswordComplexity

Function Update-NsxtManagerAccountLockout {
    <#
		.SYNOPSIS
        Configure account lockout policy for NSX Local Manager

        .DESCRIPTION
        The Update-NsxtManagerAccountLockout cmdlet configures the account lockout policy for NSX Local Manager nodes within
        a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Configure the account lockout policy

        .EXAMPLE
        Update-NsxtManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cliFailures 5 -cliUnlockInterval 900 -apiFailures 5 -apiFailureInterval 120 -apiUnlockInterval 900
        This example configures the account lockout policy in NSX Local Manager nodes in the sfo-m01 workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER cliFailures
        The number of failed login attempts before the account is locked out for the CLI.

        .PARAMETER cliUnlockInterval
        The number of seconds before the account is unlocked for the CLI.

        .PARAMETER apiFailures
        The number of failed login attempts before the account is locked out for the API.

        .PARAMETER apiFailureInterval
        The number of seconds before the account is unlocked for the API.

        .PARAMETER apiUnlockInterval
        The number of seconds before the account is unlocked for the API.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$cliFailures,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$cliUnlockInterval,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$apiFailures,
		[Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$apiFailureInterval,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$apiUnlockInterval,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                                    if (Test-NSXTAuthentication -server $nsxtManagerNode.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.AdminPass) {
                                        $existingConfiguration = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn
                                        if (($existingConfiguration).cli_max_auth_failures -ne $cliFailures -or ($existingConfiguration).cli_failed_auth_lockout_period -ne $cliUnlockInterval -or ($existingConfiguration).api_max_auth_failures -ne $apiFailures -or ($existingConfiguration).api_failed_auth_reset_period -ne $apiFailureInterval -or ($existingConfiguration).api_failed_auth_lockout_period -ne $apiUnlockInterval ) {
                                            if (!$PsBoundParameters.ContainsKey("cliFailures")){
                                                $cliFailures = [int]$existingConfiguration.cli_max_auth_failures
                                            }
                                            if (!$PsBoundParameters.ContainsKey("cliUnlockInterval")){
                                                $cliUnlockInterval = [int]$existingConfiguration.cli_failed_auth_lockout_period
                                            }
                                            if (!$PsBoundParameters.ContainsKey("apiFailures")){
                                                $apiFailures = [int]$existingConfiguration.api_max_auth_failures
                                            }
                                            if (!$PsBoundParameters.ContainsKey("apiFailureInterval")){
                                                $apiFailureInterval = [int]$existingConfiguration.api_failed_auth_reset_period
                                            }
                                            if (!$PsBoundParameters.ContainsKey("apiUnlockInterval")){
                                                $apiUnlockInterval = [int]$existingConfiguration.api_failed_auth_lockout_period
                                            }
                                            Set-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn -cli_max_attempt $cliFailures -cli_lockout_period $cliUnlockInterval -api_max_attempt $apiFailures -api_reset_period $apiFailureInterval -api_lockout_period $apiUnlockInterval | Out-Null
                                            $updatedConfiguration = Get-NsxtManagerAuthPolicy -nsxtManagerNode $nsxtManagerNode.fqdn
                                            if (($updatedConfiguration).cli_max_auth_failures -eq $cliFailures -and ($updatedConfiguration).cli_failed_auth_lockout_period -eq $cliUnlockInterval -and ($updatedConfiguration).api_max_auth_failures -eq $apiFailures -and ($updatedConfiguration).api_failed_auth_reset_period -eq $apiFailureInterval -and ($updatedConfiguration).api_failed_auth_lockout_period -eq $apiUnlockInterval ) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Account Lockout Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Account Lockout Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Account Lockout Policy on NSX Local Manager ($($nsxtManagerNode.fqdn)) for Workload Domain ($domain):, already set: SKIPPED"
                                            }
                                        }
                                    }
                                }
                                if ($detail -eq "false") {
                                    Write-Output "Update Account Lockout Policy for all NSX Local Manager Nodes in Workload Domain ($domain): SUCCESSFUL"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-NsxtManagerAccountLockout

Function Publish-NsxManagerPasswordExpiration {
    <#
        .SYNOPSIS
        Publish password expiration policy for NSX Local Manager.

        .DESCRIPTION
        The Publish-NsxManagerPasswordExpiration cmdlet returns password expiration policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password expiration policy for each local user of NSX Local Manager

        .EXAMPLE
        Publish-NsxManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password expiration policy for each local user of NSX Local Manager for all Workload Domains

        .EXAMPLE
        Publish-NsxManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password expiration policy for each local user of NSX Local Manager for a Workload Domain

        .EXAMPLE
        Publish-NsxManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for each local user of NSX Local Manager for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxManagerPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password expiration policy for each local user of NSX Local Manager for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxManagerPasswordExpirationObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $workloadDomain -listNodes)) {
                        # foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                            $command = "Request-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                            $nsxPasswordExpiration = Invoke-Expression $command ; $nsxManagerPasswordExpirationObject += $nsxPasswordExpiration
                        # }
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain.name -listNodes)) {
                            # foreach ($nsxtManagerNode in $vcfNsxDetails.nodes) {
                                $command = "Request-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                                $nsxPasswordExpiration = Invoke-Expression $command ; $nsxManagerPasswordExpirationObject += $nsxPasswordExpiration
                            # }
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxManagerPasswordExpirationObject
                } else {
                    $nsxManagerPasswordExpirationObject = $nsxManagerPasswordExpirationObject | Sort-Object 'Workload Domain', 'System', 'User' | ConvertTo-Html -Fragment -PreContent '<a id="nsxmanager-password-expiration"></a><h3>NSX Manager - Password Expiration</h3>' -As Table
                    $nsxManagerPasswordExpirationObject = Convert-CssClassStyle -htmldata $nsxManagerPasswordExpirationObject
                    $nsxManagerPasswordExpirationObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxManagerPasswordExpiration

Function Publish-NsxManagerPasswordComplexity {
    <#
        .SYNOPSIS
        Publish password complexity policy for NSX Local Manager.

        .DESCRIPTION
        The Publish-NsxManagerPasswordComplexity cmdlet returns password complexity policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password complexity policy for each NSX Local Manager

        .EXAMPLE
        Publish-NsxManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password complexity policy for each NSX Local Manager for all Workload Domains

        .EXAMPLE
        Publish-NsxManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password complexity policy for each NSX Local Manager for a Workload Domain

        .EXAMPLE
        Publish-NsxManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password complexity policy of NSX Local Manager for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxManagerPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains -drift
        This example will return password complexity policy of NSX Local Manager for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxManagerPasswordComplexityObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $nsxPasswordComplexity = Invoke-Expression $command ; $nsxManagerPasswordComplexityObject += $nsxPasswordComplexity
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $nsxPasswordComplexity = Invoke-Expression $command ; $nsxManagerPasswordComplexityObject += $nsxPasswordComplexity
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxManagerPasswordComplexityObject
                } else {
                    $nsxManagerPasswordComplexityObject = $nsxManagerPasswordComplexityObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="nsxmanager-password-complexity"></a><h3>NSX Manager - Password Complexity</h3>' -As Table
                    $nsxManagerPasswordComplexityObject = Convert-CssClassStyle -htmldata $nsxManagerPasswordComplexityObject
                    $nsxManagerPasswordComplexityObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxManagerPasswordComplexity

Function Publish-NsxManagerAccountLockout {
    <#
        .SYNOPSIS
        Publish account lockout policy for NSX Local Manager.

        .DESCRIPTION
        The Publish-NsxManagerAccountLockout cmdlet returns account lockout policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects account lockout policy for each NSX Local Manager

        .EXAMPLE
        Publish-NsxManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return account lockout policy for each NSX Local Manager for all Workload Domains

        .EXAMPLE
        Publish-NsxManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return account lockout policy for each NSX Local Manager for a Workload Domain

        .EXAMPLE
        Publish-NsxManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return account lockout policy for each NSX Local Manager for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxManagerAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return account lockout policy for each NSX Local Manager for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxManagerAccountLockoutObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $nsxAccountLockout = Invoke-Expression $command ; $nsxManagerAccountLockoutObject += $nsxAccountLockout
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $nsxAccountLockout = Invoke-Expression $command ; $nsxManagerAccountLockoutObject += $nsxAccountLockout
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxManagerAccountLockoutObject
                } else {
                    $nsxManagerAccountLockoutObject = $nsxManagerAccountLockoutObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="nsxmanager-account-lockout"></a><h3>NSX Manager - Account Lockout</h3>' -As Table
                    $nsxManagerAccountLockoutObject = Convert-CssClassStyle -htmldata $nsxManagerAccountLockoutObject
                    $nsxManagerAccountLockoutObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxManagerAccountLockout

#EndRegion  End NSX Manager Password Management Functions           ######
##########################################################################

##########################################################################
#Region     Begin NSX Edge Password Management Function             ######

Function Request-NsxtEdgePasswordExpiration {
    <#
		.SYNOPSIS
		Retrieve the password expiration policy for NSX Edge Users

        .DESCRIPTION
        The Request-NsxtEdgePasswordExpiration cmdlet retrieves the password complexity policy for all NSX Edge users
        for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and
        -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Retrieves the password expiration policy for all users

        .EXAMPLE
        Request-NsxtEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password expiration policy for all users for the NSX Edge for a workload domain

        .EXAMPLE
        Request-NsxtEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password expiration policy for all users for the NSX Edge for a workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieves the password expiration policy for all users for the NSX Edge for a workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxManager.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxManager.passwordExpiration
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $($vcfNsxDetails.fqdn)) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $allNsxEdgePasswordExpirationPolicy = New-Object System.Collections.ArrayList
                                $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                    $localUsers = Get-NsxtApplianceUser
                                    foreach ($localUser in $localUsers) {
                                        $nsxEdgePasswordExpirationPolicy = New-Object -TypeName psobject
                                        $nsxEdgePasswordExpirationPolicy | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                        $nsxEdgePasswordExpirationPolicy | Add-Member -notepropertyname "System" -notepropertyvalue $nsxtEdgeNode.display_name
                                        $nsxEdgePasswordExpirationPolicy | Add-Member -notepropertyname "User" -notepropertyvalue $($localUser.username)
                                        $nsxEdgePasswordExpirationPolicy | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($localUser.password_change_frequency -ne $requiredConfig.maxDays) { "$($localUser.password_change_frequency) [ $($requiredConfig.maxDays) ]" } else { "$($localUser.password_change_frequency)" }} else { "$($localUser.password_change_frequency)" })
                                        $allNsxEdgePasswordExpirationPolicy += $nsxEdgePasswordExpirationPolicy
                                    }
                                }
                                Return $allNsxEdgePasswordExpirationPolicy
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Request-NsxtEdgePasswordExpiration

Function Request-NsxtEdgePasswordComplexity {
    <#
		.SYNOPSIS
		Retrieve the password complexity policy for NSX Edge

        .DESCRIPTION
        The Request-NsxtEdgePasswordComplexity cmdlet retrieves the password complexity policy for each NSX Edge
        nodes for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Retrieves the password complexity policy

        .EXAMPLE
        Request-NsxtEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password complexity policy for each NSX Edge node for a workload domain

        .EXAMPLE
        Request-NsxtEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for each NSX Edge node for a workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieves the password complexity policy for each NSX Edge node for a workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxEdge.passwordComplexity
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxEdge.passwordComplexity
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                                    if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                                        if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                            $nsxtPasswordComplexityPolicy = New-Object System.Collections.ArrayList
                                            $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                            foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                                $nsxEdgeRootPass = (Get-VCFCredential | Where-Object {$_.resource.resourceName -eq ($nsxtEdgeNode.display_name + '.' + $vcfNsxDetails.fqdn.Split('.',2)[-1]) -and $_.username -eq "root"}).password
                                                if ($nsxtEdgeNodePolicy = Get-LocalPasswordComplexity -vmName $($nsxtEdgeNode.display_name) -guestUser root -guestPassword $nsxEdgeRootPass -nsx ) {
                                                    $NsxtEdgePasswordComplexityObject = New-Object -TypeName psobject
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "System" -notepropertyvalue $nsxtEdgeNode.display_name
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Length" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Length' -ne $requiredConfig.minLength) { "$($nsxtEdgeNodePolicy.'Min Length') [ $($requiredConfig.minLength) ]" } else { "$($nsxtEdgeNodePolicy.'Min Length')" }} else { "$($nsxtEdgeNodePolicy.'Min Length')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Lowercase" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Lowercase' -ne $requiredConfig.minLowercase) { "$($nsxtEdgeNodePolicy.'Min Lowercase') [ $($requiredConfig.minLowercase) ]" } else { "$($nsxtEdgeNodePolicy.'Min Lowercase')" }} else { "$($nsxtEdgeNodePolicy.'Min Lowercase')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Uppercase" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Uppercase' -ne $requiredConfig.minUppercase) { "$($nsxtEdgeNodePolicy.'Min Uppercase') [ $($requiredConfig.minUppercase) ]" } else { "$($nsxtEdgeNodePolicy.'Min Uppercase')" }} else { "$($nsxtEdgeNodePolicy.'Min Uppercase')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Numerical" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Numerical' -ne $requiredConfig.minNumerical) { "$($nsxtEdgeNodePolicy.'Min Numerical') [ $($requiredConfig.minNumerical) ]" } else { "$($nsxtEdgeNodePolicy.'Min Numerical')" }} else { "$($nsxtEdgeNodePolicy.'Min Numerical')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Special" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Special' -ne $requiredConfig.minSpecial) { "$($nsxtEdgeNodePolicy.'Min Special') [ $($requiredConfig.minSpecial) ]" } else { "$($nsxtEdgeNodePolicy.'Min Special')" }} else { "$($nsxtEdgeNodePolicy.'Min Special')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Min Unique" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Min Unique' -ne $requiredConfig.minUnique) { "$($nsxtEdgeNodePolicy.'Min Unique') [ $($requiredConfig.minUnique) ]" } else { "$($nsxtEdgeNodePolicy.'Min Unique')" }} else { "$($nsxtEdgeNodePolicy.'Min Unique')" })
                                                    $NsxtEdgePasswordComplexityObject | Add-Member -notepropertyname "Max Retries" -notepropertyvalue $(if ($drift) { if ($nsxtEdgeNodePolicy.'Max Retries' -ne $requiredConfig.retries) { "$($nsxtEdgeNodePolicy.'Max Retries') [ $($requiredConfig.retries) ]" } else { "$($nsxtEdgeNodePolicy.'Max Retries')" }} else { "$($nsxtEdgeNodePolicy.'Max Retries')" })
                                                    $nsxtPasswordComplexityPolicy += $NsxtEdgePasswordComplexityObject
                                                } else {
                                                    Write-Error "Unable to retrieve Password Complexity Policy from NSX Edge node ($($nsxtEdgeNode.display_name)): PRE_VALIDATION_FAILED"
                                                }
                                            }
                                        }
                                    }
                                    return $nsxtPasswordComplexityPolicy
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-NsxtEdgePasswordComplexity

Function Request-NsxtEdgeAccountLockout {
    <#
		.SYNOPSIS
        Retrieve account lockout policy from NSX Edge

        .DESCRIPTION
        The Request-NsxtEdgeAccountLockout cmdlet retrieves the account lockout policy from NSX Edge nodes within a
        workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Retrieves the account lockout policy

        .EXAMPLE
        Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01
        This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain

        .EXAMPLE
        Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -drift
        This example retrieving the account lockout policy for NSX Edge nodes in sfo-m01 workload domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
    )



    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).nsxEdge.accountLockout
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).nsxEdge.accountLockout
                    }
                }
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $nsxtAccountLockoutPolicy = New-Object System.Collections.ArrayList
                                $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                    if ($NsxtEdgeAccountLockout = Get-NsxtEdgeNodeAuthPolicy -nsxtManager $vcfNsxDetails.fqdn -nsxtEdgeNodeID $nsxtEdgeNode.transport_node_id) {
                                        $NsxtEdgeAccountLockoutObject = New-Object -TypeName psobject
                                        $NsxtEdgeAccountLockoutObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                        $NsxtEdgeAccountLockoutObject | Add-Member -notepropertyname "System" -notepropertyvalue $nsxtEdgeNode.display_name
                                        $NsxtEdgeAccountLockoutObject | Add-Member -notepropertyname "CLI Max Failures" -notepropertyvalue $(if ($drift) { if ($NsxtEdgeAccountLockout.cli_max_auth_failures -ne $requiredConfig.cliMaxFailures) { "$($NsxtEdgeAccountLockout.cli_max_auth_failures) [ $($requiredConfig.cliMaxFailures) ]" } else { "$($NsxtEdgeAccountLockout.cli_max_auth_failures)" }} else { "$($NsxtEdgeAccountLockout.cli_max_auth_failures)" })
                                        $NsxtEdgeAccountLockoutObject | Add-Member -notepropertyname "CLI Unlock Interval (sec)" -notepropertyvalue $(if ($drift) { if ($NsxtEdgeAccountLockout.cli_failed_auth_lockout_period -ne $requiredConfig.cliUnlockInterval) { "$($NsxtEdgeAccountLockout.cli_failed_auth_lockout_period) [ $($requiredConfig.cliUnlockInterval) ]" } else { "$($NsxtEdgeAccountLockout.cli_failed_auth_lockout_period)" }} else { "$($NsxtEdgeAccountLockout.cli_failed_auth_lockout_period)" })
                                        $nsxtAccountLockoutPolicy += $NsxtEdgeAccountLockoutObject
                                    } else {
                                        Write-Error "Unable to retrieve Account Lockout Policy from NSX Edge node ($($nsxtEdgeNode.display_name)): PRE_VALIDATION_FAILED"
                                    }
                                }
                                return $nsxtAccountLockoutPolicy
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Request-NsxtEdgeAccountLockout

Function Update-NsxtEdgePasswordExpiration {
    <#
		.SYNOPSIS
        Configure password expiration policy for NSX Edge Local Users

        .DESCRIPTION
        The Update-NsxtEdgePasswordExpiration cmdlet configures the password expiration policy for NSX Edge local users
        for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Configure the password expiration policy

        .EXAMPLE
        Update-NsxtEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -maxdays 999
        This example configures the password expiration policy in NSX Edge for all local users in the sfo-m01 workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER maxDays
        The maximum number of days before the password expires.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateRange(0,9999)] [Int]$maxDays,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $($vcfNsxDetails.fqdn)) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                    $localUsers = Get-NsxtApplianceUser
                                    foreach ($localUser in $localUsers) {
                                        if ($localUser.password_change_frequency -ne $maxDays) {
                                            Set-NsxtApplianceUserExpirationPolicy -userId $localUser.userid -maxDays $maxDays | Out-Null
                                            $updatedConfiguration = Get-NsxtApplianceUser | Where-Object {$_.userid -eq $localUser.userid }
                                            if (($updatedConfiguration).password_change_frequency -eq $maxDays ) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Password Expiration Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Local User ($($localUser.username)): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Password Expiration Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Local User ($($localUser.username)): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Password Expiration Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Local User ($($localUser.username)):, already set: SKIPPED"
                                            }
                                        }
                                    }
                                }
                                if ($detail -eq "false") {
                                    Write-Output "Update Password Expiration Policy for all NSX Edge Local Users in Workload Domain ($domain): SUCCESSFUL"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-NsxtEdgePasswordExpiration

Function Update-NsxtEdgePasswordComplexity {
    <#
		.SYNOPSIS
		Configure the password complexity policy for NSX Edge

        .DESCRIPTION
        The Update-NsxtEdgePasswordComplexity cmdlet updates the password complexity policy for each NSX Edge
        node for a workload domain. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
		- Updates the password complexity policy

        .EXAMPLE
        Update-NsxtEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -minLength 15 -minLowercase -1 -minUppercase -1  -minNumerical -1 -minSpecial -1 -minUnique 4 -maxRetry 3
        This example updates the password complexity policy for each NSX Edge node for a workload domain

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER minLength
        The minimum length of the password.

        .PARAMETER minLowercase
        The minimum number of lowercase characters in the password.

        .PARAMETER minUppercase
        The minimum number of uppercase characters in the password.

        .PARAMETER minNumerical
        The minimum number of numerical characters in the password.

        .PARAMETER minSpecial
        The minimum number of special characters in the password.

        .PARAMETER minUnique
        The minimum number of unique characters in the password.

        .PARAMETER maxRetry
        The maximum number of retries before the account is locked.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minNumerical,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$minUnique,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxRetry,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                                    if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                                        if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                            $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                            foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                                $nsxEdgeRootPass = (Get-VCFCredential | Where-Object {$_.resource.resourceName -eq ($nsxtEdgeNode.display_name + '.' + $vcfNsxDetails.fqdn.Split('.',2)[-1]) -and $_.username -eq "root"}).password
                                                $existingConfiguration = Get-LocalPasswordComplexity -vmName $($nsxtEdgeNode.display_name) -guestUser root -guestPassword $nsxEdgeRootPass -nsx
                                                if ($existingConfiguration.'Min Length' -ne $minLength  -or $existingConfiguration.'Min Lowercase' -ne $minLowercase -or $existingConfiguration.'Min Uppercase' -ne $minUppercase -or $existingConfiguration.'Min Numerical' -ne $minNumerical -or $existingConfiguration.'Min Special' -ne $minSpecial -or $existingConfiguration.'Min Unique' -ne $minUnique -or $existingConfiguration.'Max Retries' -ne $maxRetry) {
                                                    Set-LocalPasswordComplexity -vmName $nsxtEdgeNode.display_name -guestUser root -guestPassword $nsxEdgeRootPass -nsx -minLength $minLength -uppercase $minUppercase -lowercase $minLowercase -numerical $minNumerical -special $minSpecial -unique $minUnique -retry $maxRetry| Out-Null
                                                    $updatedConfiguration = Get-LocalPasswordComplexity -vmName $nsxtEdgeNode.display_name -guestUser root -guestPassword $nsxEdgeRootPass -nsx
                                                    if ($updatedConfiguration.'Min Length' -eq $minLength -and $updatedConfiguration.'Min Lowercase' -eq $minLowercase -and $updatedConfiguration.'Min Uppercase' -eq $minUppercase -and $updatedConfiguration.'Min Numerical' -eq $minNumerical -and $updatedConfiguration.'Min Special' -eq $minSpecial -and $updatedConfiguration.'Min Unique' -eq $minUnique -and $updatedConfiguration.'Max Retries' -eq $maxRetry) {
                                                        if ($detail -eq "true") {
                                                            Write-Output "Update Password Complexity Policy on NSX Edge Node ($($nsxtEdgeNode.display_name)): SUCCESSFUL"
                                                        }
                                                    } else {
                                                        Write-Error "Update Password Complexity Policy on NSX Edge Node ($($nsxtEdgeNode.display_name)): POST_VALIDATION_FAILED"
                                                    }
                                                } else {
                                                    if ($detail -eq "true") {
                                                        Write-Warning "Update Password Complexity Policy on NSX Edge Node ($($nsxtEdgeNode.display_name)), already set: SKIPPED"
                                                    }
                                                }
                                            }
                                            if ($detail -eq "false") {
                                                Write-Output "Update Password Complexity for all NSX Edge Nodes in Workload Domain ($domain): SUCCESSFUL"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-NsxtEdgePasswordComplexity

Function Update-NsxtEdgeAccountLockout {
    <#
		.SYNOPSIS
        Configure account lockout policy for NSX Edge

        .DESCRIPTION
        The Update-NsxtEdgeAccountLockout cmdlet configures the account lockout policy for NSX Edge nodes.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to NSX Local Manager
        - Configure the account lockout policy

        .EXAMPLE
        Update-NsxtEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cliFailures 5 -cliUnlockInterval 900
        This example configures the account lockout policy of the NSX Edges nodes in sfo-m01 workload domain

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER cliFailures
        The number of failed login attempts before the account is locked for the CLI

        .PARAMETER cliUnlockInterval
        The number of seconds before the account is unlocked for the CLI.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$cliFailures,
        [Parameter (Mandatory = $false)] [ValidateRange(1, [int]::MaxValue)] [int]$cliUnlockInterval,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain -listNodes)) {
                        if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                    $existingConfiguration = Get-NsxtEdgeNodeAuthPolicy -nsxtManager $vcfNsxDetails.fqdn -nsxtEdgeNodeID $nsxtEdgeNode.transport_node_id
                                    if (($existingConfiguration).cli_max_auth_failures -ne $cliFailures -or ($existingConfiguration).cli_failed_auth_lockout_period -ne $cliUnlockInterval) {
                                        if (!$PsBoundParameters.ContainsKey("cliFailures")){
                                            $cliFailures = [int]$existingConfiguration.cli_max_auth_failures
                                        }
                                        if (!$PsBoundParameters.ContainsKey("cliUnlockInterval")){
                                            $cliUnlockInterval = [int]$existingConfiguration.cli_failed_auth_lockout_period
                                        }
                                        Set-NsxtEdgeNodeAuthPolicy -nsxtManager $vcfNsxDetails.fqdn -nsxtEdgeNodeID $nsxtEdgeNode.transport_node_id -cli_max_attempt $cliFailures -cli_lockout_period $cliUnlockInterval | Out-Null
                                        $updatedConfiguration = Get-NsxtEdgeNodeAuthPolicy -nsxtManager $vcfNsxDetails.fqdn -nsxtEdgeNodeID $nsxtEdgeNode.transport_node_id
                                        if (($updatedConfiguration).cli_max_auth_failures -eq $cliFailures -and ($updatedConfiguration).cli_failed_auth_lockout_period -eq $cliUnlockInterval) {
                                            if ($detail -eq "true") {
                                                Write-Output "Update Account Lockout Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Workload Domain ($domain): SUCCESSFUL"
                                            }
                                        } else {
                                            Write-Error "Update Account Lockout Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Workload Domain ($domain): POST_VALIDATION_FAILED"
                                        }
                                    } else {
                                        if ($detail -eq "true") {
                                            Write-Warning "Update Account Lockout Policy on NSX Edge ($($nsxtEdgeNode.display_name)) for Workload Domain ($domain):, already set: SKIPPED"
                                        }
                                    }

                                }
                                if ($detail -eq "false") {
                                    Write-Output "Update Account Lockout Policy for all NSX Edge Nodes in Workload Domain ($domain): SUCCESSFUL"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-NsxtEdgeAccountLockout

Function Publish-NsxEdgePasswordExpiration {
    <#
        .SYNOPSIS
        Publish password expiration policy for NSX Edge.

        .DESCRIPTION
        The Publish-NsxEdgePasswordExpiration cmdlet returns password expiration policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password expiration policy for each local user of NSX Edge

        .EXAMPLE
        Publish-NsxEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password expiration policy for each local user of NSX Edge nodes for all Workload Domains

        .EXAMPLE
        Publish-NsxEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password expiration policy for each local user of NSX Edge nodes for a Workload Domain

        .EXAMPLE
        Publish-NsxEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for each local user of NSX Edge nodes for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxEdgePasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password expiration policy for each local user of NSX Edge nodes for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxEdgePasswordExpirationObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $workloadDomain)) {
                        if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                            if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                # $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                # foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                    $command = "Request-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                                    $nsxEdgePasswordExpiration = Invoke-Expression $command ;  $nsxEdgePasswordExpirationObject += $nsxEdgePasswordExpiration
                                # }
                            }
                        }
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if (($vcfNsxDetails = Get-NsxtServerDetail -fqdn $server -username $user -password $pass -domain $domain.name)) {
                            if (Test-NSXTConnection -server $vcfNsxDetails.fqdn) {
                                if (Test-NSXTAuthentication -server $vcfNsxDetails.fqdn -user $vcfNsxDetails.adminUser -pass $vcfNsxDetails.adminPass) {
                                    # $nsxtEdgeNodes = (Get-NsxtEdgeCluster | Where-Object {$_.member_node_type -eq "EDGE_NODE"})
                                    # foreach ($nsxtEdgeNode in $nsxtEdgeNodes.members) {
                                        $command = "Request-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                                        $nsxEdgePasswordExpiration = Invoke-Expression $command ;  $nsxEdgePasswordExpirationObject += $nsxEdgePasswordExpiration
                                    # }
                                }
                            }
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxEdgePasswordExpirationObject
                } else {
                    $nsxEdgePasswordExpirationObject = $nsxEdgePasswordExpirationObject | Sort-Object 'Workload Domain', 'System', 'User' | ConvertTo-Html -Fragment -PreContent '<a id="nsxedge-password-expiration"></a><h3>NSX Edge - Password Expiration</h3>' -As Table
                    $nsxEdgePasswordExpirationObject = Convert-CssClassStyle -htmldata $nsxEdgePasswordExpirationObject
                    $nsxEdgePasswordExpirationObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxEdgePasswordExpiration

Function Publish-NsxEdgePasswordComplexity {
    <#
        .SYNOPSIS
        Publish password complexity policy for NSX Edge.

        .DESCRIPTION
        The Publish-NsxEdgePasswordComplexity cmdlet returns password complexity policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects password complexity policy for each local user of NSX Edge

        .EXAMPLE
        Publish-NsxEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return password complexity policy for each local user of NSX Edge nodes for all Workload Domains

        .EXAMPLE
        Publish-NsxEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return password complexity policy for each local user of NSX Edge nodes for a Workload Domain

        .EXAMPLE
        Publish-NsxEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password complexity policy for each local user of NSX Edge nodes for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxEdgePasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return password complexity policy for each local user of NSX Edge nodes for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxEdgePasswordComplexityObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $nsxEdgePasswordComplexity = Invoke-Expression $command ;  $nsxEdgePasswordComplexityObject += $nsxEdgePasswordComplexity
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $nsxEdgePasswordComplexity = Invoke-Expression $command ;  $nsxEdgePasswordComplexityObject += $nsxEdgePasswordComplexity
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxEdgePasswordComplexityObject
                } else {
                    $nsxEdgePasswordComplexityObject = $nsxEdgePasswordComplexityObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="nsxedge-password-complexity"></a><h3>NSX Edge - Password Complexity</h3>' -As Table
                    $nsxEdgePasswordComplexityObject = Convert-CssClassStyle -htmldata $nsxEdgePasswordComplexityObject
                    $nsxEdgePasswordComplexityObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxEdgePasswordComplexity

Function Publish-NsxEdgeAccountLockout {
    <#
        .SYNOPSIS
        Publish account lockout policy for NSX Edge.

        .DESCRIPTION
        The Publish-NsxEdgeAccountLockout cmdlet returns account lockout policy for local users of NSX Local
        Manager. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Collects account lockout policy for NSX Edge node

        .EXAMPLE
        Publish-NsxEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -allDomains
        This example will return account lockout policy for each NSX Edge nodes for all Workload Domains

        .EXAMPLE
        Publish-NsxEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01
        This example will return account lockout policy for each NSX Edge nodes for a Workload Domain

        .EXAMPLE
        Publish-NsxEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return account lockout policy for each NSX Edge nodes for a Workload Domain and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-NsxEdgeAccountLockout -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -workloadDomain sfo-w01 -drift
        This example will return account lockout policy for each NSX Edge nodes for a Workload Domain and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $nsxEdgeAccountLockoutObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    $command = "Request-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $workloadDomain" + $commandSwitch
                    $nsxEdgeAccountLockout = Invoke-Expression $command ;  $nsxEdgeAccountLockoutObject += $nsxEdgeAccountLockout
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        $command = "Request-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $($domain.name)" + $commandSwitch
                        $nsxEdgeAccountLockout = Invoke-Expression $command ;  $nsxEdgeAccountLockoutObject += $nsxEdgeAccountLockout
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $nsxEdgeAccountLockoutObject
                } else {
                    $nsxEdgeAccountLockoutObject = $nsxEdgeAccountLockoutObject | Sort-Object 'Workload Domain', 'System' | ConvertTo-Html -Fragment -PreContent '<a id="nsxedge-account-lockout"></a><h3>NSX Edge - Account Lockout</h3>' -As Table
                    $nsxEdgeAccountLockoutObject = Convert-CssClassStyle -htmldata $nsxEdgeAccountLockoutObject
                    $nsxEdgeAccountLockoutObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-NsxEdgeAccountLockout

#EndRegion  End NSX Edge Password Management Functions              ######
##########################################################################

##########################################################################
#Region     Begin ESXi Password Management Functions                ######

Function Request-EsxiPasswordExpiration {
	<#
        .SYNOPSIS
        Retrieves ESXi host password expiration

        .DESCRIPTION
        The Request-EsxiPasswordExpiration cmdlet retrieves a list of ESXi hosts for a cluster displaying the currently
        configured password expiration policy (Advanced Setting Security.PasswordMaxDays). The cmdlet connects to SDDC
        Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Retrieve all ESXi hosts password expiration policy

        .EXAMPLE
        Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01
        This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01

        .EXAMPLE
        Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift
        This example retrieves all ESXi hosts password expiration policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER cluster
        The name of the cluster to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).esxi.passwordExpiration
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).esxi.passwordExpiration
                    }
                }
				if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
							if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
								if (Get-Cluster | Where-Object {$_.Name -eq $cluster}) {
                                    $esxiPasswdPolicy = New-Object System.Collections.Generic.List[System.Object]
									$esxiHosts = Get-Cluster $cluster | Get-VMHost | Sort-Object -Property Name
									if ($esxiHosts) {
										Foreach ($esxiHost in $esxiHosts) {
											$passwordExpire = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"} | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordMaxDays" }
											if ($passwordExpire) {
												$nodePasswdPolicy = New-Object -TypeName psobject
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Cluster" -notepropertyvalue $cluster
                                                $nodePasswdPolicy | Add-Member -notepropertyname "System" -notepropertyvalue $esxiHost.Name
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($passwordExpire.Value -ne $requiredConfig.maxdays) { "$($passwordExpire.Value) [ $($requiredConfig.maxdays) ]" } else { "$($passwordExpire.Value)" }} else { "$($passwordExpire.Value)" })
                                                $esxiPasswdPolicy.Add($nodePasswdPolicy)
												Remove-Variable -Name nodePasswdPolicy
											} else {
												Write-Error "Unable to retrieve password expiration policy from ESXi host ($esxiHost.Name): PRE_VALIDATION_FAILED"
											}
										}
										return $esxiPasswdPolicy
									} else {
										Write-Warning "No ESXi hosts found within cluster named ($cluster): PRE_VALIDATION_FAILED"
									}
								} else {
                                    Write-Error "Unable to locate Cluster ($cluster) in vCenter Server ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
								}
							}
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-EsxiPasswordExpiration

Function Request-EsxiPasswordComplexity {
	<#
        .SYNOPSIS
        Retrieves ESXi host password complexity

        .DESCRIPTION
        The Request-EsxiPasswordComplexity cmdlet retrieves a list of ESXi hosts for a cluster displaying the currently
        configured password complexity policy (Advanced Settings Security.PasswordHistory and
        Security.PasswordQualityControl). The cmdlet connects to SDDC Manager using the -server, -user, and -password
        values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Retrieve all ESXi hosts password complexity policy

        .EXAMPLE
        Request-EsxiPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01
        This example retrieves all ESXi hosts password complexity policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01

        .EXAMPLE
        Request-EsxiPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves all ESXi hosts password complexity policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-EsxiPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift
        This example retrieves all ESXi hosts password complexity policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER cluster
        The name of the cluster to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).esxi.passwordComplexity
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).esxi.passwordComplexity
                    }
                }
				if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
							if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
								if (Get-Cluster | Where-Object {$_.Name -eq $cluster}) {
                                    $esxiPasswdPolicy = New-Object System.Collections.Generic.List[System.Object]
									$esxiHosts = Get-Cluster $cluster | Get-VMHost | Sort-Object -Property Name
									if ($esxiHosts) {
										Foreach ($esxiHost in $esxiHosts) {
											# retreving ESXi Advanced Setting: Security.PasswordHistory
											$passwordHistory = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"} | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordHistory" }
											# retreving ESXi Advanced Setting: Security.PasswordQualityControl
											$passwordQualityControl = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"} | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordQualityControl" }
											if ($passwordHistory -and $passwordQualityControl) {
												$nodePasswdPolicy = New-Object -TypeName psobject
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Cluster" -notepropertyvalue $cluster
												$nodePasswdPolicy | Add-Member -notepropertyname "System" -notepropertyvalue $esxiHost.Name
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Policy" -notepropertyvalue $(if ($drift) { if ($passwordQualityControl.value -ne $requiredConfig.policy) { "$($passwordQualityControl.value) [ $($requiredConfig.policy) ]" } else { "$($passwordQualityControl.value)" }} else { "$($passwordQualityControl.value)" })
												$nodePasswdPolicy | Add-Member -notepropertyname "History" -notepropertyvalue $(if ($drift) { if ($passwordHistory.Value -ne $requiredConfig.history) { "$($passwordHistory.Value) [ $($requiredConfig.history) ]" } else { "$($passwordHistory.Value)" }} else { "$($passwordHistory.Value)" })
                                                $esxiPasswdPolicy.Add($nodePasswdPolicy)
												Remove-Variable -Name nodePasswdPolicy
											} else {
												Write-Error "Unable to retrieve password complexity policy from ESXi host ($esxiHost.Name): PRE_VALIDATION_FAILED"
											}
										}
										return $esxiPasswdPolicy
									} else {
										Write-Warning "No ESXi hosts found within cluster named ($cluster): PRE_VALIDATION_FAILED"
									}
								} else {
                                    Write-Error "Unable to locate Cluster ($cluster) in vCenter Server ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
								}
							}
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-EsxiPasswordComplexity

Function Request-EsxiAccountLockout {
	<#
        .SYNOPSIS
        Retrieves ESXi host account lockout

        .DESCRIPTION
        The Request-EsxiAccountLockout cmdlet retrieves a list of ESXi hosts for a cluster displaying the currently
        configured account lockout policy (Advanced Settings Security.AccountLockFailures and
        Security.AccountUnlockTime). The cmdlet connects to SDDC Manager using the -server, -user, and -password
        values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Retrieve all ESXi hosts account lockout policy

        .EXAMPLE
        Request-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01
        This example retrieves all ESXi hosts account lockout policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01

        .EXAMPLE
        Request-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves all ESXi hosts account lockout policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -drift
        This example retrieves all ESXi hosts account lockout policy for the cluster named sfo-m01-cl01 in workload domain sfo-m01 and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to retrieve the policy from.

        .PARAMETER cluster
        The name of the cluster to retrieve the policy from.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey("policyFile")) {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version -reportPath $reportPath -policyFile $policyFile ).esxi.accountLockout
                    } else {
                        $requiredConfig = (Get-PasswordPolicyConfig -version $version).esxi.accountLockout
                    }
                }
				if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
							if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
								if (Get-Cluster | Where-Object {$_.Name -eq $cluster}) {
                                    $esxiPasswdPolicy = New-Object System.Collections.Generic.List[System.Object]
									$esxiHosts = Get-Cluster $cluster | Get-VMHost | Sort-Object -Property Name
									if ($esxiHosts) {
										Foreach ($esxiHost in $esxiHosts) {
											# retreving ESXi Advanced Setting: Security.PasswordHistory
											$lockFailues = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"} | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountLockFailures" }
											# retreving ESXi Advanced Setting: Security.PasswordQualityControl
											$unlockTime = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"} | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountUnlockTime" }
											if ($lockFailues -and $unlockTime) {
												$nodePasswdPolicy = New-Object -TypeName psobject
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Cluster" -notepropertyvalue $cluster
												$nodePasswdPolicy | Add-Member -notepropertyname "System" -notepropertyvalue $esxiHost.Name
												$nodePasswdPolicy | Add-Member -notepropertyname "Max Failures" -notepropertyvalue $(if ($drift) { if ($lockFailues.Value -ne $requiredConfig.maxFailures) { "$($lockFailues.Value) [ $($requiredConfig.maxFailures) ]" } else { "$($lockFailues.Value)" }} else { "$($lockFailues.Value)" })
                                                $nodePasswdPolicy | Add-Member -notepropertyname "Unlock Interval (sec)" -notepropertyvalue $(if ($drift) { if ($unlockTime.value -ne $requiredConfig.unlockInterval) { "$($unlockTime.value) [ $($requiredConfig.unlockInterval) ]" } else { "$($unlockTime.value)" }} else { "$($unlockTime.value)" })
												$esxiPasswdPolicy.Add($nodePasswdPolicy)
												Remove-Variable -Name nodePasswdPolicy
											} else {
												Write-Error "Unable to retrieve account lockout policy from ESXi host ($esxiHost.Name): PRE_VALIDATION_FAILED"
											}
										}
										return $esxiPasswdPolicy
									} else {
										Write-Warning "No ESXi hosts found within cluster named ($cluster): PRE_VALIDATION_FAILED"
									}
								} else {
                                    Write-Error "Unable to locate Cluster ($cluster) in vCenter Server ($($vcfVcenterDetails.fqdn)): PRE_VALIDATION_FAILED"
								}
							}
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-EsxiAccountLockout

Function Update-EsxiPasswordExpiration {
	<#
		.SYNOPSIS
        Update ESXi password expiration period in days

        .DESCRIPTION
		The Update-EsxiPasswordExpiration cmdlet configures the password expiration policy on ESXi. The cmdlet connects
        to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Configures the password expiration policy for all ESXi hosts in the cluster

        .EXAMPLE
        Update-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -maxDays 999
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 for the workload domain sfo-m01

        .EXAMPLE
        Update-EsxiPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -maxDays 999 -detail false
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 for the workload domain sfo-m01 but does not show the detail per host

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER cluster
        The name of the cluster to update the policy for.

        .PARAMETER maxDays
        The maximum number of days before the password expires.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$maxDays,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
	)

	Try {
		if (Test-Connection -server $server) {
			if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
				if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
					if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
						if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
							if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
								if (Get-Cluster | Where-Object { $_.Name -eq $cluster }) {
									$esxiHosts = Get-Cluster $cluster | Get-VMHost
									Foreach ($esxiHost in $esxiHosts) {
										# $passwordExpire = Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordMaxDays" }
										if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordMaxDays" }).value -ne $maxDays) {
											Set-AdvancedSetting -AdvancedSetting (Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordMaxDays" }) -Value $maxDays -Confirm:$false | Out-Null
                                            if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordMaxDays" }) -match $maxDays) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Advanced System Setting (Security.PasswordMaxDays) to ($maxDays) on ESXi Host ($esxiHost): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Advanced System Setting (Security.PasswordMaxDays) to ($maxDays) on ESXi Host ($esxiHost): POST_VALIDATION_FAILED"
                                            }
										} else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Advanced System Setting (Security.PasswordMaxDays) to ($maxDays) on ESXi Host ($esxiHost), already set: SKIPPED"
                                            }
                                        }
									}
									if ($detail -eq "false") {
                                        Write-Output "Update Advanced System Setting (Security.PasswordQualityControl) to ($maxDays) on all ESXi Hosts for Workload Domain ($domain): SUCCESSFUL"
                                    }
								} else {
                                    Write-Error "Unable to find Cluster ($cluster) in vCenter Server ($vcfVcenterDetails.fqdn), check details and retry: PRE_VALIDATION_FAILED"
                                }
							}
						}
					}
				} else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	} Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-EsxiPasswordExpiration

Function Update-EsxiPasswordComplexity {
    <#
		.SYNOPSIS
        Update ESXi password complexity policy

        .DESCRIPTION
        The Update-EsxiPasswordComplexity cmdlet configures the password complexity policy on ESXi. The cmdlet connects
        to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Configures the password complexity policy for all ESXi hosts in the cluster

        .EXAMPLE
        Update-EsxiPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -policy "retry=5 min=disabled,disabled,disabled,disabled,15" -history 5
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01

        .EXAMPLE
        Update-EsxiPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -policy "retry=5 min=disabled,disabled,disabled,disabled,15" -history 5 -detail false
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01 but does not show the detail per host

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER cluster
        The name of the cluster to update the policy for.

        .PARAMETER policy
        The policy to apply to the ESXi hosts.

        .PARAMETER history
        The number of previous passwords that a password cannot match.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$policy,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$history,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (Get-Cluster | Where-Object {$_.Name -eq $cluster}) {
                                    $esxiHosts = Get-Cluster $cluster | Get-VMHost
                                    Foreach ($esxiHost in $esxiHosts) {
                                        if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordQualityControl" }).value -ne $policy) {
                                            Set-AdvancedSetting -AdvancedSetting (Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordQualityControl" }) -Value $policy -Confirm:$false | Out-Null
                                            if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordQualityControl" }).value -match $policy) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Password Complexity Policy (Security.PasswordQualityControl) on ESXi Host ($esxiHost): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Password Complexity Policy (Security.PasswordQualityControl) on ESXi Host ($esxiHost): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Password Complexity Policy (Security.PasswordQualityControl) on ESXi Host ($esxiHost), already set: SKIPPED"
                                            }
                                        }
                                        if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordHistory" }).value -ne $history) {
                                            Set-AdvancedSetting -AdvancedSetting (Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordHistory" }) -Value $history -Confirm:$false | Out-Null
                                            if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.PasswordHistory" }) -match $history) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Password Complexity Policy (Security.PasswordHistory) to ($history) on ESXi Host ($esxiHost): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Password Complexity Policy (Security.PasswordHistory) to ($history) on ESXi Host ($esxiHost): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Password Complexity Policy (Security.PasswordHistory) to ($history) on ESXi Host ($esxiHost), already set: SKIPPED"
                                            }
                                        }
                                    }
                                    if ($detail -eq "false") {
                                        Write-Output "Update Password Complexity Policy (Security.PasswordQualityControl and Security.PasswordHistory) on all ESXi Hosts for Workload Domain ($domain): SUCCESSFUL"
                                    }
                                } else {
                                    Write-Error "Unable to find Cluster ($cluster) in vCenter Server ($($vcfVcenterDetails.fqdn)), check details and retry: PRE_VALIDATION_FOUND"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-EsxiPasswordComplexity

Function Update-EsxiAccountLockout {
    <#
		.SYNOPSIS
        Update ESXi account lockout policy

        .DESCRIPTION
        The Update-EsxiAccountLockout cmdlet configures the account lockout policy on ESXi. The cmdlet connects
        to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that the workload domain exists in the SDDC Manager inventory
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Gathers the ESXi hosts for the cluster specificed
        - Configures the account lockout policy for all ESXi hosts in the cluster

        .EXAMPLE
        Update-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -failures 5 -unlockInterval 900
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01

        .EXAMPLE
        Update-EsxiAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -cluster sfo-m01-cl01 -failures 5 -unlockInterval 900 -detail false
        This example configures all ESXi hosts within the cluster named sfo-m01-cl01 of the workload domain sfo-m01 but does not show the detail per host

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain to update the policy for.

        .PARAMETER cluster
        The name of the cluster to update the policy for.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER unlockInterval
        The number of seconds before a locked out account is unlocked.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$cluster,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object {$_.name -eq $domain}) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (Get-Cluster | Where-Object {$_.Name -eq $cluster}) {
                                    $esxiHosts = Get-Cluster $cluster | Get-VMHost
                                    Foreach ($esxiHost in $esxiHosts) {
                                        if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountLockFailures" }).value -ne $failures) {
                                            Set-AdvancedSetting -AdvancedSetting (Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountLockFailures" }) -Value $failures -Confirm:$false | Out-Null
                                            if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountLockFailures" }).value -match $failures) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Password Complexity Policy (Security.AccountLockFailures) to ($failures) on ESXi Host ($esxiHost): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Password Complexity Policy (Security.AccountLockFailures) to ($failures) on ESXi Host ($esxiHost): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Password Complexity Policy (Security.AccountLockFailures) to ($failures) on ESXi Host ($esxiHost), already set: SKIPPED"
                                            }
                                        }
                                        if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountUnlockTime" }).value -ne $unlockInterval) {
                                            Set-AdvancedSetting -AdvancedSetting (Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountUnlockTime" }) -Value $unlockInterval -Confirm:$false | Out-Null
                                            if ((Get-VMHost -name $esxiHost | Where-Object { $_.ConnectionState -eq "Connected" } | Get-AdvancedSetting | Where-Object { $_.Name -eq "Security.AccountUnlockTime" }) -match $unlockInterval) {
                                                if ($detail -eq "true") {
                                                    Write-Output "Update Password Complexity Policy (Security.AccountUnlockTime) to ($unlockInterval) on ESXi Host ($esxiHost): SUCCESSFUL"
                                                }
                                            } else {
                                                Write-Error "Update Password Complexity Policy (Security.AccountUnlockTime) to ($unlockInterval) on ESXi Host ($esxiHost): POST_VALIDATION_FAILED"
                                            }
                                        } else {
                                            if ($detail -eq "true") {
                                                Write-Warning "Update Password Complexity Policy (Security.AccountUnlockTime) to ($unlockInterval) on ESXi Host ($esxiHost), already set: SKIPPED"
                                            }
                                        }
                                    }
                                    if ($detail -eq "false") {
                                        Write-Output "Update Password Complexity Policy (Security.AccountLockFailures and Security.AccountUnlockTime) on all ESXi Hosts for Workload Domain ($domain): SUCCESSFUL"
                                    }
                                } else {
                                    Write-Error "Unable to find Cluster ($cluster) in vCenter Server ($($vcfVcenterDetails.fqdn)), check details and retry: PRE_VALIDATION_FOUND"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
    } Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-EsxiAccountLockout

Function Publish-EsxiPasswordPolicy {
    <#
        .SYNOPSIS
        Publish password policies for ESXi Hosts

        .DESCRIPTION
        The Publish-EsxiPasswordPolicy cmdlet retrieves the requested password policy for all ESXi hosts and converts
        the output to HTML. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Retrieves the requested password policy for all ESXi Hosts and converts to HTML

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -allDomains
        This example will return password expiration policy for all ESXi Hosts across all Workload Domains

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-w01
        This example will return password expiration policy for all ESXi Hosts for a Workload Domain

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -allDomains
        This example will return password complexity policy for all ESXi Hosts across all Workload Domains

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -workloadDomain sfo-w01
        This example will return password complexity policy for all ESXi Hosts for a Workload Domain

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -allDomains
        This example will return account lockout policy for all ESXi Hosts across all Workload Domains

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -workloadDomain sfo-w01
        This example will return account lockout policy for all ESXi Hosts for a Workload Domain

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-w01 -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for all ESXi Hosts across all Workload Domains and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-EsxiPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -workloadDomain sfo-w01 -drift
        This example will return password expiration policy for all ESXi Hosts across all Workload Domains and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER policy
        The policy to publish. One of: PasswordExpiration, PasswordComplexity, AccountLockout.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateSet('PasswordExpiration','PasswordComplexity','AccountLockout')] [String]$policy,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json
    )

    if ($policy -eq "PasswordExpiration") { $pvsCmdlet = "Request-EsxiPasswordExpiration"; $preHtmlContent = '<a id="esxi-password-expiration"></a><h3>ESXi - Password Expiration</h3>' }
    if ($policy -eq "PasswordComplexity") { $pvsCmdlet = "Request-EsxiPasswordComplexity"; $preHtmlContent = '<a id="esxi-password-complexity"></a><h3>ESXi - Password Complexity</h3>' }
    if ($policy -eq "AccountLockout") { $pvsCmdlet = "Request-EsxiAccountLockout"; $preHtmlContent = '<a id="esxi-account-lockout"></a><h3>ESXi - Account Lockout</h3>' }

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                $esxiPasswordPolicyObject = New-Object System.Collections.ArrayList
                if ($PsBoundParameters.ContainsKey('workloadDomain')) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $workloadDomain)) {
						if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
							if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                $clusters = Get-Cluster -Server $vcfVcenterDetails.fqdn
                                foreach ($cluster in $clusters) {
                                    $command = $pvsCmdlet + " -server $server -user $user -pass $pass -cluster $($cluster.name) -domain $workloadDomain" + $commandSwitch
                                    $esxiPolicy = Invoke-Expression $command ; $esxiPasswordPolicyObject += $esxiPolicy
                                }
                            }
                        }
                    }
                } elseif ($PsBoundParameters.ContainsKey('allDomains')) {
                    $allWorkloadDomains = Get-VCFWorkloadDomain
                    foreach ($domain in $allWorkloadDomains ) {
                        if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain.name)) {
                            if (Test-VsphereConnection -server $($vcfVcenterDetails.fqdn)) {
                                if (Test-VsphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                    $clusters = Get-Cluster -Server $vcfVcenterDetails.fqdn
                                    foreach ($cluster in $clusters) {
                                        $command = $pvsCmdlet + " -server $server -user $user -pass $pass -cluster $($cluster.name) -domain $($domain.name)" + $commandSwitch
                                        $esxiPolicy = Invoke-Expression $command; $esxiPasswordPolicyObject += $esxiPolicy
                                    }
                                }
                            }
                        }
                    }
                }
                if ($PsBoundParameters.ContainsKey('json')) {
                    $esxiPasswordPolicyObject
                } else {
                    $esxiPasswordPolicyObject = $esxiPasswordPolicyObject | Sort-Object 'Workload Domain', 'Cluster', 'System' | ConvertTo-Html -Fragment -PreContent $preHtmlContent -As Table
                    $esxiPasswordPolicyObject = Convert-CssClassStyle -htmldata $esxiPasswordPolicyObject
                    $esxiPasswordPolicyObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Publish-EsxiPasswordPolicy

#EndRegion  End ESXi Password Management Functions                  ######
##########################################################################

##########################################################################
#Region     Begin Workspace ONE Access Password Management Function ######

Function Request-WsaPasswordExpiration {
	<#
        .SYNOPSIS
        Retrieves Workspace ONE Access password expiration

        .DESCRIPTION
        The Request-WsaPasswordExpiration cmdlet retrieves the Workspace ONE Access password expiration policy.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
        - Retrieve the password expiration policy

        .EXAMPLE
        Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1!
        This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io

        .EXAMPLE
        Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift
        This example retrieves the password expiration policy for Workspace ONE Access instance sfo-wsa01.sfo.rainpole.io and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

    if ($drift) {
        if ($PsBoundParameters.ContainsKey("policyFile")) {
            $requiredConfig = (Get-PasswordPolicyConfig -reportPath $reportPath -policyFile $policyFile ).wsaDirectory.passwordExpiration
        } else {
            $requiredConfig = (Get-PasswordPolicyConfig).wsaDirectory.passwordExpiration
        }
    }

	Try {
		if (Test-WsaConnection -server $server) {
			if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                if ($WsaPasswordExpiration = Get-WsaPasswordPolicy) {
                    $WsaPasswordExpirationObject = New-Object -TypeName psobject
                    $WsaPasswordExpirationObject | Add-Member -notepropertyname "System" -notepropertyvalue ($server.Split("."))[-0]
                    $WsaPasswordExpirationObject | Add-Member -notepropertyname "Password Lifetime (days)" -notepropertyvalue $(if ($drift) { if (($WsaPasswordExpiration.passwordTtlInHours / 24) -ne $requiredConfig.passwordLifetime) { "$(($WsaPasswordExpiration.passwordTtlInHours / 24)) [ $($requiredConfig.passwordLifetime) ]" } else { "$(($WsaPasswordExpiration.passwordTtlInHours / 24))" }} else { "$(($WsaPasswordExpiration.passwordTtlInHours / 24))" })
                    $WsaPasswordExpirationObject | Add-Member -notepropertyname "Password Reminder (days)" -notepropertyvalue $(if ($drift) { if (($WsaPasswordExpiration.notificationThreshold / 24 / 3600 / 1000) -ne $requiredConfig.passwordReminder) { "$(($WsaPasswordExpiration.notificationThreshold / 24 / 3600 / 1000)) [ $($requiredConfig.passwordReminder) ]" } else { "$(($WsaPasswordExpiration.notificationThreshold / 24 / 3600 / 1000))" }} else { "$(($WsaPasswordExpiration.notificationThreshold / 24 / 3600 / 1000))" })
                    $WsaPasswordExpirationObject | Add-Member -notepropertyname "Temporary Password (hours)" -notepropertyvalue $(if ($drift) { if ($WsaPasswordExpiration.tempPasswordTtl -ne $requiredConfig.temporaryPassword) { "$($WsaPasswordExpiration.tempPasswordTtl) [ $($requiredConfig.temporaryPassword) ]" } else { "$($WsaPasswordExpiration.tempPasswordTtl)" }} else { "$($WsaPasswordExpiration.tempPasswordTtl)" })
                    $WsaPasswordExpirationObject | Add-Member -notepropertyname "Password Reminder Frequency (days)" -notepropertyvalue $(if ($drift) { if (($WsaPasswordExpiration.notificationInterval / 24 / 3600 / 1000) -ne $requiredConfig.temporaryPassword) { "$(($WsaPasswordExpiration.notificationInterval / 24 / 3600 / 1000)) [ $($requiredConfig.temporaryPassword) ]" } else { "$(($WsaPasswordExpiration.notificationInterval / 24 / 3600 / 1000))" }} else { "$(($WsaPasswordExpiration.notificationInterval / 24 / 3600 / 1000))" })
                } else {
                    Write-Error "Unable to retrieve password expiration policy from Workspace ONE Access instance ($server): PRE_VALIDATION_FAILED"
                }
                return $WsaPasswordExpirationObject
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	}
}
Export-ModuleMember -Function Request-WsaPasswordExpiration

Function Request-WsaPasswordComplexity {
	<#
        .SYNOPSIS
        Retrieves Workspace ONE Access password complexity

        .DESCRIPTION
        The Request-WsaPasswordComplexity cmdlet retrieves the Workspace ONE Access password complexity policy.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
        - Retrieve the password complexity policy

        .EXAMPLE
        Request-WsaPasswordComplexity -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1!
        This example retrieves the password complexity policy for Workspace ONE Access instance sfo-wsa01

        .EXAMPLE
        Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the password complexity policy for Workspace ONE Access instance sfo-wsa01 and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift
        This example retrieves the password complexity policy for Workspace ONE Access instance sfo-wsa01 and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

    if ($drift) {
        if ($PsBoundParameters.ContainsKey("policyFile")) {
            $requiredConfig = (Get-PasswordPolicyConfig -reportPath $reportPath -policyFile $policyFile ).wsaDirectory.passwordComplexity
        } else {
            $requiredConfig = (Get-PasswordPolicyConfig).wsaDirectory.passwordComplexity
        }
    }

    $(if ($drift) { if ($WsaPasswordComplexity.History -ne $requiredConfig.history) { "$($WsaPasswordComplexity.History) [ $($requiredConfig.history) ]" } else { "$($WsaPasswordComplexity.History)" }} else { "$($WsaPasswordComplexity.History)" })

	Try {
		if (Test-WsaConnection -server $server) {
			if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                if ($WsaPasswordComplexity = Get-WsaPasswordPolicy) {
                    $WsaPasswordComplexityObject = New-Object -TypeName psobject
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "System" -notepropertyvalue ($server.Split("."))[-0]
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Min Length" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.minLen -ne $requiredConfig.minLength) { "$($WsaPasswordComplexity.minLen) [ $($requiredConfig.minLength) ]" } else { "$($WsaPasswordComplexity.minLen)" }} else { "$($WsaPasswordComplexity.minLen)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Min Lowercase" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.minLower -ne $requiredConfig.minLowercase) { "$($WsaPasswordComplexity.minLower) [ $($requiredConfig.minLowercase) ]" } else { "$($WsaPasswordComplexity.minLower)" }} else { "$($WsaPasswordComplexity.minLower)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Min Uppercase" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.minUpper -ne $requiredConfig.minUppercase) { "$($WsaPasswordComplexity.minUpper) [ $($requiredConfig.minUppercase) ]" } else { "$($WsaPasswordComplexity.minUpper)" }} else { "$($WsaPasswordComplexity.minUpper)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Min Numberic" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.minDigit -ne $requiredConfig.minNumerical) { "$($WsaPasswordComplexity.minDigit) [ $($requiredConfig.minNumerical) ]" } else { "$($WsaPasswordComplexity.minDigit)" }} else { "$($WsaPasswordComplexity.minDigit)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Min Special" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.minSpecial -ne $requiredConfig.minSpecial) { "$($WsaPasswordComplexity.minSpecial) [ $($requiredConfig.minSpecial) ]" } else { "$($WsaPasswordComplexity.minSpecial)" }} else { "$($WsaPasswordComplexity.minSpecial)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "Max Identical Adjacent" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.maxConsecutiveIdenticalCharacters -ne $requiredConfig.maxIdenticalAdjacent) { "$($WsaPasswordComplexity.maxConsecutiveIdenticalCharacters) [ $($requiredConfig.maxIdenticalAdjacent) ]" } else { "$($WsaPasswordComplexity.maxConsecutiveIdenticalCharacters)" }} else { "$($WsaPasswordComplexity.maxConsecutiveIdenticalCharacters)" })
                    $WsaPasswordComplexityObject | Add-Member -notepropertyname "History" -notepropertyvalue $(if ($drift) { if ($WsaPasswordComplexity.History -ne $requiredConfig.history) { "$($WsaPasswordComplexity.History) [ $($requiredConfig.history) ]" } else { "$($WsaPasswordComplexity.History)" }} else { "$($WsaPasswordComplexity.History)" })
                } else {
                    Write-Error "Unable to retrieve password complexity policy from Workspace ONE Access instance ($server): PRE_VALIDATION_FAILED"
                }
                return $WsaPasswordComplexityObject
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	}
}
Export-ModuleMember -Function Request-WsaPasswordComplexity

Function Request-WsaLocalUserPasswordComplexity {
    <#
		.SYNOPSIS
		Retrieve the local user password complexity policy for Workspace ONE Access

        .DESCRIPTION
        The Request-WsaLocalUserPasswordComplexity cmdlet retrieves the local user password complexity policy for
        Workspace ONE Access. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrieves the local user password complexity policy

        .EXAMPLE
        Request-WsaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1!
        This example retrieves the local user password complexity policy for Workspace ONE Access

        .EXAMPLE
        Request-WsaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the local user password complexity policy for Workspace ONE Access and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-WsaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -drift
        This example retrieves the local user password complexity policy for Workspace ONE Access and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            if ($drift) {
                                if ($PsBoundParameters.ContainsKey('policyFile')) {
                                    Get-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -drift -product wsaLocal -reportPath $reportPath -policyFile $policyFile
                                } else {
                                    Get-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -drift -product wsaLocal
                                }
                            } else {
                                Get-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-WsaLocalUserPasswordComplexity

Function Request-WsaLocalUserAccountLockout {
    <#
		.SYNOPSIS
		Retrieve the account lockout policy for Workspace ONE Access

        .DESCRIPTION
        The Request-WsaLocalUserAccountLockout cmdlet retrieves the account lockout policy for SDDC Manager.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
		- Retrieves the account lockout policy of Workspace ONE Access

        .EXAMPLE
        Request-WsaLocalUserAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1!
        This example retrieves the account lockout policy for Workspace ONE Access

        .EXAMPLE
        Request-WsaLocalUserAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the local user password complexity policy for Workspace ONE Access and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-WsaLocalUserAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -drift
        This example retrieves the local user password complexity policy for Workspace ONE Access and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            if ($drift) {
                                if ($PsBoundParameters.ContainsKey('policyFile')) {
                                    Get-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal -drift -reportPath $reportPath -policyFile $policyFile
                                } else {
                                    Get-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal -drift
                                }
                            } else {
                                Get-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Request-WsaLocalUserAccountLockout

Function Request-WsaAccountLockout {
	<#
        .SYNOPSIS
        Retrieves Workspace ONE Access account lockout

        .DESCRIPTION
        The Request-WsaAccountLockout cmdlet retrieves the Workspace ONE Access account lockout policy.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
        - Retrieve the account lockout policy

        .EXAMPLE
        Request-WsaAccountLockout -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1!
        This example retrieves the account lockout policy for Workspace ONE Access instance sfo-wsa01

        .EXAMPLE
        Request-WsaAccountLockout -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the local user password complexity policy for Workspace ONE Access and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-WsaAccountLockout -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -drift
        This example retrieves the local user password complexity policy for Workspace ONE Access and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

	Param (
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

    if ($drift) {
        if ($PsBoundParameters.ContainsKey("policyFile")) {
            $requiredConfig = (Get-PasswordPolicyConfig -reportPath $reportPath -policyFile $policyFile ).wsaDirectory.accountLockout
        } else {
            $requiredConfig = (Get-PasswordPolicyConfig).wsaDirectory.accountLockout
        }
    }

    $(if ($drift) { if ($WsaAccountLockout.numAttempts -ne $requiredConfig.maxFailures) { "$($WsaAccountLockout.numAttempts) [ $($requiredConfig.maxFailures) ]" } else { "$($WsaAccountLockout.numAttempts)" }} else { "$($WsaAccountLockout.numAttempts)" })

    Try {
		if (Test-WsaConnection -server $server) {
			if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                if ($WsaAccountLockout = Get-WsaAccountLockout) {
                    $WsaAccountLockoutObject = New-Object -TypeName psobject
                    $WsaAccountLockoutObject | Add-Member -notepropertyname "System" -notepropertyvalue ($server.Split("."))[-0]
                    $WsaAccountLockoutObject | Add-Member -notepropertyname "Max Failures" -notepropertyvalue $(if ($drift) { if ($WsaAccountLockout.numAttempts -ne $requiredConfig.maxFailures) { "$($WsaAccountLockout.numAttempts) [ $($requiredConfig.maxFailures) ]" } else { "$($WsaAccountLockout.numAttempts)" }} else { "$($WsaAccountLockout.numAttempts)" })
                    $WsaAccountLockoutObject | Add-Member -notepropertyname "Unlock Interval (min)" -notepropertyvalue $WsaAccountLockout.unlockInterval
                    $WsaAccountLockoutObject | Add-Member -notepropertyname "Failed Attempt Interval (min)" -notepropertyvalue $WsaAccountLockout.attemptInterval
                } else {
                    Write-Error "Unable to retrieve account lockout policy from Workspace ONE Access instance ($server): PRE_VALIDATION_FAILED"
                }
                return $WsaAccountLockoutObject
			}
		}
	} Catch {
		Debug-ExceptionWriter -object $_
	}
}
Export-ModuleMember -Function Request-WsaAccountLockout

Function Update-WsaPasswordExpiration {
    <#
		.SYNOPSIS
		Update the Workspace ONE Access password expiration policy

        .DESCRIPTION
        The Update-WsaPasswordExpiration cmdlet configures the password expiration policy for a Workspace ONE Access
        instance.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
		- Configures the Workspace ONE Access password expiration policy

        .EXAMPLE
        Update-WsaPasswordExpiration -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -maxDays 999 -warnDays 14 -reminderDays 7 -tempPasswordHours 24
        This example configures the password expiration policy for Workspace ONE Access

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER maxDays
        The maximum number of days that a password is valid.

        .PARAMETER warnDays
        The number of days before a password expires that a warning is issued.

        .PARAMETER reminderDays
        The number of days before a password expires that a reminder is issued.

        .PARAMETER tempPasswordHours
        The number of hours that a temporary password is valid.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
		[Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$warnDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$reminderDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$tempPasswordHours
	)

	Try {
        if (Test-WsaConnection -server $server) {
            if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                $newMaxDays = ($maxDays * 24)
                $newWarnDays = ($warnDays * 24 * 3600 * 1000)
                $newReminderDays = ($reminderDays * 24 * 3600 * 1000)
                if ((Get-WsaPasswordPolicy).passwordTtlInHours -ne $newMaxDays -or (Get-WsaPasswordPolicy).notificationThreshold -ne $newWarnDays -or (Get-WsaPasswordPolicy).notificationInterval -ne $newReminderDays -or (Get-WsaPasswordPolicy).tempPasswordTtl -ne $tempPasswordHours) {
                    Set-WsaPasswordPolicy -minLen (Get-WsaPasswordPolicy).minLen -minLower (Get-WsaPasswordPolicy).minLower -minUpper (Get-WsaPasswordPolicy).minUpper -minDigit (Get-WsaPasswordPolicy).minDigit -minSpecial (Get-WsaPasswordPolicy).minSpecial -history (Get-WsaPasswordPolicy).history -maxConsecutiveIdenticalCharacters (Get-WsaPasswordPolicy).maxConsecutiveIdenticalCharacters -maxPreviousPasswordCharactersReused (Get-WsaPasswordPolicy).maxPreviousPasswordCharactersReused -tempPasswordTtlInHrs $tempPasswordHours -passwordTtlInDays $maxDays -notificationThresholdInDays $warnDays -notificationIntervalInDays $reminderDays | Out-Null
                    if ((Get-WsaPasswordPolicy).passwordTtlInHours -eq $newMaxDays -and (Get-WsaPasswordPolicy).notificationThreshold -eq $newWarnDays -and (Get-WsaPasswordPolicy).notificationInterval -eq $newReminderDays -and (Get-WsaPasswordPolicy).tempPasswordTtl -eq $tempPasswordHours) {
                        Write-Output "Update Workspace ONE Access Password Expiration Policy on server ($server): SUCCESSFUL"
                    } else {
                        Write-Error "Update Workspace ONE Access Password Expiration Policy on server ($server): POST_VALIDATION_FAILED"
                    }
                } else {
                    Write-Warning "Update Workspace ONE Access Password Expiration Policy on server ($server), already set: SKIPPED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-WsaPasswordExpiration

Function Update-WsaPasswordComplexity {
    <#
		.SYNOPSIS
		Update the Workspace ONE Access password complexity policy

        .DESCRIPTION
        The Update-WsaPasswordComplexity cmdlet configures the password complexity policy for a Workspace ONE Access
        instance.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
		- Configures the Workspace ONE Access password complexity policy

        .EXAMPLE
        Update-WsaPasswordComplexity -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -minLength 15 -minLowercase 1 -minUppercase 1 -minNumeric 1 -minSpecial 1 -maxIdenticalAdjacent 1 -maxPreviousCharacters 0 -history 5
        This example configures the password complexity policy for Workspace ONE Access

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER minLength
        The minimum number of characters that a password must contain.

        .PARAMETER minLowercase
        The minimum number of lowercase characters that a password must contain.

        .PARAMETER minUppercase
        The minimum number of uppercase characters that a password must contain.

        .PARAMETER minNumeric
        The minimum number of numeric characters that a password must contain.

        .PARAMETER minSpecial
        The minimum number of special characters that a password must contain.

        .PARAMETER maxIdenticalAdjacent
        The maximum number of identical adjacent characters that a password can contain.

        .PARAMETER maxPreviousCharacters
        The maximum number of previous characters that a password can contain.

        .PARAMETER history
        The number of previous passwords that a password cannot match.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLowercase,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minUppercase,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minNumeric,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minSpecial,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxIdenticalAdjacent,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$maxPreviousCharacters,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$history
	)

	Try {
        if (Test-WsaConnection -server $server) {
            if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                $currentPasswordPolicy = Get-WsaPasswordPolicy
                $currentMaxDays = (($currentPasswordPolicy).passwordTtlInHours / 24)
                $currentWarnDays = (($currentPasswordPolicy).notificationThreshold / 24 / 3600 / 1000)
                $currentReminderDays = (($currentPasswordPolicy).notificationInterval / 24 / 3600 / 1000)
                if ((Get-WsaPasswordPolicy).minLen -ne $minLength  -or (Get-WsaPasswordPolicy).minLower -ne $minLowercase  -or (Get-WsaPasswordPolicy).minUpper -ne $minUppercase  -or (Get-WsaPasswordPolicy).minDigit -ne $minNumeric -or (Get-WsaPasswordPolicy).minSpecial -ne $minSpecial -or (Get-WsaPasswordPolicy).maxConsecutiveIdenticalCharacters -ne $maxIdenticalAdjacent -or (Get-WsaPasswordPolicy).maxPreviousPasswordCharactersReused -ne $maxPreviousCharacters -or (Get-WsaPasswordPolicy).history -ne $history) {
                    Set-WsaPasswordPolicy -minLen $minLength -minLower $minLowercase -minUpper $minUppercase -minDigit $minNumeric -minSpecial $minSpecial -history $history -maxConsecutiveIdenticalCharacters $maxIdenticalAdjacent -maxPreviousPasswordCharactersReused $maxPreviousCharacters -tempPasswordTtlInHrs (Get-WsaPasswordPolicy).tempPasswordTtl -passwordTtlInDays $currentMaxDays -notificationThresholdInDays $currentWarnDays -notificationIntervalInDays $currentReminderDays | Out-Null
                    if ((Get-WsaPasswordPolicy).minLen -eq $minLength  -and (Get-WsaPasswordPolicy).minLower -eq $minLowercase -and (Get-WsaPasswordPolicy).minUpper -eq $minUppercase  -and (Get-WsaPasswordPolicy).minDigit -eq $minNumeric -and (Get-WsaPasswordPolicy).minSpecial -eq $minSpecial -and (Get-WsaPasswordPolicy).maxConsecutiveIdenticalCharacters -eq $maxIdenticalAdjacent -and (Get-WsaPasswordPolicy).maxPreviousPasswordCharactersReused -eq $maxPreviousCharacters -and (Get-WsaPasswordPolicy).history -eq $history) {
                        Write-Output "Updated Workspace ONE Access Password Complexity on Server ($server): SUCCESSFUL"
                    } else {
                        Write-Error "Update Workspace ONE Access Password Complexity Policy on server ($server): POST_VALIDATION_FAILED"
                    }
                } else {
                    Write-Warning "Update Workspace ONE Access Password Complexity Policy on server ($server), already set: SKIPPED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-WsaPasswordComplexity

Function Update-WsaLocalUserPasswordComplexity {
    <#
		.SYNOPSIS
		Update the local user password complexity policy for Workspace ONE Access

        .DESCRIPTION
        The Update-WsaLocalUserPasswordComplexity cmdlet configures the local user password complexity policy for
        Workspace ONE Access. The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the password complexity policy

        .EXAMPLE
        Update-WsaLocalUserPasswordComplexity -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -minLength 1 -history 5 -maxRetry 3
        This example configures the local user password complexity policy for Workspace ONE Access

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER minLength
        The minimum length of the password.

        .PARAMETER history
        The number of previous passwords that a password cannot match.

        .PARAMETER maxRetry
        The number of failed login attempts before the account is locked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$minLength,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$history,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$maxRetry
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            $existingConfiguration = Get-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass
                            if ($existingConfiguration.'Min Length' -ne $minLength -or $existingConfiguration.'History' -ne $history -or $existingConfiguration.'Max Retries' -ne $maxRetry) {
                                Set-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -minLength $minLength -uppercase $minUppercase -lowercase $minLowercase -numerical $minNumerical -special $minSpecial -unique $minUnique -class $minClass -sequence $maxSequence -history $history -retry $maxRetry | Out-Null
                                $updatedConfiguration = Get-LocalPasswordComplexity -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass
                                if ($updatedConfiguration.'Min Length' -eq $minLength -and $updatedConfiguration.'History' -eq $history -and $updatedConfiguration.'Max Retries' -eq $maxRetry) {
                                    Write-Output "Update Local User Password Complexity Policy on Workspace ONE Access ($wsaFqdn): SUCCESSFUL"
                                } else {
                                    Write-Error "Update Local User Password Complexity Policy on Workspace ONE Access ($wsaFqdn): POST_VALIDATION_FAILED"
                                }
                            } else {
                                Write-Warning "Update Local User Password Complexity Policy on Workspace ONE Access ($wsaFqdn), already set: SKIPPED"
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-WsaLocalUserPasswordComplexity

Function Update-WsaAccountLockout {
    <#
		.SYNOPSIS
		Update the Workspace ONE Access account lockout policy

        .DESCRIPTION
        The Update-WsaAccountLockout cmdlet configures the account lockout policy for Workspace ONE Access.
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
		- Configures the Workspace ONE Access account lockout policy

        .EXAMPLE
        Update-WsaAccountLockout -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -failures 5 -failureInterval 180 -unlockInterval 900
        This example configures the account lockout policy for Workspace ONE Access

        .PARAMETER server
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER user
        The username to authenticate to the Workspace ONE Access instance.

        .PARAMETER pass
        The password to authenticate to the Workspace ONE Access instance.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER failureInterval
        The number of seconds before the failed login attempts counter is reset.

        .PARAMETER unlockInterval
        The number of seconds before a locked account is unlocked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failureInterval,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval

	)

	Try {
        if (Test-WsaConnection -server $server) {
            if (Test-WsaAuthentication -server $server -user $user -pass $pass) {
                $failureInterval = ($failureInterval / 60)
                $unlockInterval = ($unlockInterval / 60)
                if ((Get-WsaAccountLockout).numAttempts -ne $failures -or (Get-WsaAccountLockout).attemptInterval -ne $failureInterval -or (Get-WsaAccountLockout).unlockInterval -ne $unlockInterval) {
                    Set-WsaAccountLockout  -numAttempts $failures -attemptInterval $failureInterval -unlockInterval $unlockInterval | Out-Null
                    if ((Get-WsaAccountLockout).numAttempts -eq $failures -and (Get-WsaAccountLockout).attemptInterval -eq $failureInterval -and (Get-WsaAccountLockout).unlockInterval -eq $unlockInterval) {
                        Write-Output "Update Workspace ONE Access Account Lockout Policy on instance ($server): SUCCESSFUL"
                    } else {
                        Write-Error "Update Workspace ONE Access Account Lockout Policy on instance ($server): POST_VALIDATION_FAILED"
                    }
                } else {
                    Write-Warning "Update Workspace ONE Access Account Lockout Policy on instance ($server), already set: SKIPPED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-WsaAccountLockout

Function Update-WsaLocalUserAccountLockout {
    <#
		.SYNOPSIS
		Update the account lockout policy of Workspace ONE Access

        .DESCRIPTION
        The Update-WsaLocalUserAccountLockout cmdlet configures the account lockout policy of Workspace ONE Access.
        The cmdlet connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the account lockout policy

        .EXAMPLE
        Update-WsaLocalUserAccountLockout -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -failures 3 -unlockInterval 900 -rootUnlockInterval 900
        This example configures the account lockout policy for Workspace ONE Access

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER failures
        The number of failed login attempts before the account is locked.

        .PARAMETER unlockInterval
        The number of seconds before a locked account is unlocked.

        .PARAMETER rootUnlockInterval
        The number of seconds before a locked root account is unlocked.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Int]$failures,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$unlockInterval,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Int]$rootUnlockInterval
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType MANAGEMENT)) {
                    if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                        if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                            $existingConfiguration = Get-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal
                            if ($existingConfiguration.'Max Failures' -ne $failures -or $existingConfiguration.'Unlock Interval (sec)' -ne $unlockInterval -or $existingConfiguration.'Root Unlock Interval (sec)' -ne $rootUnlockInterval) {
                                Set-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -failures $failures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval | Out-Null
                                $updatedConfiguration = Get-LocalAccountLockout -vmName ($wsaFqdn.Split("."))[-0] -guestUser root -guestPassword $wsaRootPass -product wsaLocal
                                if ($updatedConfiguration.'Max Failures' -eq $failures -and $updatedConfiguration.'Unlock Interval (sec)' -eq $unlockInterval -and $updatedConfiguration.'Root Unlock Interval (sec)' -eq $rootUnlockInterval) {
                                    Write-Output "Update Account Lockout Policy on Workspace ONE Access ($wsaFqdn): SUCCESSFUL"
                                } else {
                                    Write-Error "Update Account Lockout Policy on Workspace ONE Access ($wsaFqdn): POST_VALIDATION_FAILED"
                                }
                            } else {
                                Write-Warning "Update Account Lockout Policy on Workspace ONE Access ($wsaFqdn), already set: SKIPPED"
                            }
                        }
                    }
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    }
}
Export-ModuleMember -Function Update-WsaLocalUserAccountLockout

Function Publish-WsaDirectoryPasswordPolicy {
    <#
        .SYNOPSIS
        Publish password policies for Workspace ONE Access Directory

        .DESCRIPTION
        The Publish-WsaDirectoryPasswordPolicy cmdlet retrieves the requested password policy for Workspace ONE Access
        and converts the output to HTML. The cmdlet connects to the SDDC Manager using the -server, -user, and
        -password values:
        - Validates that network connectivity and authentication is possible to Workspace ONE Access
        - Retrieves the requested password policy for Workspace ONE Access and converts to HTML

        .EXAMPLE
        Publish-WsaDirectoryPasswordPolicy -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -policy PasswordExpiration -allDomains
        This example will return the password expiration policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaDirectoryPasswordPolicy -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -policy PasswordComplexity -allDomains
        This example will return the password complexity policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaDirectoryPasswordPolicy -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -policy AccountLockout -allDomains
        This example will return the account lockout policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaDirectoryPasswordPolicy -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -policy PasswordExpiration -allDomains -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return the password expiration policy for Workspace ONE Access Directory Users and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-WsaDirectoryPasswordPolicy -server sfo-wsa01.sfo.rainpole.io -user admin -pass VMw@re1! -policy PasswordExpiration -allDomains -drift
        This example will return the password expiration policy for Workspace ONE Access Directory Users and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER policy
        The policy to publish. One of: PasswordExpiration, PasswordComplexity, AccountLockout.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateSet('PasswordExpiration','PasswordComplexity','AccountLockout')] [String]$policy,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain
    )

    if ($policy -eq "PasswordExpiration") { $pvsCmdlet = "Request-WsaPasswordExpiration"; $preHtmlContent = '<a id="wsa-directory-password-expiration"></a><h3>Workspace ONE Access Directory - Password Expiration</h3>' }
    if ($policy -eq "PasswordComplexity") { $pvsCmdlet = "Request-WsaPasswordComplexity"; $preHtmlContent = '<a id="wsa-directory-password-complexity"></a><h3>Workspace ONE Access Directory - Password Complexity</h3>' }
    if ($policy -eq "AccountLockout") { $pvsCmdlet = "Request-WsaAccountLockout"; $preHtmlContent = '<a id="wsa-directory-account-lockout"></a><h3>Workspace ONE Access Directory - Account Lockout</h3>' }

    # Define the Command Switch
    if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }

    Try {
        $command = $pvsCmdlet + " -server $server -user $user -pass $pass" + $commandSwitch
        $wsaDirectoryPasswordPolicyObject = Invoke-Expression $command
        if ($PsBoundParameters.ContainsKey('json')) {
            $wsaDirectoryPasswordPolicyObject
        } else {
            if ($wsaDirectoryPasswordPolicyObject.Count -eq 0) {
                $wsaDirectoryPasswordPolicyObject = $wsaDirectoryPasswordPolicyObject | ConvertTo-Html -Fragment -PreContent $preHtmlContent -PostContent '<p>Workspace ONE Access Not Requested</p>'
            } else {
                $wsaDirectoryPasswordPolicyObject = $wsaDirectoryPasswordPolicyObject | Sort-Object 'System' | ConvertTo-Html -Fragment -PreContent $preHtmlContent -As Table
            }
            $wsaDirectoryPasswordPolicyObject = Convert-CssClassStyle -htmldata $wsaDirectoryPasswordPolicyObject
            $wsaDirectoryPasswordPolicyObject
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-WsaDirectoryPasswordPolicy

Function Publish-WsaLocalPasswordPolicy {
    <#
        .SYNOPSIS
        Publish password policies for Workspace ONE Access Local Users

        .DESCRIPTION
        The Publish-WsaDirectoryPasswordPolicy cmdlet retrieves the requested password policy for all ESXi hosts and converts
        the output to HTML. The cmdlet connects to the SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
        - Retrieves the requested password policy for Workspace ONE Access Local Users and converts to HTML

        .EXAMPLE
        Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
        This example will return password expiration policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordComplexity -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
        This example will return password complexity policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy AccountLockout -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains
        This example will return account lockout policy for Workspace ONE Access Directory Users

        .EXAMPLE
        Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example will return password expiration policy for Workspace ONE Access Directory Users and compare the configuration against the passwordPolicyConfig.json

        .EXAMPLE
        Publish-WsaLocalPasswordPolicy -server sfo-vcf01.sfo.rainpole.io -user admin@local -pass VMw@re1!VMw@re1! -policy PasswordExpiration -wsaFqdn sfo-wsa01.sfo.rainpole.io -wsaRootPass VMw@re1! -allDomains -drift
        This example will return password expiration policy for Workspace ONE Access Directory Users and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER wsaFqdn
        The fully qualified domain name of the Workspace ONE Access instance.

        .PARAMETER wsaRootPass
        The password for the Workspace ONE Access appliance root account.

        .PARAMETER policy
        The policy to publish. One of: PasswordExpiration, PasswordComplexity, AccountLockout.

        .PARAMETER allDomains
        Switch to publish the policy for all workload domains.

        .PARAMETER workloadDomain
        Switch to publish the policy for a specific workload domain.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.

        .PARAMETER json
        Switch to publish the policy in JSON format.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaFqdn,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$wsaRootPass,
        [Parameter (Mandatory = $true)] [ValidateSet('PasswordExpiration','PasswordComplexity','AccountLockout')] [String]$policy,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [Switch]$json,
        [Parameter (ParameterSetName = 'All-WorkloadDomains', Mandatory = $true)] [ValidateNotNullOrEmpty()] [Switch]$allDomains,
        [Parameter (ParameterSetName = 'Specific-WorkloadDomain', Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$workloadDomain
    )

    Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {

                # Define the Command Switch
                if ($PsBoundParameters.ContainsKey('drift')) { if ($PsBoundParameters.ContainsKey('policyFile')) { $commandSwitch = " -drift -reportPath '$reportPath' -policyFile '$policyFile'" } else { $commandSwitch = " -drift" }} else { $commandSwitch = "" }
                [Array]$localUsers = '"root","sshuser"'
                if ($policy -eq "PasswordExpiration") { $pvsCmdlet = "Request-LocalUserPasswordExpiration"; $preHtmlContent = '<a id="wsa-local-password-expiration"></a><h3>Workspace ONE Access (Local Users) - Password Expiration</h3>'; $customSwitch = " -domain $((Get-VCFWorkloadDomain | Where-Object {$_.type -eq "MANAGEMENT"}).name) -product wsaLocal -vmName $(($wsaFqdn.Split("."))[-0]) -guestUser root -guestPassword $wsaRootPass -localUser $localUsers" }
                if ($policy -eq "PasswordComplexity") { $pvsCmdlet = "Request-WsaLocalUserPasswordComplexity"; $preHtmlContent = '<a id="wsa-local-password-complexity"></a><h3>Workspace ONE Access (Local Users) - Password Complexity</h3>'; $customSwitch = " -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass"}
                if ($policy -eq "AccountLockout") { $pvsCmdlet = "Request-WsaLocalUserAccountLockout"; $preHtmlContent = '<a id="wsa-local-account-lockout"></a><h3>Workspace ONE Access (Local Users) - Account Lockout</h3>'; $customSwitch = " -wsaFqdn $wsaFqdn -wsaRootPass $wsaRootPass" }

                $command = $pvsCmdlet + " -server $server -user $user -pass $pass" + $commandSwitch + $customSwitch
                $wsaLocalPasswordPolicyObject = Invoke-Expression $command
                if ($PsBoundParameters.ContainsKey('json')) {
                    $wsaLocalPasswordPolicyObject
                } else {
                    if ($wsaLocalPasswordPolicyObject.Count -eq 0) {
                        $wsaLocalPasswordPolicyObject = $wsaLocalPasswordPolicyObject | ConvertTo-Html -Fragment -PreContent $preHtmlContent -PostContent '<p>Workspace ONE Access Not Requested</p>'
                    } else {
                        $wsaLocalPasswordPolicyObject = $wsaLocalPasswordPolicyObject | Sort-Object 'System' | ConvertTo-Html -Fragment -PreContent $preHtmlContent -As Table
                    }
                    $wsaLocalPasswordPolicyObject = Convert-CssClassStyle -htmldata $wsaLocalPasswordPolicyObject
                    $wsaLocalPasswordPolicyObject
                }
            }
        }
    } Catch {
        Debug-CatchWriter -object $_
    }
}
Export-ModuleMember -Function Publish-WsaLocalPasswordPolicy

#EndRegion  End Workspace ONE Access Password Management Functions  ######
##########################################################################

##########################################################################
#Region     Begin Shared Password Management Function               ######

Function Request-LocalUserPasswordExpiration {
    <#
		.SYNOPSIS
		Retrieve local user password expiration policy

        .DESCRIPTION
        The Request-LocalUserPasswordExpiration cmdlet retrieves a local user password expiration policy. The cmdlet
        connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Retrives the local user password expiration policy

        .EXAMPLE
        Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root"
        This example retrieves the global password expiration policy for the vCenter Server

        .EXAMPLE
        Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root" -drift -reportPath "F:\Reporting" -policyFile "passwordPolicyConfig.json"
        This example retrieves the global password expiration policy for the vCenter Server and checks the configuration drift using the provided configuration JSON

        .EXAMPLE
        Request-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -product vcenterServer -vmName sfo-m01-vc01 -guestUser root -guestPassword VMw@re1! -localUser "root" -drift
        This example retrieves the global password expiration policy for the vCenter Server and compares the configuration against the product defaults

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain which the product is deployed for.

        .PARAMETER vmName
        The name of the virtual machine to retrieve the policy from.

        .PARAMETER guestUser
        The username to authenticate to the virtual machine guest operating system.

        .PARAMETER guestPassword
        The password to authenticate to the virtual machine guest operating system.

        .PARAMETER localUser
        The local user to retrieve the password expiration policy for.

        .PARAMETER product
        The product to retrieve the password expiration policy for. One of: sddcManager, vcenterServer, nsxManager, nsxEdge, wsaLocal.

        .PARAMETER drift
        Switch to compare the current configuration against the product defaults or a JSON file.

        .PARAMETER reportPath
        The path to save the policy report.

        .PARAMETER policyFile
        The path to the policy configuration file.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$vmName,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$guestUser,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$guestPassword,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Array]$localUser,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateSet('sddcManager', 'vcenterServer', 'nsxManager', 'nsxEdge', 'wsaLocal')] [String]$product,
        [Parameter (Mandatory = $false, ParameterSetName = 'drift')] [ValidateNotNullOrEmpty()] [Switch]$drift,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$reportPath,
        [Parameter (Mandatory = $false)] [ValidateNotNullOrEmpty()] [String]$policyFile
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if ($drift) {
                    $version = ""
                    if(((Get-VCFManager).version) -match "\d+\.\d+\.\d+") {
                        $version = $Matches[0]
                    } 
                    if ($PsBoundParameters.ContainsKey('policyFile')) {
                        $command = '(Get-PasswordPolicyConfig  -version $version -reportPath $reportPath -policyFile $policyFile ).' + $product + '.passwordExpiration'
                    } else {
                        $command = '(Get-PasswordPolicyConfig -version $version).' + $product + '.passwordExpiration'
                    }
                    $requiredConfig = Invoke-Expression $command
                }
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                                    $vcenterDomain = $vcfVcenterDetails.type
                                    if ($vcenterDomain -ne "MANAGEMENT") {
                                        if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                            if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                                if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                                    if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                                        $mgmtConnected = $true
                                                    }
                                                }
                                            }
                                        } else {
                                            Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                                        }
                                    }
                                
                                }
                                $allLocalUserExpirationObject = New-Object System.Collections.ArrayList
                                foreach ($user in $localUser) {
                                    if ($localUserPasswordExpiration = Get-LocalUserPasswordExpiration -vmName $vmName -guestUser $guestUser -guestPassword $guestPassword -localUser $user) {
                                        $localUserExpirationObject = New-Object -TypeName psobject
                                        $localUserExpirationObject | Add-Member -notepropertyname "Workload Domain" -notepropertyvalue $domain
                                        $localUserExpirationObject | Add-Member -notepropertyname "System" -notepropertyvalue $vmName
                                        $localUserExpirationObject | Add-Member -notepropertyname "User" -notepropertyvalue $user
                                        $localUserExpirationObject | Add-Member -notepropertyname "Min Days" -notepropertyvalue $(if ($drift) { if ($(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim()) -ne $requiredConfig.minDays) { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim()) [ $($requiredConfig.minDays) ]" } else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim())" }} else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim())" })
                                        $localUserExpirationObject | Add-Member -notepropertyname "Max Days" -notepropertyvalue $(if ($drift) { if ($(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim()) -ne $requiredConfig.maxDays) { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim()) [ $($requiredConfig.maxDays) ]" } else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim())" }} else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim())" })
                                        $localUserExpirationObject | Add-Member -notepropertyname "Warning Days" -notepropertyvalue $(if ($drift) { if ($(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim()) -ne $requiredConfig.warningDays) { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim()) [ $($requiredConfig.warningDays) ]" } else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim())" }} else { "$(($localUserPasswordExpiration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim())" })
                                        $allLocalUserExpirationObject += $localUserExpirationObject
                                    } else {
                                        Write-Error "Unable to retrieve password expiration policy for local user ($user) from Virtual Machine ($vmName): PRE_VALIDATION_FAILED"
                                    }
                                }
                                return $allLocalUserExpirationObject
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Request-LocalUserPasswordExpiration

Function Update-LocalUserPasswordExpiration {
    <#
		.SYNOPSIS
		Configure a local user password expiration policy

        .DESCRIPTION
        The Update-LocalUserPasswordExpiration cmdlet configures a local user password expiration policy. The cmdlet
        connects to SDDC Manager using the -server, -user, and -password values:
        - Validates that network connectivity and authentication is possible to SDDC Manager
        - Validates that network connectivity and authentication is possible to vCenter Server
		- Configures the local user password expiration policy

        .EXAMPLE
        Update-LocalUserPasswordExpiration -server sfo-vcf01.sfo.rainpole.io -user administrator@vsphere.local -pass VMw@re1! -domain sfo-m01 -vmName sfo-wsa01 -guestUser root -guestPassword VMw@re1! -localUser "root","sshuser" -minDays 0 -maxDays 999 -warnDays 14
        This example updates the global password expiration policy for the vCenter Server

        .PARAMETER server
        The fully qualified domain name of the SDDC Manager instance.

        .PARAMETER user
        The username to authenticate to the SDDC Manager instance.

        .PARAMETER pass
        The password to authenticate to the SDDC Manager instance.

        .PARAMETER domain
        The name of the workload domain which the product is deployed for.

        .PARAMETER vmName
        The name of the virtual machine to retrieve the policy from.

        .PARAMETER guestUser
        The username to authenticate to the virtual machine guest operating system.

        .PARAMETER guestPassword
        The password to authenticate to the virtual machine guest operating system.

        .PARAMETER localUser
        The local user to retrieve the password expiration policy for.

        .PARAMETER minDays
        The minimum number of days between password changes.

        .PARAMETER maxDays
        The maximum number of days between password changes.

        .PARAMETER warnDays
        The number of days of warning before password expires.

        .PARAMETER detail
        Return the details of the policy. One of true or false. Default is true.
    #>

    Param (
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$server,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$user,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$pass,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$domain,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$vmName,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$guestUser,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$guestPassword,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [Array]$localUser,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$minDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$maxDays,
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()] [String]$warnDays,
        [Parameter (Mandatory = $false)] [ValidateSet("true","false")] [String]$detail="true"
	)

	Try {
        if (Test-VCFConnection -server $server) {
            if (Test-VCFAuthentication -server $server -user $user -pass $pass) {
                if (Get-VCFWorkloadDomain | Where-Object { $_.name -eq $domain }) {
                    if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                        if (Test-vSphereConnection -server $($vcfVcenterDetails.fqdn)) {
                            if (Test-vSphereAuthentication -server $vcfVcenterDetails.fqdn -user $vcfVcenterDetails.ssoAdmin -pass $vcfVcenterDetails.ssoAdminPass) {
                                if (($vcfVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domain $domain)) {
                                    $vcenterDomain = $vcfVcenterDetails.type
                                    if ($vcenterDomain -ne "MANAGEMENT") {
                                        if (Get-VCFWorkloadDomain | Where-Object { $_.type -eq "MANAGEMENT" }) {
                                            if (($vcfMgmtVcenterDetails = Get-vCenterServerDetail -server $server -user $user -pass $pass -domainType "Management")) {
                                                if (Test-vSphereConnection -server $($vcfMgmtVcenterDetails.fqdn)) {
                                                    if (Test-vSphereAuthentication -server $vcfMgmtVcenterDetails.fqdn -user $vcfMgmtVcenterDetails.ssoAdmin -pass $vcfMgmtVcenterDetails.ssoAdminPass) {
                                                        $mgmtConnected = $true
                                                    }
                                                }
                                            }
                                        } else {
                                            Write-Error "Unable to find Workload Domain typed (MANAGEMENT) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                                        }
                                    }
                                }
                                foreach ($user in $localUser) {
                                    $existingConfiguration = Get-LocalUserPasswordExpiration -vmName $vmName -guestUser $guestUser -guestPassword $guestPassword -localUser $user
                                    $currentMinDays = ($existingConfiguration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim()
                                    $currentMaxDays = ($existingConfiguration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim()
                                    $currentWarnDays = ($existingConfiguration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim()
                                    if ($currentMinDays -ne $minDays -or $currentMaxDays -ne $maxDays -or $currentWarnDays -ne $warnDays) {
                                        Set-LocalUserPasswordExpiration -vmName $vmName -guestUser $guestUser -guestPassword $guestPassword -localUser $user -minDays $minDays -maxDays $maxDays -warnDays $warnDays
                                        $updatedConfiguration = Get-LocalUserPasswordExpiration -vmName $vmName -guestUser $guestUser -guestPassword $guestPassword -localUser $user
                                        $updatedMinDays = ($updatedConfiguration | Where-Object {$_.Setting -match "Minimum number of days between password change"}).Value.Trim()
                                        $updatedMaxDays = ($updatedConfiguration | Where-Object {$_.Setting -match "Maximum number of days between password change"}).Value.Trim()
                                        $updatedWarnDays = ($updatedConfiguration | Where-Object {$_.Setting -match "Number of days of warning before password expires"}).Value.Trim()
                                        if ($updatedMinDays -eq $minDays -or $updatedMaxDays -eq $maxDays -or $updatedWarnDays -eq $warnDays) {
                                            if ($detail -eq "true") {
                                                Write-Output "Update Local User ($user) Password Expiration Policy on Virtual Machine ($vmName): SUCCESSFUL"
                                            }
                                        } else {
                                            Write-Error "Update Local User ($user) Password Expiration Policy on Virtual Machine ($vmName): POST_VALIDATION_FAILED"
                                        }
                                    } else {
                                        if ($detail -eq "true") {
                                            Write-Warning "Update Local User ($user) Password Expiration Policy on Virtual Machine ($vmName), already set: SKIPPED"
                                        }
                                    }
                                }
                                if ($detail -eq "false") {
                                    Write-Output "Update Local Users to Max Days ($maxDays), Min Days ($minDays) and Warn Days ($warnDays) on Virtual Machine ($vmName): SUCCESSFUL"
                                }
                            }
                        }
                    }
                } else {
                    Write-Error "Unable to find Workload Domain named ($domain) in the inventory of SDDC Manager ($server): PRE_VALIDATION_FAILED"
                }
            }
        }
	} Catch {
        Debug-ExceptionWriter -object $_
    } Finally {
        if ($global:DefaultVIServers) {
            Disconnect-VIServer -Server $global:DefaultVIServers -Confirm:$false
        }
    }
}
Export-ModuleMember -Function Update-LocalUserPasswordExpiration

#EndRegion  End Shared Password Management Functions                ######
##########################################################################

##########################################################################
#Region     Begin Supporting Functions                              ######

Function Test-VcfPasswordManagementPrereq {
    <#
		.SYNOPSIS
        Validate prerequisites to run the PowerShell module.

        .DESCRIPTION
        The Test-VcfPasswordManagementPrereq cmdlet checks that all the prerequisites have been met to run the PowerShell module.

        .EXAMPLE
        Test-VcfPasswordManagementPrereq
        This example runs the prerequisite validation.
    #>

    Try {
        Clear-Host; Write-Host ""

        $modules = @(
            @{ Name=("VMware.PowerCLI"); MinimumVersion=("13.0.0")}
            @{ Name=("VMware.vSphere.SsoAdmin"); MinimumVersion=("1.3.9")}
            @{ Name=("PowerVCF"); MinimumVersion=("2.3.0")}
            @{ Name=("PowerValidatedSolutions"); MinimumVersion=("2.4.0")}
        )

        foreach ($module in $modules ) {
            if ((Get-InstalledModule -ErrorAction SilentlyContinue -Name $module.Name).Version -lt $module.MinimumVersion) {
                $message = "PowerShell Module: $($module.Name) $($module.MinimumVersion) minimum required version is not installed."
                Show-PasswordManagementOutput -type ERROR -message $message
                Break
            } else {
                $moduleCurrentVersion = (Get-InstalledModule -Name $module.Name).Version
                $message = "PowerShell Module: $($module.Name) $($moduleCurrentVersion) is installed and supports the minimum required version."
                Show-PasswordManagementOutput -type INFO -message $message
            }
        }
    }
    Catch {
        Write-Error $_.Exception.Message
    }
}
Export-ModuleMember -Function Test-VcfPasswordManagementPrereq

Function Show-PasswordManagementOutput {
    Param (
        [Parameter (Mandatory = $true)] [AllowEmptyString()] [String]$message,
        [Parameter (Mandatory = $false)] [ValidateSet("INFO", "ERROR", "WARNING", "EXCEPTION","ADVISORY","NOTE","QUESTION","WAIT")] [String]$type = "INFO",
        [Parameter (Mandatory = $false)] [Switch]$skipnewline
    )

    If ($type -eq "INFO") {
        $messageColour = "92m" #Green
    } elseIf ($type -in "ERROR","EXCEPTION") {
        $messageColour = "91m" # Red
    } elseIf ($type -in "WARNING","ADVISORY","QUESTION") {
        $messageColour = "93m" #Yellow
    } elseIf ($type -in "NOTE","WAIT") {
        $messageColour = "97m" # White
    }

    $ESC = [char]0x1b
    $timestampColour = "97m"

    $timeStamp = Get-Date -Format "MM-dd-yyyy_HH:mm:ss"

    If ($skipnewline) {
        Write-Host -NoNewline "$ESC[${timestampcolour} [$timestamp]$ESC[${threadColour} $ESC[${messageColour} [$type] $message$ESC[0m"
    } else {
        Write-Host "$ESC[${timestampcolour} [$timestamp]$ESC[${threadColour} $ESC[${messageColour} [$type] $message$ESC[0m"
    }
}
Export-ModuleMember -Function Show-PasswordManagementOutput

#EndRegion  End Supporting Functions                                ######
##########################################################################
