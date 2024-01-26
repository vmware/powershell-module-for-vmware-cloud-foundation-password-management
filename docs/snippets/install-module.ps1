Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name VMware.PowerCLI -MinimumVersion 13.1.0
Install-Module -Name VMware.vSphere.SsoAdmin -MinimumVersion 1.3.9
Install-Module -Name PowerVCF -MinimumVersion 2.4.1
Install-Module -Name PowerValidatedSolutions -MinimumVersion 2.8.0
Install-Module -Name VMware.CloudFoundation.PasswordManagement
