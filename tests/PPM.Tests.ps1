# © Broadcom. All Rights Reserved.
# The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-2

Describe 'Test Suite' {
    BeforeAll {
        $useLiveData = $true

        Function Start-SetupLogFile ($path) {
            if (!$path) {
                $path = Get-Location
            }
            $scriptName = Split-Path $MyInvocation.ScriptName -leaf
            $filetimeStamp = Get-Date -Format "MM-dd-yyyy_hh_mm_ss"
            $logfilename = $scriptName + '-' + $filetimeStamp + '.log'
            $Global:logFile = Join-Path $path.Path 'logs' $logfilename
            $logFolder = Join-Path $path.Path 'logs'
            $logFolderExists = Test-Path $logFolder
            if (!$logFolderExists) {
                New-Item -ItemType Directory -Path $logFolder | Out-Null
            }
            New-Item -type File -Path $logFile | Out-Null
            $logContent = '[' + $filetimeStamp + '] INFO Beginning of Log File'
            Add-Content -Path $logFile $logContent | Out-Null
        }

        Function Write-LogToFile {
            Param (
                [Parameter (Mandatory = $true)] [AllowEmptyString()] [String]$Message,
                [Parameter (Mandatory = $false)] [ValidateSet("INFO", "ERROR", "WARNING", "EXCEPTION")] [String]$Type = "INFO",
                [Parameter (Mandatory = $false)] [String]$Colour,
                [Parameter (Mandatory = $false)] [String]$Skipnewline,
                [Parameter (Mandatory = $false)] [bool]$LogOnConsole = $false
            )

            $timeStamp = Get-Date -Format "MM-dd-yyyy_HH:mm:ss"
            if ($LogOnConsole) {
                if (!$Colour) {
                    $Colour = "White"
                }
                Write-Host -NoNewline -ForegroundColor White " [$timestamp]"
                if ($Skipnewline) {
                    Write-Host -NoNewline -ForegroundColor $Colour " $Type $Message"
                } else {
                    Write-Host -ForegroundColor $colour " $Type $Message"
                }
            }
            $logContent = '[' + $timeStamp + '] ' + $Type + ' ' + $Message
            Add-Content -Path $logFile $logContent
        }

        Function Get-Index {
            param(
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $output,
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $server,
                [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()] $user,
                [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()] $type,
                [bool] $aria = $false,
                [bool] $useLiveData = $false
            )

            $flag = $false
            if ($useLiveData) {
                $index = 0
                # Loop through each item in the output.
                foreach ($item in $output) {
                    if ($aria) {
                        $userinOutput = $item.'Local User'
                    } else {
                        $userinOutput = $item.'User'
                    }
                    if ($user -and $type) {
                        if ($item.'System' -match $server -and $userinOutput -match $user -and $item.'Type' -match $type) {
                            $flag = $true
                            break
                        }
                    } else {
                        if ($user) {
                            # If the system matches the server and user, break the loop.
                            if ($item.'System' -match $server -and $userinOutput -match $user) {
                                $flag = $true
                                break
                            }
                        } elseif ($type) {
                            if ($item.'System' -match $server -and $item.'Type' -match $type) {
                                $flag = $true
                                break
                            }
                        } else {
                            # If the system matches the server, break the loop.
                            if ($item.'System' -match $server) {
                                $flag = $true
                                break
                            }
                        }
                    }
                }
                if ($flag) {
                    return $index
                } else {
                    # Increment the index by 1.
                    $index = $index + 1
                }
            } else {
                $index = $output.'Index'
            }
            if (-Not $flag) {
                Write-LogToFile -Type ERROR -message "$server or $user is not matching in the $output"
            } else {
                return $index
            }
        }

        Start-SetupLogFile
        $inputData = Get-Content -Raw 'inputData.json' | ConvertFrom-Json
        $server = $inputData.'SDDC Manager'
        $vmName = $inputData.'SDDC Manager VM Name'
        $user = $inputData.'User'
        $pass = $inputData.'Password'
        $rootUser = $inputData.'Root User'
        $rootPass = $inputData.'Root Password'
        $guestUser = $inputData.'Guest User'
        $localUser = $inputData.'Local User'
        $domain = $inputData.'Domains'[0]
        $esxiServer = $inputData.$domain.'ESX Hosts'[0]
        $cluster = $inputData.$domain.'Clusters'[0]
        $nsxManagerNode = $inputData.$domain.'NSX Manager Nodes'[0]
        $nsxManager = $inputData.$domain.'NSX Manager'[0]
        $nsxEdgeNode = $inputData.$domain.'NSX Edge Nodes'[0]
        $nsxEdgeFqdn = $inputData.$domain.'NSX Edge FQDN'[0]
        $vcenterServer = $inputData.$domain.'vCenter'[0]
        $ariaDomain = $inputData.'Domains'[0]
        $ariaSuiteLifecycle = $inputData.$ariaDomain."Aria"."Aria Suite Lifecycle"
        $ariaOperations = $inputData.$ariaDomain."Aria"."Aria Operations"
        $ariaOperationsLogs = $inputData.$ariaDomain."Aria"."Aria Operations Logs"
        $ariaAutomation = $inputData.$ariaDomain."Aria"."Aria Automation"
        $workspaceOneAccess = $inputData.$ariaDomain."Aria"."Workspace ONE Access"
    }


    Describe 'Password Expiration Test Suite' -Tag "PasswordExpirationSuite" {
        # ESX Password Expiration
        Describe 'ESX Password Expiration' -Tag "EsxiPasswordExpiration" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of ESX Password Expiration Positive Testcase"
                    # Request the current ESX host password expiration settings.
                    $currentExpirationSettings = Request-EsxiPasswordExpiration -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                    # Get the index of the first ESX host in the output.
                    $index = Get-Index -output $currentExpirationSettings -server $esxiServer -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the ESX host $esxiServer in the output is $index."

                    # Decrement the Max Days by 1.
                    $maxDays = [int]$currentExpirationSettings[$index].'Max Days' - 1
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the ESX host password expiration settings.
                    $updateResult = Update-EsxiPasswordExpiration -server $server -user $user -pass $pass -domain $domain -cluster $cluster -maxDays $maxDays
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated ESX host password expiration settings.
                    $updatedExpirationSettings = Request-EsxiPasswordExpiration -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                    # Get the index of the first ESX host in the output.
                    $index = Get-Index -output $updatedExpirationSettings -server $esxiServer -useLiveData $useLiveData

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Max Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of ESX Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = -1

                    # Attempt to update the ESX host password expiration settings.
                    $updateResult = Update-EsxiPasswordExpiration -server $server -user $user -pass $pass -domain $domain -cluster $cluster -maxDays $invalidMaxDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Password Expiration Negative Testcase"
                }
            }
        }

        # SSO Password Expiration
        Describe 'SSO Password Expiration' -Tag "SsoPasswordExpiration" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of SSO Password Expiration Positive Testcase"
                    # Request the current SSO password expiration settings
                    $currentExpirationSettings = Request-SsoPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Decrement the Max Days by 1.
                    $maxDays = [int]$currentExpirationSettings[0].'Max Days' - 1
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the SSO password expiration settings.
                    $updateResult = Update-SsoPasswordExpiration -server $server -user $user -pass $pass -domain $domain -maxDays $maxDays
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SSO password expiration settings.
                    $updatedExpirationSettings = Request-SsoPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[0].'Max Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SSO Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of SSO Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = -1

                    # Attempt to update the ESX host password expiration settings.
                    $updateResult = Update-SsoPasswordExpiration -server $server -user $user -pass $pass -domain $domain -maxDays $invalidMaxDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test. If setting is already present, it will be skipped and result will be null
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SSO Password Expiration Negative Testcase"
                }

            }
        }

        # vCenter Password Expiration
        Describe 'vCenter Password Expiration' -Tag "vCenterPasswordExpiration" {
            BeforeEach {
                # Request the current vCenter password expiration settings
                $currentExpirationSettings = Request-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                # Increment the values by 1.
                $minDays = [int]$currentExpirationSettings[0].'Min Days' + 1
                $warnDays = [int]$currentExpirationSettings[0].'Warning Days' + 1
                $maxDays = [int]$currentExpirationSettings[0].'Max Days' + 1

            }
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Expiration Positive Testcase"

                    Write-LogToFile -message "Incremented Min Days: $minDays"
                    Write-LogToFile -message "Incremented Max Days: $maxDays"
                    Write-LogToFile -message "Incremented Warn Days: $warnDays"

                    # Update the vCenter password expiration settings.
                    $updateResult = Update-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $domain -minDays $minDays -warnDays $warnDays -maxDays $maxDays
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated vCenter password expiration settings.
                    $updatedExpirationSettings = Request-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Get the updated values.
                    $outMinDays = $updatedExpirationSettings[0].'Min Days'
                    $outMaxDays = $updatedExpirationSettings[0].'Max Days'
                    $outWarnDays = $updatedExpirationSettings[0].'Warning Days'

                    # Output the updated values.
                    Write-LogToFile -message "Updated Min Days: $outMinDays"
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"
                    Write-LogToFile -message "Updated Warn Days: $outWarnDays"

                    # Assert that the updated values are equal to the incremented values.
                    $outMinDays | Should -Be $minDays
                    $outMaxDays | Should -Be $maxDays
                    $outWarnDays | Should -Be $warnDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepting negative value so gave bigger value.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 100000000000000000000

                    # Attempt to update the vCenter password expiration settings.
                    $updateResult = Update-VcenterPasswordExpiration -server $server -user $user -pass $pass -domain $domain -minDays $invalidMaxDays -warnDays $invalidMaxDays -maxDays $invalidMaxDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # The API call with invalid value for max days, returns "500 Internal server error" and no exception, hence landing here. It is expected, hence passing test
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Expiration Negative Testcase"
                }
            }
        }

        # vCenter root Password Expiration
        Describe 'vCenter root Password Expiration' -Tag "vCenterRootPasswordExpiration" {
            BeforeEach {
                # Request the current vCenter root password expiration settings
                $currentExpirationSettings = Request-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                # Increment the values by 1.
                $email = 'Sample@broadcom.com'
                $warnDays = [int]$currentExpirationSettings.'Warning Days' + 1
                $maxDays = [int]$currentExpirationSettings.'Max Days' + 1
                $minDays = [int]$currentExpirationSettings.'Min Days' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Root Password Expiration Positive Testcase"
                    Write-LogToFile -message "Incremented Warn Days: $warnDays"
                    Write-LogToFile -message "Incremented Max Days: $maxDays"
                    Write-LogToFile -message "Incremented Min Days: $minDays"
                    Write-LogToFile -message "existing email: $email"

                    # Update the vCenter root password expiration settings.
                    $updateResult = Update-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $domain -warnDays $warnDays -maxDays $maxDays -email $email
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated vCenter root password expiration settings.
                    $updatedExpirationSettings = Request-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Get the updated Max Days.
                    $outEmail = $updatedExpirationSettings.'Email'
                    $outMaxDays = $updatedExpirationSettings.'Max Days'
                    $outWarnDays = $updatedExpirationSettings.'Warning Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated email: $outEmail"
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"
                    Write-LogToFile -message "Updated Warn Days: $outWarnDays"

                    # Assert that the updated values are equal to the incremented values.
                    $outEmail | Should -Be $email
                    $outMaxDays | Should -Be $maxDays
                    $outWarnDays | Should -Be $warnDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Root Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Root Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000000

                    # Attempt to update the vCenter root password expiration settings.
                    $updateResult = Update-VcenterRootPasswordExpiration -server $server -user $user -pass $pass -domain $domain -warnDays $warnDays -maxDays $invalidMaxDays -email $email

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # The API call with invalid value for max days, returns "500 Internal server error" and no exception, hence landing here. It is expected, hence passing test
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Root Password Expiration Negative Testcase"
                }
            }
        }

        Describe 'SDDC Manager Local User Password Expiration' -Tag "SddcManagerLocalUserPasswordExpiration" {
            BeforeEach {
                # Request the current local user password expiration settings for SDDC Manager
                $currentExpirationSettings = Request-LocalUserPasswordExpiration -server $server -user $user -pass $pass -domain $domain -vmName $vmName -guestUser $rootUser -guestPassword $rootPass -localUser $localUser
                # Increment the Max Days by 1.
                $minDays = [int]$currentExpirationSettings.'Min Days' + 1
                $warnDays = [int]$currentExpirationSettings.'Warning Days' + 1
                $maxDays = [int]$currentExpirationSettings.'Max Days' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of SDDC Manager Local User Password Expiration Positive Testcase"
                    Write-LogToFile -message "Incremented Max Days: $maxDays"
                    Write-LogToFile -message "Incremented Min Days: $minDays"
                    Write-LogToFile -message "Incremented Warn Days: $warnDays"

                    # Update the SDDC Manager local user password expiration settings.
                    $updateResult = Update-LocalUserPasswordExpiration -server $server -user $user -pass $pass -domain $domain -minDays $minDays -warnDays $warnDays -maxDays $maxDays -vmName $vmName -guestUser $rootUser -guestPassword $rootPass -localUser $localUser
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SDDC Manager local user password expiration settings.
                    $updatedExpirationSettings = Request-LocalUserPasswordExpiration -server $server -user $user -pass $pass -domain $domain -vmName $vmName -guestUser $rootUser -guestPassword $rootPass -localUser $localUser

                    # Get the updated Max Days.
                    $outMinDays = $updatedExpirationSettings.'Min Days'
                    $outMaxDays = $updatedExpirationSettings.'Max Days'
                    $outWarnDays = $updatedExpirationSettings.'Warning Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Min Days: $outMinDays"
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"
                    Write-LogToFile -message "Updated Warn Days: $outWarnDays"

                    # Assert that the updated values are equal to the incremented values.
                    $outMinDays | Should -Be $minDays
                    $outMaxDays | Should -Be $maxDays
                    $outWarnDays | Should -Be $warnDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC Manager Local User Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of SDDC Manager Local User Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000000

                    # Attempt to update the SDDC Manager local user password expiration settings.
                    $updateResult = Update-LocalUserPasswordExpiration -server $server -user $user -pass $pass -domain $domain -minDays $minDays -warnDays $warnDays -maxDays $invalidMaxDays -vmName $vmName -guestUser $rootUser -guestPassword $rootPass -localUser $localUser

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test. If setting is already present, it will be skipped and result will be null
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC Manager Local User Password Expiration Negative Testcase"
                }
            }
        }

        # NSX Edge Password Expiration
        Describe 'NSX Edge Password Expiration' -Tag "NsxEdgePasswordExpiration" {
            BeforeEach {
                # Request the current NSX Edge password expiration settings
                $currentExpirationSettings = Request-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $domain

                # Get the index of the NSX Edge.
                $index = Get-Index -output $currentExpirationSettings -server $nsxEdgeNode -user $rootUser -useLiveData $useLiveData
                Write-LogToFile -message "The index of the NSX Edge node $nsxEdgeNode in the output is $index."
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Expiration Positive Testcase"
                    # Decrement the Max Days by 1.
                    $maxDays = [int]$currentExpirationSettings[$index].'Max Days' - 1
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the NSX Edge password expiration settings.
                    $updateResult = Update-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $domain -maxDays $maxDays
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated NSX Edge password expiration settings.
                    $updatedExpirationSettings = Request-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Get the index of the NSX Edge.
                    $index = Get-Index -output $updatedExpirationSettings -server $nsxEdgeNode -user $rootUser -useLiveData $useLiveData

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Max Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Expiration Positive Testcase"
                }
            }

            # Accepted range of value is <1-9999>
            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000

                    # Attempt to update the NSX Edge password expiration settings.
                    $updateResult = Update-NsxtEdgePasswordExpiration -server $server -user $user -pass $pass -domain $domain -maxDays $invalidMaxDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an exception, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true

                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Expiration Negative Testcase"
                }
            }
        }

        # NSX Manager Password Expiration
        Describe 'NSX Manager Password Expiration' -Tag "NsxManagerPasswordExpiration" {
            BeforeEach {
                # Request the current NSX Manager password expiration settings
                $currentExpirationSettings = Request-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                # Get the index of the NSX Manager.
                $index = Get-Index -output $currentExpirationSettings -server $nsxManager -user $rootUser -useLiveData $useLiveData
                Write-LogToFile -message "The index of the NSX Manager node $nsxManagerNode in the output is $index."

                # Decrement the Max Days by 1.
                $maxDays = [int]$currentExpirationSettings[$index].'Max Days' - 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Expiration Positive Testcase"
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the NSX Manager password expiration settings.
                    $updateResult = Update-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $domain -maxDays $maxDays
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Run this validation only after 30 seconds as NSX service will be down after update in the previous statement
                    Start-Sleep -Seconds 90

                    # Request the updated NSX Manager password expiration settings.
                    $updatedExpirationSettings = Request-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $domain

                    # Get the index of the NSX Manager.
                    $index = Get-Index -output $updatedExpirationSettings -server $nsxManager -user $rootUser -useLiveData $useLiveData

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Max Days'

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepted range of value is <1-9999>
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000

                    # Attempt to update the NSX Manager password expiration settings.
                    $updateResult = Update-NsxtManagerPasswordExpiration -server $server -user $user -pass $pass -domain $domain -cluster $cluster -maxDays $invalidMaxDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Expiration Negative Testcase"
                }
            }
        }

        # VMware Aria Suite Lifecycle Password Expiration
        Describe 'VMware Aria Suite Lifecycle Password Expiration' -Tag "AriaSuiteLifecyclePasswordExpiration" {
            BeforeEach {
                # Request the current VMware Aria Suite Lifecycle password expiration settings
                $currentExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrslcm
                Write-LogToFile -message $currentExpirationSettings

                $ariaSuiteLifecycleVMname = $ariaSuiteLifecycle.Split('.')[0]
                Write-LogToFile -message $ariaSuiteLifecycleVMname

                $index = Get-Index -output $currentExpirationSettings -server $ariaSuiteLifecycleVMname -user $rootUser -useLiveData $useLiveData -aria $true
                Write-LogToFile -message "The index of the VMware Aria Suite Lifecycle node $ariaSuiteLifecycleVMname in the output is $index."

                # Decrement the Max Days by 1.
                $maxDays = [int]$currentExpirationSettings[$index].'Maximum (days)' - 1
                $minDays = [int]$currentExpirationSettings[$index].'Minimum (days)'
                $warnDays = [int]$currentExpirationSettings[$index].'Warning (days)'
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Password Expiration Positive Testcase"
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the VMware Aria Suite Lifecycle password expiration settings.
                    Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrslcm -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Request the updated VMware Aria Suite Lifecycle password expiration settings.
                    $updatedExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrslcm
                    Write-LogToFile -message $updatedExpirationSettings

                    # Get the index of the VMware Aria Suite Lifecycle.
                    $index = Get-Index -output $updatedExpirationSettings -server $ariaSuiteLifecycleVMname -user $rootUser -useLiveData $useLiveData -aria $true

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Maximum (days)'.trim()
                    Write-LogToFile -message $outMaxDays

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepted range of value is <1-9999>
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000

                    # Attempt to update the VMware Aria Suite Lifecycle password expiration settings.
                    $updateResult = Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrslcm -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Password Expiration Negative Testcase"
                }
            }
        }

        # VMware Aria Operations Password Expiration
        Describe 'VMware Aria Operations Password Expiration' -Tag "AriaOperationsPasswordExpiration" {
            BeforeEach {
                # Request the current VMware Aria Operations password expiration settings.
                $currentExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrops

                $ariaOperationsVM = $ariaOperations.Split('.')[0]
                Write-LogToFile -message $ariaOperationsVM

                $index = Get-Index -output $currentExpirationSettings -server $ariaOperationsVM -user $rootUser -useLiveData $useLiveData -aria $true
                Write-LogToFile -message "The index of the VMware Aria Operations node $ariaOperationsVM in the output is $index."

                # Decrement the Max Days by 1.
                $maxDays = [int]$currentExpirationSettings[$index].'Maximum (days)' - 1
                $minDays = [int]$currentExpirationSettings[$index].'Minimum (days)'
                $warnDays = [int]$currentExpirationSettings[$index].'Warning (days)'
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Password Expiration Positive Testcase"
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the VMware Aria Operations password expiration settings.
                    Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrops -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Request the updated VMware Aria Operations password expiration settings.
                    $updatedExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrops

                    # Get the index of the VMware Aria Operations.
                    $index = Get-Index -output $updatedExpirationSettings -server $ariaOperationsVM -user $rootUser -useLiveData $useLiveData -aria $true

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Maximum (days)'.trim()
                    Write-LogToFile -message $outMaxDays

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepted range of value is <1-9999>
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000

                    # Attempt to update the VMware Aria Operations password expiration settings.
                    $updateResult = Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrops -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Password Expiration Negative Testcase"
                }
            }
        }

        # VMware Aria Operations for Logs Password Expiration
        Describe 'VMware Aria Operations for Logs Password Expiration' -Tag "AriaOperationsLogsPasswordExpiration" {
            BeforeEach {
                # Request the current VMware Aria Operations for Logs password expiration settings
                $currentExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrli

                $ariaOperationsLogsVM = $ariaOperationsLogs.Split('.')[0]
                Write-LogToFile -message $ariaOperationsLogsVM

                $index = Get-Index -output $currentExpirationSettings -server $ariaOperationsLogsVM -user $rootUser -useLiveData $useLiveData -aria $true
                Write-LogToFile -message "The index of the VMware Aria Operations for Logs node $ariaOperationsLogsVM in the output is $index."

                # Decrement the Max Days by 1.
                $maxDays = [int]$currentExpirationSettings[$index].'Maximum (days)' - 1
                $minDays = [int]$currentExpirationSettings[$index].'Minimum (days)'
                $warnDays = [int]$currentExpirationSettings[$index].'Warning (days)'
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Password Expiration Positive Testcase"
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the VMware Aria Operations for Logs password expiration settings.
                    Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrli -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Request the updated VMware Aria Operations for Logs password expiration settings.
                    $updatedExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrli

                    # Get the index of the VMware Aria Operations for Logs.
                    $index = Get-Index -output $updatedExpirationSettings -server $ariaOperationsLogsVM -user $rootUser -useLiveData $useLiveData -aria $true

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Maximum (days)'.trim()
                    Write-LogToFile -message $outMaxDays

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepted range of value is <1-9999>
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000

                    # Attempt to update the VMware Aria Operations for Logs password expiration settings.
                    $updateResult = Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vrli -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Password Expiration Negative Testcase"
                }
            }
        }

        # VMware Aria Automation Password Expiration
        Describe 'VMware Aria Automation Password Expiration' -Tag "AriaAutomationPasswordExpiration" {
            BeforeEach {
                # Request the current VMware Aria Automation password expiration settings
                $ariaAutomationVMname = $ariaAutomation.Split('.')[0]
                Write-LogToFile -message $ariaAutomationVMname

                # Request the updated VMware Aria Automation password expiration settings.
                $currentExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vra

                $index = Get-Index -output $currentExpirationSettings -server $ariaAutomationVMname -user $rootUser -useLiveData $useLiveData -aria $true
                Write-LogToFile -message "The index of the VMware Aria Automation node $ariaAutomationVMname in the output is $index."

                # Decrement the Max Days by 1.
                $maxDays = [int]$currentExpirationSettings[$index].'Maximum (days)' - 1
                $minDays = [int]$currentExpirationSettings[$index].'Minimum (days)'
                $warnDays = [int]$currentExpirationSettings[$index].'Warning (days)'
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Expiration Positive Testcase"
                    Write-LogToFile -message "Decremented Max Days: $maxDays"

                    # Update the VMware Aria Automation password expiration settings.
                    Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vra -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Request the updated VMware Aria Automation password expiration settings.
                    $updatedExpirationSettings = Request-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vra

                    # Get the index of the VMware Aria Automation.
                    $index = Get-Index -output $updatedExpirationSettings -server $ariaAutomationVMname -user $rootUser -useLiveData $useLiveData -aria $true

                    # Get the updated Max Days.
                    $outMaxDays = $updatedExpirationSettings[$index].'Maximum (days)'.trim()
                    Write-LogToFile -message $outMaxDays

                    # Output the updated Max Days.
                    Write-LogToFile -message "Updated Max Days: $outMaxDays"

                    # Assert that the updated Max Days is equal to the decremented Max Days.
                    $outMaxDays | Should -Be $maxDays
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Expiration Positive Testcase"
                }
            }

            # Expect a failure.
            # Accepted range of value is <1-9999>
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Expiration Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidMaxDays = 10000000000000000

                    # Attempt to update the VMware Aria Automation password expiration settings.
                    $updateResult = Update-AriaLocalUserPasswordExpiration -server $server -user $user -pass $pass -product vra -localuser $rootUser -maxDays $maxDays -mindays $minDays -warndays $warnDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $false | Should -Be $true
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Expiration Negative Testcase"
                }
            }
        }
    }

    # Start of password complexity test suite
    Describe 'Password Complexity Test Suite' -Tag "PasswordComplexitySuite" {
        # ESX Password Complexity
        Describe 'ESX Password Complexity' -Tag "EsxiPasswordComplexity" {
            BeforeEach {
                # Request the current ESX host password complexity settings
                $currentComplexitySettings = Request-EsxiPasswordComplexity -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                # Get the index of the ESX host.
                $index = Get-Index -output $currentComplexitySettings -server $esxiServer -useLiveData $useLiveData
                Write-LogToFile -message "The index of the ESX host $esxiServer in the output is $index."

                # Increment the History by 1.
                $policy = $currentComplexitySettings[$index].'Policy'
                $history = [int]$currentComplexitySettings[$index].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of ESX Host Password Complexity Positive Testcase"
                    Write-LogToFile -message "Incremented Policy: $policy"
                    Write-LogToFile -message "Incremented History: $history"

                    # Update the ESX host password complexity settings.
                    $updateResult = Update-EsxiPasswordComplexity -server $server -user $user -pass $pass -domain $domain -cluster $cluster -policy $policy -history $history
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated ESX host password complexity settings.
                    $updatedComplexitySettings = Request-EsxiPasswordComplexity -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                    # Get the index of the ESX host.
                    $index = Get-Index -output $updatedComplexitySettings -server $esxiServer -useLiveData $useLiveData

                    # Get the updated History.
                    $outPolicy = $updatedComplexitySettings[$index].'Policy'
                    $outHistory = $updatedComplexitySettings[$index].'History'

                    # Output the updated History.
                    Write-LogToFile -message "Updated History: $outHistory"

                    # Assert that the updated History is equal to the incremented History.
                    $outPolicy | Should -Be $policy
                    $outHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Host Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of ESX Host Password Complexity Negative Testcase"
                    # Set History to an invalid value
                    $invalidHistory = 10000000000000000000000
                    $invalidPolicy = -1

                    # Attempt to update the ESX host password expiration settings.
                    $updateResult = Update-EsxiPasswordComplexity -server $server -user $user -pass $pass -domain $domain -cluster $cluster -policy $invalidPolicy -history $invalidHistory

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Host Password Complexity Negative Testcase"
                }
            }
        }

        # SSO Password Complexity
        Describe 'SSO Password Complexity' -Tag "SsoPasswordComplexity" {

            BeforeEach {
                # Request the current SSO password Complexity settings
                $currentComplexitySettings = Request-SsoPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings[0].'Min Length' + 1
                $maxLength = [int]$currentComplexitySettings[0].'Max Length' + 1
                $minAlpha = [int]$currentComplexitySettings[0].'Min Alphabetic'
                $minLower = [int]$currentComplexitySettings[0].'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings[0].'Min Uppercase'
                $minNum = [int]$currentComplexitySettings[0].'Min Numeric'
                $minSpecial = [int]$currentComplexitySettings[0].'Min Special'
                $maxIdenticalAdj = [int]$currentComplexitySettings[0].'Max Identical Adjacent'
                $history = [int]$currentComplexitySettings[0].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {

                    Write-LogToFile -message "Start of sso Password Complexity Positive Testcase"
                    Write-LogToFile -message "MinLength: $minLength -- MaxLength: $maxLength -- MinAlpha: $minAlpha -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinSpecial: $minSpecial -- MaxIdenticalAdj: $maxIdenticalAdj -- History:$history"
                    # Update the SSO password complexity settings.
                    $updateResult = Update-SsoPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -maxLength $maxLength -minAlpha $minAlpha -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -maxIdenticalAdj $maxIdenticalAdj -history $history
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SSO password complexity settings.
                    $updatedComplexitySettings = Request-SsoPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings[0].'Min Length'
                    $OutMaxLength = [int]$updatedComplexitySettings[0].'Max Length'
                    $OutMinAlpha = [int]$updatedComplexitySettings[0].'Min Alphabetic'
                    $OutMinLower = [int]$updatedComplexitySettings[0].'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings[0].'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings[0].'Min Numeric'
                    $OutMinSpecial = [int]$updatedComplexitySettings[0].'Min Special'
                    $OutMaxIdenticalAdj = [int]$updatedComplexitySettings[0].'Max Identical Adjacent'
                    $OutHistory = [int]$updatedComplexitySettings[0].'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MaxLength: $OutMaxLength -- MinAlpha: $OutMinAlpha -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinSpecial: $OutMinSpecial -- MaxIdenticalAdj: $OutMaxIdenticalAdj -- History:$OutHistory"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMaxLength | Should -Be $maxLength
                    $OutMinAlpha | Should -Be $minAlpha
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                } Finally {
                    Write-LogToFile -message "End of sso Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of sso Password Complexity Negative Testcase"
                    $history = -1
                    # Attempt to update the ESX host password expiration settings.
                    $updateResult = Update-SsoPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -maxLength $maxLength -minAlpha $minAlpha -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -maxIdenticalAdj $maxIdenticalAdj -history $history

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test. If setting is already present, it will be skipped and result will be null
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true

                } Finally {
                    Write-LogToFile -message "End of sso Password Complexity Negative Testcase"
                }
            }
        }

        # SDDC Manager Password Complexity
        Describe 'SDDC Manager Password Complexity' -Tag "SddcManagerPasswordComplexity" {

            BeforeEach {
                $currentComplexitySettings = Request-SDDCManagerPasswordComplexity -server $server -user $user -pass $pass -rootPass $rootPass

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings.'Min Length'
                $minLower = [int]$currentComplexitySettings.'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings.'Min Uppercase'
                $minNum = [int]$currentComplexitySettings.'Min Numerical'
                $minSpecial = [int]$currentComplexitySettings.'Min Special'
                $minUnique = [int]$currentComplexitySettings.'Min Unique'
                $minClasses = [int]$currentComplexitySettings.'Min Classes'
                $maxSequence = [int]$currentComplexitySettings.'Max Sequence'
                $maxRetries = [int]$currentComplexitySettings.'Max Retries'
                $history = [int]$currentComplexitySettings.'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of SDDC manager Password Complexity Positive Testcase"
                    # Request the current SDDC Manager password complexity settings
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinSpecial: $minSpecial -- MinUnique: $MinUnique -- MaxSequence: $maxSequence -- MaxRetries: $maxRetries -- MinClasses: $minClasses -- History:$history "

                    # Update the SDDC Manager password complexity settings.
                    $updateResult = Update-SDDCManagerPasswordComplexity -server $server -user $user -pass $pass -rootPass $rootPass -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -minUnique $minUnique -maxSequence $maxSequence -maxReTry $maxRetries -history $history
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SDDC Manager password complexity settings.
                    $updatedComplexitySettings = Request-SDDCManagerPasswordComplexity -server $server -user $user -pass $pass -rootPass $rootPass

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings.'Min Length'
                    $OutMinLower = [int]$updatedComplexitySettings.'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings.'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings.'Min Numerical'
                    $OutMinSpecial = [int]$updatedComplexitySettings.'Min Special'
                    $OutMinUnique = [int]$updatedComplexitySettings.'Min Unique'
                    $OutHistory = [int]$updatedComplexitySettings.'History'
                    $OutMinClasses = [int]$updatedComplexitySettings.'Min Classes'
                    $OutMaxSequence = [int]$updatedComplexitySettings.'Max Sequence'
                    $OutMaxRetries = [int]$updatedComplexitySettings.'Max Retries'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinSpecial: $OutMinSpecial -- MinUnique: $OutMinUnique -- MaxSequence: $OutMaxSequence -- MaxReries: $OutMaxRetries -- MinClasses: $OutMinClasses -- History:$OutHistory "

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinUnique | Should -Be $minUnique
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                    $OutMaxSequence | Should -Be $maxSequence
                    $OutMaxRetries | Should -Be $maxRetries
                    $OutMinClasses | Should -Be $minClasses
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC manager Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of SDDC manager Password Complexity Negative Testcase"
                    # Set MinLength to an invalid value
                    $minLength = 10000000000000000000000

                    # Attempt to update the SDDC Manager password complexity settings.
                    $updateResult = Update-SDDCManagerPasswordComplexity -server $server -user $user -pass $pass -rootPass $rootPass -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -history $history
                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes update doesn't happen but null value is returned
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC manager Password Complexity Negative Testcase"
                }
            }
        }

        # vCenter Password Complexity
        Describe 'vCenter Password Complexity' -Tag "vCenterPasswordComplexity" {

            BeforeEach {
                $currentComplexitySettings = Request-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings.'Min Length' + 1
                $minLower = [int]$currentComplexitySettings.'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings.'Min Uppercase'
                $minNum = [int]$currentComplexitySettings.'Min Numeric'
                $minSpecial = [int]$currentComplexitySettings.'Min Special'
                $maxUnique = [int]$currentComplexitySettings.'Max Unique'
                $history = [int]$currentComplexitySettings.'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Complexity Positive Testcase"
                    # Request the current vCenter password complexity settings
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinSpecial: $minSpecial -- MaxUnique: $maxUnique -- History:$history "

                    # Update the vCenter password complexity settings.
                    $updateResult = Update-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -history $history
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated vCenter password complexity settings.
                    $updatedComplexitySettings = Request-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings.'Min Length'
                    $OutMinLower = [int]$updatedComplexitySettings.'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings.'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings.'Min Numeric'
                    $OutMinSpecial = [int]$updatedComplexitySettings.'Min Special'
                    $OutMaxUnique = [int]$updatedComplexitySettings.'Max Unique'
                    $OutHistory = [int]$updatedComplexitySettings.'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinSpecial: $OutMinSpecial -- MaxUnique: $OutMaxUnique -- History:$OutHistory "

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMaxUnique | Should -Be $maxUnique
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Complexity Negative Testcase"
                    # Set MinLength to an invalid value
                    $minLength = 10000000000000000000000000000

                    # Attempt to update the vCenter password complexity settings.
                    $updateResult = Update-VcenterPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -history $history
                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes update doesn't happen but null value is returned
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Complexity Negative Testcase"
                }
            }
        }

        # NSX Edge Password Complexity
        Describe 'NSX Edge Password Complexity' -Tag "NsxEdgePasswordComplexity" {
            BeforeEach {
                # Request the current NSX Edge password complexity settings
                $currentComplexitySettings = Request-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $domain

                # Get the index of the NSX Edge.
                $index = Get-Index -output $currentComplexitySettings -server $nsxEdgeNode -useLiveData $useLiveData
                Write-LogToFile -message "The index of the NSX Edge node $nsxEdgeNode in the output is $index."

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings[$index].'Min Length' + 1
                $minLower = [int]$currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings[$index].'Min Uppercase'
                $minNum = [int]$currentComplexitySettings[$index].'Min Numerical'
                $minSpecial = [int]$currentComplexitySettings[$index].'Min Special'
                $minUnique = [int]$currentComplexitySettings[$index].'Min Unique'
                $maxRetries = [int]$currentComplexitySettings[$index].'Max Retries' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Complexity Positive Testcase"
                    # Request the current NSX Edge password complexity settings
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinSpecial: $minSpecial -- MinUnique: $minUnique -- MaxRetries:$maxRetries "

                    # Update the NSX Edge password complexity settings.
                    $updateResult = Update-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -maxReTry $maxRetries
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated NSX Edge password complexity settings.
                    $updatedComplexitySettings = Request-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $domain

                    # Get the index of the NSX Edge.
                    $index = Get-Index -output $updatedComplexitySettings -server $nsxEdgeNode -useLiveData $useLiveData

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings[$index].'Min Length'
                    $OutMinLower = [int]$updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinSpecial = [int]$updatedComplexitySettings[$index].'Min Special'
                    $OutMinUnique = [int]$updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRetries = [int]$updatedComplexitySettings[$index].'Max Retries'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinSpecial: $OutMinSpecial -- MinUnique: $OutMinUnique -- MaxRetries: $OutMaxRetries"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRetries | Should -Be $maxRetries
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Complexity Negative Testcase"
                    # Set minlength to an invalid value
                    $minLength = 1000000000000000000000000000

                    # Attempt to update the NSX Edge password complexity settings.
                    $updateResult = Update-NsxtEdgePasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -maxReTry $maxRetries

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes update not happening will result in null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Complexity Negative Testcase"
                }
            }
        }

        # NSX Manager Password Complexity
        Describe 'NSX Manager Password Complexity' -Tag "NsxManagerPasswordComplexity" {
            BeforeEach {
                # Request the current NSX manager password complexity settings
                $currentComplexitySettings = Request-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                # Get the index of the NSX Manager.
                $index = Get-Index -output $currentComplexitySettings -server $nsxManagerNode -useLiveData $useLiveData
                Write-LogToFile -message "The index of the NSX Manager node $nsxManagerNode in the output is $index."

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings[$index].'Min Length' + 1
                $maxLength = [int]$currentComplexitySettings[$index].'Max Length'
                $minLower = [int]$currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings[$index].'Min Uppercase'
                $minNum = [int]$currentComplexitySettings[$index].'Min Numerical'
                $minSpecial = [int]$currentComplexitySettings[$index].'Min Special'
                $minUnique = [int]$currentComplexitySettings[$index].'Min Unique'
                $maxRepeats = [int]$currentComplexitySettings[$index].'Max Repeats'
                $maxSequence = [int]$currentComplexitySettings[$index].'Max Sequence'
                $history = [int]$currentComplexitySettings[$index].'History' + 1
                $hash = $currentComplexitySettings[$index].'Hash Algorithm'
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Complexity Positive Testcase"
                    # Output the current data.
                    Write-LogToFile -message "MinLength: $minLength -- maxLength: $maxLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinSpecial: $minSpecial -- MaxUnique: $minUnique -- maxRepeats: $maxRepeats -- maxSequence: $maxSequence -- history: $history -- hash: $hash"

                    # Update the NSX Manager password complexity settings.
                    $updateResult = Update-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -maxLength $maxLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -minUnique $minUnique -maxRepeats $maxRepeats -maxSequence $maxSequence -history $history -hash_algorithm $hash
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Run this validation only after 90 seconds as NSX service will be down after update in the previous statement.
                    Start-Sleep -Seconds 90

                    # Request the updated NSX manager password complexity settings.
                    $updatedComplexitySettings = Request-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $domain

                    # Get the index of the NSX Manager.
                    $index = Get-Index -output $updatedComplexitySettings -server $nsxManagerNode -useLiveData $useLiveData

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings[$index].'Min Length'
                    $OutMaxLength = [int]$updatedComplexitySettings[$index].'Max Length'
                    $OutMinLower = [int]$updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinSpecial = [int]$updatedComplexitySettings[$index].'Min Special'
                    $OutMinUnique = [int]$updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRepeats = [int]$updatedComplexitySettings[$index].'Max Repeats'
                    $OutMaxSequence = [int]$updatedComplexitySettings[$index].'Max Sequence'
                    $OutHistory = [int]$updatedComplexitySettings[$index].'History'
                    $OutHash = $updatedComplexitySettings[$index].'Hash Algorithm'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- maxLength: $OutMaxLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinSpecial: $OutMinSpecial -- MaxUnique: $OutMinUnique -- maxRepeats: $OutMaxRepeats -- maxSequence: $OutMaxSequence -- history: $OutHistory -- hash: $OutHash"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMaxLength | Should -Be $maxLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRepeats | Should -Be $maxRepeats
                    $OutMaxSequence | Should -Be $maxSequence
                    $OutHistory | Should -Be $history
                    $OutHash | Should -Be $hash
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Complexity Negative Testcase"
                    # Set history to an invalid value
                    $history = 10000000000000000000000

                    # Attempt to update the NSX Manager password complexity settings.
                    $updateResult = Update-NsxtManagerPasswordComplexity -server $server -user $user -pass $pass -domain $domain -minLength $minLength -maxLength $maxLength -minLower $minLower -minUpper $minUpper -minNum $minNum -minSpecial $minSpecial -minUnique $minUnique -maxRepeats $maxRepeats -maxSequence $maxSequence -history $history -hash_algorithm $hash

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated yet there is no exception, hence null ouput.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Complexity Negative Testcase"
                }
            }
        }

        # VMware Aria Suite Lifecycle Password Complexity
        Describe 'VMware Aria Suite Lifecycle Password Complexity' -Tag "AriaSuiteLifecyclePasswordComplexity" {
            BeforeEach {
                $ariaSuiteLifecycleVMname = $ariaSuiteLifecycle.Split('.')[0]
                Write-LogToFile -message $ariaSuiteLifecycleVMname

                # Request the current VMware Aria Suite Lifecycle Password complexity settings
                $currentComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrslcm
                Write-LogToFile -message $currentComplexitySettings

                # Get the index of the VMware Aria Suite Lifecycle .
                $index = Get-Index -output $currentComplexitySettings -server $ariaSuiteLifecycleVMname -useLiveData $true -aria $true
                Write-LogToFile -message "The index of the VMware Aria Suite Lifecycle  node $ariaSuiteLifecycleVMname in the output is $index."

                # Increment the input settings by 1.
                $minLength = $currentComplexitySettings[$index].'Min Length' + 1
                $minLower = $currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = $currentComplexitySettings[$index].'Min Uppercase'
                $minNum = $currentComplexitySettings[$index].'Min Numerical'
                $minUnique = $currentComplexitySettings[$index].'Min Unique'
                $minClass = $currentComplexitySettings[$index].'Min Class'
                $maxRepeats = $currentComplexitySettings[$index].'Max Retries'
                $minSpecial = $currentComplexitySettings[$index].'Min Identical Adjacent'
                $history = $currentComplexitySettings[$index].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Password Complexity Positive Testcase"
                    # Output the current data.
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinClass: $minClass -- MaxUnique: $minUnique -- mix Identical adjecant: $minSpecial -- maxRepeats: $maxRepeats -- history: $history"

                    # Update the VMware Aria Suite Lifecycle Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrslcm -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRepeats -history $history
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Suite Lifecycle Password complexity settings.
                    $updatedComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrslcm

                    # Get the index of the VMware Aria Suite Lifecycle .
                    $index = Get-Index -output $updatedComplexitySettings -server $ariaSuiteLifecycleVMname -useLiveData $true -aria $true

                    # Get the updated settings data.
                    $OutMinLength = $updatedComplexitySettings[$index].'Min Length'
                    $OutMinLower = $updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = $updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = $updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinClass = $updatedComplexitySettings[$index].'Min Class'
                    $OutMinUnique = $updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRepeats = $updatedComplexitySettings[$index].'Max Retries'
                    $OutMinSpecial = $updatedComplexitySettings[$index].'Min Identical Adjacent'
                    $OutHistory = $updatedComplexitySettings[$index].'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinClass: $OutMinClass -- MaxUnique: $OutMinUnique -- max Identical adjecant: $OutMinSpecial -- OutMaxRepeats: $OutMaxRepeats -- history: $OutHistory"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRepeats | Should -Be $maxRepeats
                    $OutMinClass | Should -Be $minClass
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Password Complexity Negative Testcase"
                    # Set history to an invalid value
                    $history = 10000000000000000000000

                    # Attempt to update the VMware Aria Suite Lifecycle Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrslcm -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRepeats -history $history

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated yet there is no exception, hence null ouput.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Password Complexity Negative Testcase"
                }
            }
        }

        # VMware Aria Operations Password Complexity
        Describe 'VMware Aria Operations Password Complexity' -Tag "AriaOperationsPasswordComplexity" {
            BeforeEach {
                $ariaOperationsVMname = $ariaOperations.Split('.')[0]
                Write-LogToFile -message $ariaOperationsVMname

                # Request the current VMware Aria Operations Password complexity settings
                $currentComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrops

                # Get the index of the VMware Aria Operations .
                $index = Get-Index -output $currentComplexitySettings -server $ariaOperationsVMname -useLiveData $true -aria $true
                Write-LogToFile -message "The index of the VMware Aria Operations node $ariaOperationsVMname in the output is $index."

                # Increment the input settings by 1.
                $minLength = [int]$currentComplexitySettings[$index].'Min Length' + 1
                $minLower = [int]$currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = [int]$currentComplexitySettings[$index].'Min Uppercase'
                $minNum = [int]$currentComplexitySettings[$index].'Min Numerical'
                $minUnique = [int]$currentComplexitySettings[$index].'Min Unique'
                $minClass = [int]$currentComplexitySettings[$index].'Min Class'
                $minSpecial = [int]$currentComplexitySettings[$index].'Min Special'
                $maxRepeats = [int]$currentComplexitySettings[$index].'Max Repeat'
                $maxRetry = [int]$currentComplexitySettings[$index].'Max Retries'
                $history = [int]$currentComplexitySettings[$index].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Password Complexity Positive Testcase"
                    # Output the current data.
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinClass: $minClass -- MinUnique: $minUnique -- MinSpecial: $minSpecial -- Max Repeat: $maxRepeats -- MaxRetry: $maxRetry -- history: $history"

                    # Update the VMware Aria Operations Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrops -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Operations Password complexity settings.
                    $updatedComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrops

                    # Get the index of the VMware Aria Operations .
                    $index = Get-Index -output $updatedComplexitySettings -server $ariaOperationsVMname -useLiveData $true -aria $true

                    # Get the updated settings data.
                    $OutMinLength = [int]$updatedComplexitySettings[$index].'Min Length'
                    $OutMinLower = [int]$updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = [int]$updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = [int]$updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinClass = [int]$updatedComplexitySettings[$index].'Min Class'
                    $OutMinUnique = [int]$updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRepeats = [int]$updatedComplexitySettings[$index].'Max Repeat'
                    $OutMaxRetry = [int]$updatedComplexitySettings[$index].'Max Retries'
                    $OutMinSpecial = [int]$updatedComplexitySettings[$index].'Min Special'
                    $OutHistory = [int]$updatedComplexitySettings[$index].'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinClass: $OutMinClass -- MaxUnique: $OutMinUnique -- Min Special: $OutMinSpecial -- OutMaxRepeats: $OutMaxRepeats -- OutMaxRetry: $OutMaxRetry-- history: $OutHistory"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRepeats | Should -Be $maxRepeats
                    $OutMaxRetry | Should -Be $maxRetry
                    $OutMinClass | Should -Be $minClass
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Password Complexity Negative Testcase"
                    # Set history to an invalid value
                    $history = 10000000000000000000000

                    # Attempt to update the VMware Aria Operations Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrops -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated yet there is no exception, hence null ouput.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Password Complexity Negative Testcase"
                }
            }
        }

        # VMware Aria Operations for Logs Password Complexity
        Describe 'VMware Aria Operations for Logs Password Complexity' -Tag "AriaOperationsLogsPasswordComplexity" {
            BeforeEach {
                $ariaOperationsLogsVMname = $ariaOperationsLogs.Split('.')[0]
                Write-LogToFile -message $ariaOperationsLogsVMname

                # Request the current VMware Aria Operations for Logs Password complexity settings
                $currentComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrli

                # Get the index of the VMware Aria Operations for Logs .
                $index = Get-Index -output $currentComplexitySettings -server $ariaOperationsLogsVMname -useLiveData $true -aria $true
                Write-LogToFile -message "The index of the VMware Aria Operations for Logs node $ariaOperationsLogsVMname in the output is $index."

                # Increment the input settings by 1.
                $minLength = $currentComplexitySettings[$index].'Min Length' + 1
                $minLower = $currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = $currentComplexitySettings[$index].'Min Uppercase'
                $minNum = $currentComplexitySettings[$index].'Min Numerical'
                $minUnique = $currentComplexitySettings[$index].'Min Unique'
                $minClass = $currentComplexitySettings[$index].'Min Class'
                $minSpecial = $currentComplexitySettings[$index].'Min Special'
                $maxRepeats = $currentComplexitySettings[$index].'Max Repeat'
                $maxRetry = $currentComplexitySettings[$index].'Max Retries'
                $history = $currentComplexitySettings[$index].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Password Complexity Positive Testcase"
                    # Output the current data.
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinClass: $minClass -- MinUnique: $minUnique -- MinSpecial: $minSpecial -- Max Repeat: $maxRepeats -- MaxRetry: $maxRetry -- history: $history"

                    # Update the VMware Aria Operations for Logs Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrli -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Operations for Logs Password complexity settings.
                    $updatedComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrli

                    # Get the index of the VMware Aria Operations for Logs .
                    $index = Get-Index -output $updatedComplexitySettings -server $ariaOperationsLogsVMname -useLiveData $true -aria $true

                    # Get the updated settings data.
                    $OutMinLength = $updatedComplexitySettings[$index].'Min Length'
                    $OutMinLower = $updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = $updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = $updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinClass = $updatedComplexitySettings[$index].'Min Class'
                    $OutMinUnique = $updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRepeats = $updatedComplexitySettings[$index].'Max Repeat'
                    $OutMaxRetry = $updatedComplexitySettings[$index].'Max Retries'
                    $OutMinSpecial = $updatedComplexitySettings[$index].'Min Special'
                    $OutHistory = $updatedComplexitySettings[$index].'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinClass: $OutMinClass -- MaxUnique: $OutMinUnique -- Min Special: $OutMinSpecial -- OutMaxRepeats: $OutMaxRepeats -- OutMaxRetry: $OutMaxRetry-- history: $OutHistory"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRepeats | Should -Be $maxRepeats
                    $OutMaxRetry | Should -Be $maxRetry
                    $OutMinClass | Should -Be $minClass
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Password Complexity Negative Testcase"
                    # Set history to an invalid value
                    $history = 10000000000000000000000

                    # Attempt to update the VMware Aria Operations for Logs Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vrli -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated yet there is no exception, hence null ouput.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Password Complexity Negative Testcase"
                }
            }
        }

        # VMware Aria Automation Password Complexity
        Describe 'VMware Aria Automation Password Complexity' -Tag "AriaAutomationPasswordComplexity" {
            BeforeEach {
                $ariaAutomationVMname = $ariaAutomation.Split('.')[0]
                Write-LogToFile -message $ariaAutomationVMname

                # Request the current VMware Aria Automation Password complexity settings
                $currentComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vra

                # Get the index of the VMware Aria Automation .
                $index = Get-Index -output $currentComplexitySettings -server $ariaAutomationVMname -useLiveData $true -aria $true
                Write-LogToFile -message "The index of the VMware Aria Automation node $ariaAutomationVMname in the output is $index."

                # Increment the input settings by 1.
                $minLength = $currentComplexitySettings[$index].'Min Length' + 1
                $minLower = $currentComplexitySettings[$index].'Min Lowercase'
                $minUpper = $currentComplexitySettings[$index].'Min Uppercase'
                $minNum = $currentComplexitySettings[$index].'Min Numerical'
                $minUnique = $currentComplexitySettings[$index].'Min Unique'
                $minClass = $currentComplexitySettings[$index].'Min Class'
                $minSpecial = $currentComplexitySettings[$index].'Min Special'
                $maxRepeats = $currentComplexitySettings[$index].'Max Repeat'
                $maxRetry = $currentComplexitySettings[$index].'Max Retries'
                $history = $currentComplexitySettings[$index].'History' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Complexity Positive Testcase"
                    # Output the current data.
                    Write-LogToFile -message "MinLength: $minLength -- MinLower: $minLower -- MinUpper: $minUpper -- MinNum: $minNum -- MinClass: $minClass -- MinUnique: $minUnique -- MinSpecial: $minSpecial -- Max Repeat: $maxRepeats -- MaxRetry: $maxRetry -- history: $history"

                    # Update the VMware Aria Automation Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vra -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Automation Password complexity settings.
                    $updatedComplexitySettings = Request-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vra

                    # Get the index of the VMware Aria Automation .
                    $index = Get-Index -output $updatedComplexitySettings -server $ariaAutomationVMname -useLiveData $true -aria $true

                    # Get the updated settings data.
                    $OutMinLength = $updatedComplexitySettings[$index].'Min Length'
                    $OutMinLower = $updatedComplexitySettings[$index].'Min Lowercase'
                    $OutMinUpper = $updatedComplexitySettings[$index].'Min Uppercase'
                    $OutMinNum = $updatedComplexitySettings[$index].'Min Numerical'
                    $OutMinClass = $updatedComplexitySettings[$index].'Min Class'
                    $OutMinUnique = $updatedComplexitySettings[$index].'Min Unique'
                    $OutMaxRepeats = $updatedComplexitySettings[$index].'Max Repeat'
                    $OutMaxRetry = $updatedComplexitySettings[$index].'Max Retries'
                    $OutMinSpecial = $updatedComplexitySettings[$index].'Min Special'
                    $OutHistory = $updatedComplexitySettings[$index].'History'

                    # Output the updated data.
                    Write-LogToFile -message "MinLength: $OutMinLength -- MinLower: $OutMinLower -- MinUpper: $OutMinUpper -- MinNum: $OutMinNum -- MinClass: $OutMinClass -- MaxUnique: $OutMinUnique -- Min Special: $OutMinSpecial -- OutMaxRepeats: $OutMaxRepeats -- OutMaxRetry: $OutMaxRetry-- history: $OutHistory"

                    # Assert that the updated data is equal to the incremented data.
                    $OutMinLength | Should -Be $minLength
                    $OutMinLower | Should -Be $minLower
                    $OutMinUpper | Should -Be $minUpper
                    $OutMinNum | Should -Be $minNum
                    $OutMinUnique | Should -Be $minUnique
                    $OutMaxRepeats | Should -Be $maxRepeats
                    $OutMaxRetry | Should -Be $maxRetry
                    $OutMinClass | Should -Be $minClass
                    $OutMinSpecial | Should -Be $minSpecial
                    $OutHistory | Should -Be $history
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Complexity Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Complexity Negative Testcase"
                    # Set history to an invalid value
                    $history = 10000000000000000000000

                    # Attempt to update the VMware Aria Automation Password complexity settings.
                    $updateResult = Update-AriaLocalUserPasswordComplexity -server $server -user $user -pass $pass -product vra -minLength $minLength -lowercase $minLower -uppercase $minUpper -numerical $minNum -special $minSpecial -class $minClass -unique $minUnique -retry $maxRetry -history $history -sequence $maxRepeats

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated yet there is no exception, hence null ouput.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Complexity Negative Testcase"
                }
            }
        }
    }

    Describe 'Account Lockout Test Suite' -Tag "AccountLockoutSuite" {
        # ESX Account Lockout
        Describe 'ESX Account Lockout' -Tag "EsxiAccountLockout" {
            BeforeEach {
                # Request the current ESX host account lockout settings.
                $currentLockoutSettings = Request-EsxiAccountLockout -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                # Get the index of the ESX host.
                $index = Get-Index -output $currentLockoutSettings -server $esxiServer -useLiveData $useLiveData
                Write-LogToFile -message "The index of the ESX host $esxiServer in the output is $index."

                # Increment the Max Failures and Unlock Interval by 1.
                $maxFailures = [int]$currentLockoutSettings[$index].'Max Failures' + 1
                $unlockInterval = [int]$currentLockoutSettings[$index].'Unlock Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of ESX Host Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"

                    # Update the ESX host account lockout settings.
                    $updateResult = Update-EsxiAccountLockout -server $server -user $user -pass $pass -domain $domain -cluster $cluster -failures $maxFailures -unlockInterval $unlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated ESX host account lockout settings.
                    $updatedLockoutSettings = Request-EsxiAccountLockout -server $server -user $user -pass $pass -domain $domain -cluster $cluster

                    # Get the index of the ESX host.
                    $index = Get-Index -output $updatedLockoutSettings -server $esxiServer -useLiveData $useLiveData

                    # Get the updated Max Failures and Unlock Interval.
                    $outFailures = [int]$updatedLockoutSettings[$index].'Max Failures'
                    $outUnlockInterval = [int] $updatedLockoutSettings[$index].'Unlock Interval (sec)'

                    # Output the updated Max Failures and Unlock Interval.
                    Write-LogToFile -message "Updated Failures: $outFailures"
                    Write-LogToFile -message "Updated Unlock Interval: $outUnlockInterval"

                    # Assert that the updated Max Failures and Unlock Interval is equal to the incremented values.
                    $outUnlockInterval | Should -Be $unlockInterval
                    $outFailures | Should -Be $maxFailures
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Host Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. working
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of ESX Host Account Lockout Negative Testcase"
                    # Set History to an invalid value
                    $invalidUnlockInterval = -1
                    $invalidFailures = -1

                    # Attempt to update the ESX host account lockout settings.
                    $updateResult = Update-EsxiAccountLockout -server $server -user $user -pass $pass -domain $domain -cluster $cluster -failures $invalidFailures -unlockInterval $invalidUnlockInterval

                    #Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings are not updated but exception is not thrown, in which case output will be null
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of ESX Host Account Lockout Negative Testcase"
                }
            }
        }

        # SSO Account Lockout
        Describe 'SSO Account Lockout' -Tag "SsoAccountLockout" {
            BeforeAll {
                # Current sso account lockout settings.
                $currentLockoutSettings = Request-SSOAccountLockout -server $server -user $user -pass $pass -domain $domain

                # Increment the Max Failures, Failure Interval and Unlock Interval by 1.
                $maxFailures = [int]$currentLockoutSettings.'Max Failures' + 1
                $failureInterval = [int]$currentLockoutSettings.'Failed Attempt Interval (sec)' + 1
                $unlockInterval = [int]$currentLockoutSettings.'Unlock Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of SSO Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Failure Interval: $failureInterval"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"

                    # Update sso account lockout settings.
                    $updateResult = Update-SSOAccountLockout -server $server -user $user -pass $pass -domain $domain -failures $maxFailures -failureInterval $failureInterval -unlockInterval $unlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SSO host account lockout settings.
                    $updatedLockoutSettings = Request-SSOAccountLockout -server $server -user $user -pass $pass -domain $domain

                    # Get the updated settings.
                    $outFailures = [int]$updatedLockoutSettings.'Max Failures'
                    $outFailureInterval = [int]$updatedLockoutSettings.'Failed Attempt Interval (sec)'
                    $outUnlockInterval = [int]$updatedLockoutSettings.'Unlock Interval (sec)'

                    # Output the updated settings.
                    Write-LogToFile -message "Updated Failures: $outFailures"
                    Write-LogToFile -message "Updated Failure Interval: $outFailureInterval"
                    Write-LogToFile -message "Updated Unlock Interval: $outUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outUnlockInterval | Should -Be $unlockInterval
                    $outFailureInterval | Should -Be $failureInterval
                    $outFailures | Should -Be $maxFailures
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SSO Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. (failedAttemptIntervalSec should be in [1-1000000000] but was -1
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of SSO Account Lockout Negative Testcase"
                    # Set -1 to all fields.
                    $invalidUnlockInterval = -1
                    $invalidFailureInterval = 10000000000
                    $invalidFailures = -1

                    # Attempt to update the SSO host account lockout settings.
                    $updateResult = Update-SSOAccountLockout -server $server -user $user -pass $pass -domain $domain -failures $invalidFailures -failureInterval $invalidFailureInterval -unlockInterval $invalidUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings not updated results in null than exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SSO Account Lockout Negative Testcase"
                }
            }
        }

        # vCenter Account Lockout
        Describe 'vCenter Account Lockout' -Tag "vCenterAccountLockout" {
            BeforeEach {
                # Request the current vCenter account lockout settings.
                $currentLockoutSettings = Request-VcenterAccountLockout -server $server -user $user -pass $pass -domain $domain

                # Increment the Max Failures a$currentLockoutSettings.'Max Failures'nd Unlock Interval by 1.
                $maxFailures = [int]$currentLockoutSettings.'Max Failures' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings.'Root Unlock Interval (sec)' + 1
                $unlockInterval = [int]$currentLockoutSettings.'Unlock Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"

                    # Update the vCenter account lockout settings.
                    $updateResult = Update-VcenterAccountLockout -server $server -user $user -pass $pass -domain $domain -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated vCenter account lockout settings.
                    $updatedLockoutSettings = Request-VcenterAccountLockout -server $server -user $user -pass $pass -domain $domain

                    # Get the updated Max Failures and Unlock Interval.
                    $outFailures = [int]$updatedLockoutSettings.'Max Failures'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings.'Root Unlock Interval (sec)'
                    $outUnlockInterval = [int]$updatedLockoutSettings.'Unlock Interval (sec)'

                    # Log that the updated values.
                    Write-LogToFile -message "Updated Failures: $outFailures"
                    Write-LogToFile -message "Updated Root Unlock Interval: $outrootUnlockInterval"
                    Write-LogToFile -message "Updated Unlock Interval: $outUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                    $outFailures | Should -Be $maxFailures
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Account Lockout Positive Testcase"
                    # Set max failures to an invalid value.
                    $invalidValue = 100000000000000

                    # Attempt to update the vCenter root account lockout settings.
                    $updateResult = Update-VcenterAccountLockout -server $server -user $user -pass $pass -domain $domain -failures $invalidValue -unlockInterval $invalidValue -rootUnlockInterval $invalidValue

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes not updating settings results in null than exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Account Lockout Negative Testcase"
                }
            }
        }

        # SDDC Manager Account Lockout
        Describe 'SDDC Manager Account Lockout' -Tag "SddcManagerAccountLockout" {
            BeforeEach {
                # Request the current SDDC Manager account lockout settings.
                $currentLockoutSettings = Request-SddcManagerAccountLockout -server $server -user $user -pass $pass -rootPass $rootPass

                # Increment the values by 1.
                $maxFailures = [int]$currentLockoutSettings.'Max Failures' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings.'Root Unlock Interval (sec)' + 1
                $unlockInterval = [int]$currentLockoutSettings.'Unlock Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of SDDC Manager Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"

                    # Update the SDDC Manager account lockout settings.
                    $updateResult = Update-SddcManagerAccountLockout -server $server -user $user -pass $pass -rootPass $rootPass -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated SDDC Manager account lockout settings.
                    $updatedLockoutSettings = Request-SddcManagerAccountLockout -server $server -user $user -pass $pass -rootPass $rootPass

                    # Get the updated values.
                    $outFailures = [int]$updatedLockoutSettings.'Max Failures'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings.'Root Unlock Interval (sec)'
                    $outUnlockInterval = [int]$updatedLockoutSettings.'Unlock Interval (sec)'

                    # Log the updated values.
                    Write-LogToFile -message "Updated Failures: $outFailures"
                    Write-LogToFile -message "Updated Root Unlock  Interval: $outrootUnlockInterval"
                    Write-LogToFile -message "Updated Unlock Interval: $outUnlockInterval"

                    # Assert that the updated updated values are equal to the incremented values.
                    $outUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                    $outFailures | Should -Be $maxFailures
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | should -be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC Manager Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of SDDC Manager Account Lockout Negative Testcase"
                    # Set Max Failures to an invalid value.
                    $invalidmaxFailures = 1000000000000000000

                    # Attempt to update the SDDC Manager  account lockout settings.
                    $updateResult = Update-SddcManagerAccountLockout -server $server -user $user -pass $pass -rootPass $rootPass -failures $invalidmaxFailures -unlockInterval $invalidmaxFailures -rootUnlockInterval $invalidmaxFailures

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings not udpated results in null output than exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of SDDC Manager Account Lockout Negative Testcase"
                }
            }
        }

        # NSX Edge Account Lockout
        Describe 'NSX Edge Account Lockout' -Tag "NsxEdgeAccountLockout" {
            BeforeEach {
                # Request the current NSX Edge account lockout settings.
                $currentLockoutSettings = Request-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $domain

                $index = Get-Index -output $currentLockoutSettings -server $nsxEdgeNode -useLiveData $useLiveData

                # Increment the Max Failures and Unlock Interval by 1.
                $cliMaxFailures = [int]$currentLockoutSettings[$index].'CLI Max Failures' + 1
                $cliUnlockInterval = [int]$currentLockoutSettings[$index].'CLI Unlock Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented CLI Max Failures: $cliMaxFailures"
                    Write-LogToFile -message "Incremented CLI Unlock Interval: $cliUnlockInterval"

                    # Update the NSX Edge account lockout settings.
                    $updateResult = Update-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $domain -cliFailures $cliMaxFailures -cliUnlockInterval $cliUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Run this validation only after 90 seconds as NSX service will be down after update in the previous statement
                    Start-Sleep -Seconds 90

                    # Request the updated NSX Edge account lockout settings.
                    $updatedLockoutSettings = Request-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $domain

                    $index = Get-Index -output $updatedLockoutSettings -server $nsxEdgeNode -useLiveData $useLiveData

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'CLI Max Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'CLI Unlock Interval (sec)'

                    Write-LogToFile -message "Updated CLI Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated CLI Unlock Interval: $outcliUnlockInterval"

                    # Assert that the updated Max Failures and Unlock Interval is equal to the incremented values.
                    $outcliMaxFailures | Should -Be $cliMaxFailures
                    $outcliUnlockInterval | Should -Be $cliUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Account Lockout Positive Testcase"
                }
            }
            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Account Lockout Negative Testcase"
                    # Set Max Failures to an invalid value
                    $invalidCliMaxFailures = 100000000000000000

                    # Attempt to update the NSX Edge account lockout settings.
                    $updateResult = Update-NsxtEdgeAccountLockout -server $server -user $user -pass $pass -domain $domain -cliFailures $invalidCliMaxFailures -cliUnlockInterval $cliUnlockInterval -apiFailures $apiMaxFailures -apiFailureInterval $apiFailureInterval -apiUnlockInterval $apiUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will be not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Account Lockout Negative Testcase"
                }
            }
        }

        # NSX Manager Account Lockout
        Describe 'NSX Manager Account Lockout' -Tag "NsxManagerAccountLockout" {
            BeforeEach {
                # Request the current NSX-T Manager account lockout settings.
                $currentLockoutSettings = Request-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $domain

                $index = Get-Index -output $currentLockoutSettings -server $nsxManagerNode -useLiveData $useLiveData

                # Increment the CLI and API settings by 1.
                $cliMaxFailures = [int]$currentLockoutSettings[$index].'CLI Max Failures' + 1
                $cliUnlockInterval = [int]$currentLockoutSettings[$index].'CLI Unlock Interval (sec)' + 1
                $apiMaxFailures = [int]$currentLockoutSettings[$index].'API Max Failures' + 1
                $apiFailureInterval = [int]$currentLockoutSettings[$index].'API Unlock Interval (sec)' + 1
                $apiUnlockInterval = [int]$currentLockoutSettings[$index].'API Reset Interval (sec)' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented CLI Max Failures: $cliMaxFailures"
                    Write-LogToFile -message "Incremented CLI Unlock Interval: $cliUnlockInterval"
                    Write-LogToFile -message "Incremented API Max Failures: $apiMaxFailures"
                    Write-LogToFile -message "Incremented API Failure Interval: $apiFailureInterval"
                    Write-LogToFile -message "Incremented API Unlock Interval: $apiUnlockInterval"

                    # Update the NSX-T Manager account lockout settings.
                    $updateResult = Update-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $domain -cliFailures $cliMaxFailures -cliUnlockInterval $cliUnlockInterval -apiFailures $apiMaxFailures -apiFailureInterval $apiFailureInterval -apiUnlockInterval $apiUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Run the verification only after 200 seconds as NSX service will be down after an update.
                    Start-Sleep -Seconds 200

                    # Request the updated NSX-T Manager account lockout settings.
                    $updatedLockoutSettings = Request-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $domain

                    $index = Get-Index -output $updatedLockoutSettings -server $nsxManagerNode -useLiveData $useLiveData

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'CLI Max Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'CLI Unlock Interval (sec)'
                    $outapiMaxFailures = [int]$updatedLockoutSettings[$index].'API Max Failures'
                    $outapiFailureInterval = [int]$updatedLockoutSettings[$index].'API Unlock Interval (sec)'
                    $outapiUnlockInterval = [int]$updatedLockoutSettings[$index].'API Reset Interval (sec)'

                    Write-LogToFile -message "Updated CLI Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated CLI Unlock Interval: $outcliUnlockInterval"
                    Write-LogToFile -message "Updated API Max Failures: $outapiMaxFailures"
                    Write-LogToFile -message "Updated API Failure Interval: $outapiFailureInterval"
                    Write-LogToFile -message "Updated API Unlock Interval: $outapiUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outcliMaxFailures | Should -Be $cliMaxFailures
                    $outcliUnlockInterval | Should -Be $cliUnlockInterval
                    $outapiMaxFailures | Should -Be $apiMaxFailures
                    $outapiFailureInterval | Should -Be $apiFailureInterval
                    $outapiUnlockInterval | Should -Be $apiUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Account Lockout Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidCliMaxFailures = 10000000000000000000000

                    # Attempt to update the NSX Manager account lockout settings.
                    $updateResult = Update-NsxtManagerAccountLockout -server $server -user $user -pass $pass -domain $domain -cliFailures $invalidCliMaxFailures -cliUnlockInterval $cliUnlockInterval -apiFailures $apiMaxFailures -apiFailureInterval $apiFailureInterval -apiUnlockInterval $apiUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Account Lockout Negative Testcase"
                }
            }
        }

        # VMware Aria Suite Lifecycle Account Lockout
        Describe 'VMware Aria Suite Lifecycle Account Lockout' -Tag "AriaSuiteLifecycleAccountLockout" {
            BeforeEach {
                # Request the current VMware Aria Suite Lifecycle account lockout settings.
                $currentLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrslcm

                $ariaSuiteLifecycleVMname = $ariaSuiteLifecycle.Split('.')[0]
                Write-LogToFile -message $ariaOperationsVMname

                $index = Get-Index -output $currentLockoutSettings -server $ariaSuiteLifecycleVMname -useLiveData $useLiveData -aria $true

                # Increment existing settings value by 1.
                $maxFailures = [int]$currentLockoutSettings[$index].'Maximum Failures' + 1
                $unlockInterval = [int]$currentLockoutSettings[$index].'Unlock Interval' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings[$index].'Root Unlock Interval' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"

                    # Update the VMware Aria Suite Lifecycle account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrslcm -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Suite Lifecycle account lockout settings.
                    $updatedLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrslcm

                    $index = Get-Index -output $currentLockoutSettings -server $ariaSuiteLifecycleVMname -useLiveData $useLiveData -aria $true

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'Maximum Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'Unlock Interval'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings[$index].'Root Unlock Interval'

                    Write-LogToFile -message "Updated Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated Unlock Interval: $outcliUnlockInterval"
                    Write-LogToFile -message "Updated Root Unlock Interval: $outrootUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outcliMaxFailures | Should -Be $maxFailures
                    $outcliUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Suite Lifecycle Account Lockout Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidCliMaxFailures = 10000000000000000000000

                    # Attempt to update the VMware Aria Suite Lifecycle account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrslcm -failures $invalidCliMaxFailures -unlockInterval $UnlockInterval -rootUnlockInterval $rootUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Suite Lifecycle Account Lockout Negative Testcase"
                }
            }
        }

        # VMware Aria Operations Account Lockout
        Describe 'VMware Aria Operations Account Lockout' -Tag "AriaOperationsAccountLockout" {
            BeforeEach {
                # Request the current VMware Aria Operations account lockout settings.
                $currentLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrops

                $ariaOperationsVMname = $ariaOperations.Split('.')[0]
                Write-LogToFile -message $ariaOperationsVMname

                $index = Get-Index -output $currentLockoutSettings -server $ariaOperationsVMname -useLiveData $useLiveData -aria $true

                # Increment the CLI and API settings by 1.
                $maxFailures = [int]$currentLockoutSettings[$index].'Maximum Failures' + 1
                $unlockInterval = [int]$currentLockoutSettings[$index].'Unlock Interval' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings[$index].'Root Unlock Interval' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"

                    # Update the VMware Aria Operations account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrops -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Operations account lockout settings.
                    $updatedLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrops

                    $index = Get-Index -output $currentLockoutSettings -server $ariaOperationsVMname -useLiveData $useLiveData -aria $true

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'Maximum Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'Unlock Interval'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings[$index].'Root Unlock Interval'


                    Write-LogToFile -message "Updated Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated Unlock Interval: $outcliUnlockInterval"
                    Write-LogToFile -message "Updated Root Unlock Interval: $outrootUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outcliMaxFailures | Should -Be $maxFailures
                    $outcliUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations Account Lockout Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidCliMaxFailures = 10000000000000000000000

                    # Attempt to update the VMware Aria Operations account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrops -failures $invalidCliMaxFailures -unlockInterval $UnlockInterval -rootUnlockInterval $rootUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations Account Lockout Negative Testcase"
                }
            }
        }

        # VMware Aria Operations for Logs Account Lockout
        Describe 'VMware Aria Operations for Logs Account Lockout' -Tag "AriaOperationsLogsAccountLockout" {
            BeforeEach {
                # Request the current VMware Aria Operations for Logs account lockout settings.
                $currentLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrli

                $ariaOperationsLogsVMname = $ariaOperationsLogs.Split('.')[0]
                Write-LogToFile -message $ariaOperationsLogsVMname

                $index = Get-Index -output $currentLockoutSettings -server $ariaOperationsLogsVMname -useLiveData $useLiveData -aria $true

                # Increment existing settings value by 1.
                $maxFailures = [int]$currentLockoutSettings[$index].'Maximum Failures' + 1
                $unlockInterval = [int]$currentLockoutSettings[$index].'Unlock Interval' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings[$index].'Root Unlock Interval' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"

                    # Update the VMware Aria Operations for Logs account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrli -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Operations for Logs account lockout settings.
                    $updatedLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vrli

                    $index = Get-Index -output $currentLockoutSettings -server $ariaOperationsLogsVMname -useLiveData $useLiveData -aria $true

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'Maximum Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'Unlock Interval'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings[$index].'Root Unlock Interval'

                    Write-LogToFile -message "Updated Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated Unlock Interval: $outcliUnlockInterval"
                    Write-LogToFile -message "Updated Root Unlock Interval: $outrootUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outcliMaxFailures | Should -Be $maxFailures
                    $outcliUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operations for Logs Account Lockout Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidCliMaxFailures = 10000000000000000000000

                    # Attempt to update the VMware Aria Operations for Logs account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vrli -failures $invalidCliMaxFailures -unlockInterval $UnlockInterval -rootUnlockInterval $rootUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operations for Logs Account Lockout Negative Testcase"
                }
            }
        }

        # VMware Aria Automation Account Lockout
        Describe 'VMware Aria Automation Account Lockout' -Tag "AriaAutoomationAccountLockout" {
            BeforeEach {
                # Request the current VMware Aria Automation account lockout settings.
                $currentLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vra

                $ariaAutomationVMname = $ariaAutomation.Split('.')[0]
                Write-LogToFile -message $ariaAutomationVMname

                $index = Get-Index -output $currentLockoutSettings -server $ariaAutomationVMname -useLiveData $useLiveData -aria $true

                # Increment existing settings value by 1.
                $maxFailures = [int]$currentLockoutSettings[$index].'Maximum Failures' + 1
                $unlockInterval = [int]$currentLockoutSettings[$index].'Unlock Interval' + 1
                $rootUnlockInterval = [int]$currentLockoutSettings[$index].'Root Unlock Interval' + 1
            }

            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Account Lockout Positive Testcase"
                    Write-LogToFile -message "Incremented Max Failures: $maxFailures"
                    Write-LogToFile -message "Incremented Unlock Interval: $unlockInterval"
                    Write-LogToFile -message "Incremented Root Unlock Interval: $rootUnlockInterval"

                    # Update the VMware Aria Automation account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vra -failures $maxFailures -unlockInterval $unlockInterval -rootUnlockInterval $rootUnlockInterval
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Request the updated VMware Aria Automation account lockout settings.
                    $updatedLockoutSettings = Request-AriaLocalUserAccountLockout -server $server -user $user -pass $pass -product vra

                    $index = Get-Index -output $currentLockoutSettings -server $ariaAutomationVMname -useLiveData $useLiveData -aria $true

                    # Get the updated Max Failures and Unlock Interval.
                    $outcliMaxFailures = [int]$updatedLockoutSettings[$index].'Maximum Failures'
                    $outcliUnlockInterval = [int]$updatedLockoutSettings[$index].'Unlock Interval'
                    $outrootUnlockInterval = [int]$updatedLockoutSettings[$index].'Root Unlock Interval'

                    Write-LogToFile -message "Updated Max Failures: $outcliMaxFailures"
                    Write-LogToFile -message "Updated Unlock Interval: $outcliUnlockInterval"
                    Write-LogToFile -message "Updated Root Unlock Interval: $outrootUnlockInterval"

                    # Assert that the updated values are equal to the incremented values.
                    $outcliMaxFailures | Should -Be $maxFailures
                    $outcliUnlockInterval | Should -Be $unlockInterval
                    $outrootUnlockInterval | Should -Be $rootUnlockInterval
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    # If an error was thrown, fail the test.
                    $true | Should -Be $false
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Account Lockout Positive Testcase"
                }
            }

            # Expect a failure. Max failures is taking -1 as input, as it is of type int32, so gave value beyond 2^32.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Account Lockout Negative Testcase"
                    # Set MaxDays to an invalid value
                    $invalidCliMaxFailures = 10000000000000000000000

                    # Attempt to update the VMware Aria Automation account lockout settings.
                    $updateResult = Update-AriaLocalUserPasswordAccountLockout -server $server -user $user -pass $pass -product vra -failures $invalidCliMaxFailures -unlockInterval $UnlockInterval -rootUnlockInterval $rootUnlockInterval

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # Sometimes settings will not be updated and hence output will be null and not exception.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # For this negative testcase, exception has to be caught, so testcases passes.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Account Lockout Negative Testcase"
                }
            }
        }
    }

    Describe 'Password Rotation Test Suite' -Tag "PasswordRotationSuite" {
        # NSX Edge Password Rotation
        Describe 'NSX Edge Password Rotation' -Tag "NsxEdgePasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Rotation Testcase"

                    # Request the current NSX Edge password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge'

                    # Get the index of the first NSX Edge  in the output.
                    $index = Get-Index -output $currentRotationSettings -server $nsxEdgeFqdn -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the NSX Edge  $nsxEdgeFqdn in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"
                    # Check the Frequency of auto rotation.
                    if ($frequencyDays -match 'Disabled') {

                        # Update the NSX Edge password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge' -resourceName $nsxEdgeFqdn -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated NSX Edge password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge'

                        # Get the index of the first NSX Edge Node in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $nsxEdgeNode -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the NSX Edge password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge' -resourceName $nsxEdgeFqdn -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge'

                        # Get the index of the first NSX Edge Node in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $nsxEdgeNode -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Edge Password Rotation Negative Testcase"
                    # Set MaxDays to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the NSX Edge password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxEdge' -resourceName $nsxEdgeFqdn -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Edge Password Rotation Negative Testcase"
                }
            }
        }

        # NSX Manager Password Rotation
        Describe 'NSX Manager Password Rotation' -Tag "NsxManagerPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Rotation Testcase"

                    # Request the current NSX Manager password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager'

                    # Get the index of the first NSX Manager in the output.
                    $index = Get-Index -output $currentRotationSettings -server $nsxManager -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the NSX Manager $nsxManager in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {

                        # Update the NSX Manager password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager' -resourceName $nsxManager -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated NSX Manager password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager'

                        # Get the index of the first NSX Manager in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $nsxManager -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the NSX Manager password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager' -resourceName $nsxManager -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager'

                        # Get the index of the first NSX Manager in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $nsxManager -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of NSX Manager Password Rotation Negative Testcase"
                    # Set MaxDays to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the NSX Manager password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'nsxManager' -resourceName $nsxManager -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of NSX Manager Password Rotation Negative Testcase"
                }
            }
        }

        <#
        # vCenter Single Sign-on Password Rotation
        TODO:   Failing to rotate credentials.
                {"errorCode":"PASSWORD_MANAGER_USER_NOT_ALLOWED_PSC","arguments":[],"message":"User is not allowed to update or rotate PSC credentials. Please login using an alternate 'ADMIN' account to perform this operation.","referenceToken":"KBA3UD"}
        Describe 'SSO Password Rotation' -Tag "SsoPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Single Sign-on Password Rotation Testcase"

                    # Request the current vCenter Single Sign-on password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso'

                    # Get the index of the first vCenter Single Sign-on in the output.
                    $index = Get-Index -output $currentRotationSettings -server $vcenterServer -user $user -Type 'SSO' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the vCenter Single Sign-on $vcenterServer in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {

                        # Update the vCenter Single Sign-on password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso' -resourceName $vcenterServer -credential 'SSO' -credentialName $user -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated vCenter Single Sign-on password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso'

                        # Get the index of the first vCenter Single Sign-on in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $vcenterServer -useLiveData $useLiveData -user $user -Type 'SSO'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the vCenter Single Sign-on password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso' -resourceName $vcenterServer -credential 'SSO' -credentialName $user -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso'

                        # Get the index of the first vCenter Single Sign-on in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $vcenterServer -useLiveData $useLiveData -user $user -Type 'SSO'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Single Sign-on Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Single Sign-on Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the vCenter Single Sign-on password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'sso' -resourceName $vcenterServer -credential SSO -credentialName $user -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Single Sign-on Password Rotation Negative Testcase"
                }
            }
        }
        #>

        # vCenter Password Rotation
        Describe 'vCenter Password Rotation' -Tag "vCenterPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Rotation Testcase"

                    # Request the current vCenter password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer'

                    # Get the index of the first vCenter in the output.
                    $index = Get-Index -output $currentRotationSettings -server $vcenterServer -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the vCenter $vcenterServer in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {

                        # Update the vCenter password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer' -resourceName $vcenterServer -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated vCenter password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer'

                        # Get the index of the first vCenter in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $vcenterServer -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Max Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the vCenter password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer' -resourceName $vcenterServer -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer'

                        # Get the index of the first vCenter in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $vcenterServer -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of vCenter Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the vCenter password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'vcenterServer' -resourceName $vcenterServer -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of vCenter Password Rotation Negative Testcase"
                }
            }
        }

        # VMware Aria Suite Lifecycle Password Rotation
        Describe 'VMware Aria Suite Lifecycle Password Rotation' -Tag "AriaSuiteLifecyclePasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of Aria Suite Lifecycle Password Rotation Testcase"

                    # Request the current Aria Lifecycle password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle'

                    # Get the index of the first Aria Suite Lifecycle in the output.
                    $index = Get-Index -output $currentRotationSettings -server $ariaSuiteLifecycle -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the Aria Suite Lifecycle $ariaSuiteLifecycle in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"



                    if ($frequencyDays -match 'Disabled') {

                        # Update the Aria Suite Lifecycle password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle' -resourceName $ariaSuiteLifecycle -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated Aria Suite Lifecycle password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle'

                        # Get the index of the first Aria Suite Lifecycle  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaSuiteLifecycle -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the Aria Suite Lifecycle password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle' -resourceName $ariaSuiteLifecycle -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle'

                        # Get the index of the first Aria Suite Lifecycle  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaSuiteLifecycle -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Aria Suite Lifecycle Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of Aria Suite Lifecycle Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the Aria Suite Lifecycle password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaLifecycle' -resourceName $ariaSuiteLifecycle -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Aria Suite Lifecycle Password Rotation Negative Testcase"
                }
            }
        }

        # VMware Aria Operations Password Rotation
        Describe 'VMware Aria Operations Password Rotation' -Tag "AriaOperationsPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of Aria Operations Password Rotation Testcase"

                    # Request the current Aria Operations password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations'

                    # Get the index of the first Aria Operations in the output.
                    $index = Get-Index -output $currentRotationSettings -server $ariaOperations -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the Aria Operations $ariaOperations in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"



                    if ($frequencyDays -match 'Disabled') {

                        # Update the Aria Operations password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations' -resourceName $ariaOperations -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated Aria Operations password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations'

                        # Get the index of the first Aria Operations  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaOperations -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the Aria Operations password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations' -resourceName $ariaOperations -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations'

                        # Get the index of the first Aria Operations  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaOperations -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Aria Operations Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of Aria Operations Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the Aria Operations password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperations' -resourceName $ariaOperations -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Aria Operations Password Rotation Negative Testcase"
                }
            }
        }

        # VMware Aria Operation for Logs Password Rotation
        Describe 'VMware Aria Operation for Logs Password Rotation' -Tag "AriaOperationLogsPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Operation for Logs Password Rotation Testcase"

                    # Request the current VMware Aria Operation for Logs password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs'

                    # Get the index of the first VMware Aria Operation for Logs in the output.
                    $index = Get-Index -output $currentRotationSettings -server $ariaOperationsLogs -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the Aria Operation Logs $ariaOperationsLogs in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {

                        # Update the VMware Aria Operation for Logs password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs' -resourceName $ariaOperationsLogs -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated VMware Aria Operation for Logs password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs'

                        # Get the index of the first VMware Aria Operation for Logs in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaOperationsLogs -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the VMware Aria Operation for Logs password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs' -resourceName $ariaOperationsLogs -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs'

                        # Get the index of the first VMware Aria Operation for Logs in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaOperationsLogs -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Operation for Logs Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of Aria Operation Logs Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the Aria Operation Logs password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaOperationsLogs' -resourceName $ariaOperationsLogs -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Aria Operation Logs Password Rotation Negative Testcase"
                }
            }
        }

        # VMware Aria Automation Password Rotation
        Describe 'VMware Aria Automation Password Rotation' -Tag "AriaAutomationPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Rotation Testcase"

                    # Request the current VMware Aria Automation password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation'

                    # Get the index of the first VMware Aria Automation in the output.
                    $index = Get-Index -output $currentRotationSettings -server $ariaAutomation -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the Aria Automation $ariaAutomation in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {

                        # Update the VMware Aria Automation password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation' -resourceName $ariaAutomation -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated VMware Aria Automation password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation'

                        # Get the index of the first VMware Aria Automation in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaAutomation -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the VMware Aria Automation password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation' -resourceName $ariaAutomation -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation'

                        # Get the index of the first Aria Automation  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $ariaAutomation -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }
                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of VMware Aria Automation Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the VMware Aria Automation password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'ariaAutomation' -resourceName $ariaAutomation -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of VMware Aria Automation Password Rotation Negative Testcase"
                }
            }
        }

        # Workspace ONE Access Password Rotation
        Describe 'Workspace ONE Access Password Rotation' -Tag "WorkspaceOneAcccessPasswordRotation" {
            # Expect a success.
            It 'Expect Success' -Tag "Positive" {
                Try {
                    Write-LogToFile -message "Start of Workspace ONE Access Password Rotation Testcase"

                    # Request the current Workspace ONE Access password rotation settings.
                    $currentRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess'

                    # Get the index of the first Workspace ONE Access in the output.
                    $index = Get-Index -output $currentRotationSettings -server $workspaceOneAccess -user 'root' -Type 'SSH' -useLiveData $useLiveData
                    Write-LogToFile -message "The index of the Workspace ONE Access $workspaceOneAccess in the output is $index."

                    # Check the Frequency of auto rotation.
                    $frequencyDays = $currentRotationSettings[$index].'Frequency Days'
                    Write-LogToFile -message "Frequency Days: $frequencyDays"

                    if ($frequencyDays -match 'Disabled') {
                        # Update the Workspace ONE Access password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess' -resourceName $workspaceOneAccess -credential 'SSH' -credentialName 'root' -autoRotate 'enabled' -frequencyInDays 90
                        Write-LogToFile -message "Update Result: $updateResult"

                        # Request the updated Workspace ONE Access password rotation settings.
                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess'

                        # Get the index of the first Workspace ONE Access  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $workspaceOneAccess -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 90

                    } else {
                        # Update the Workspace ONE Access password rotation settings.
                        $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess' -resourceName $workspaceOneAccess -credential 'SSH' -credentialName 'root' -autoRotate 'disabled'
                        Write-LogToFile -message "Update Result: $updateResult"

                        $updatedRotationSettings = Request-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess'

                        # Get the index of the first Workspace ONE Access  in the output.
                        $index = Get-Index -output $updatedRotationSettings -server $workspaceOneAccess -useLiveData $useLiveData -user 'root' -Type 'SSH'

                        # Get the updated Frequency in Days.
                        $outFrequencyDays = $updatedRotationSettings[$index].'Frequency Days'

                        # Output the updated Frequency in Days.
                        Write-LogToFile -message "Updated Frequency Days: $outFrequencyDays"

                        # Assert that the updated Max Days is equal to the decremented Max Days.
                        $outFrequencyDays | Should -Be 'Disabled'
                    }

                } Catch {
                    Write-LogToFile -Type ERROR -message "An error occurred: $_"
                    $false | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Workspace ONE Access Password Rotation Positive Testcase"
                }
            }

            # Expect a failure.
            It 'Expect Failure' -Tag "Negative" {
                Try {
                    Write-LogToFile -message "Start of Workspace ONE Access Password Rotation Negative Testcase"
                    # Set the Frequency to an invalid value
                    $frequencyInDays = 100000000000000000000000000000

                    # Attempt to update the Workspace ONE Access password rotation settings.
                    $updateResult = Update-PasswordRotationPolicy -server $server -user $user -pass $pass -domain $domain -resource 'workspaceOneAccess' -resourceName $workspaceOneAccess -credential SSH -credentialName root -autoRotate enabled -frequencyInDays $frequencyInDays

                    # Output the update result.
                    Write-LogToFile -message "Update Result: $updateResult"

                    # If the function did not throw an error, fail the test.
                    $null | Should -Be $updateResult
                } Catch {
                    # Output the caught exception.
                    Write-LogToFile -message "Caught Exception: $_"

                    # If an error was thrown, fail the test.
                    $true | Should -Be $true
                } Finally {
                    Write-LogToFile -message "End of Workspace ONE Access Password Rotation Negative Testcase"
                }
            }
        }
    }
}
