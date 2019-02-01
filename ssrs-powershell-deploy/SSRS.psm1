
#Dot source all ps1 files
#These are the small function used by others
. $PSScriptRoot\Functions\Get-SSRSCredential.ps1
. $PSScriptRoot\Functions\Normalize-SSRSFolder.ps1
. $PSScriptRoot\Functions\New-XmlNamespaceManager.ps1

. $PSScriptRoot\Functions\New-SSRSFolder.ps1
. $PSScriptRoot\Functions\New-SSRSDataSource.ps1
. $PSScriptRoot\Functions\New-SSRSDataSet.ps1
. $PSScriptRoot\Functions\New-SSRSReport.ps1


#Larger methods that might use some of the ones above
. $PSScriptRoot\Functions\New-SSRSWebServiceProxy.ps1
. $PSScriptRoot\Functions\Get-SSRSProjectConfiguration.ps1
. $PSScriptRoot\Functions\Publish-SSRSProject.ps1
. $PSScriptRoot\Functions\Publish-SSRSSolution.ps1

#Common helper methods
. $PSScriptRoot\Functions\RsFolderExists.ps1
. $PSScriptRoot\Functions\Compare-SSRSReport.ps1


Export-ModuleMember Get-SSRSCredential, Normalize-SSRSFolder, New-XmlNamespaceManager, New-SSRSFolder, New-SSRSDataSource `
    , New-SSRSDataSet, New-SSRSReport, New-SSRSWebServiceProxy, Get-SSRSProjectConfiguration, Publish-SSRSProject, Publish-SSRSSolution `
    , rsFolderExists, Compare-SSRSReport
