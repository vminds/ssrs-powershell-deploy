[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)] [string]$Solution,
    [Parameter(Mandatory=$false)] [string]$Configuration,
    [Parameter(Mandatory=$true)] [string]$ReportServerURI,
    [Parameter(Mandatory=$true)] [string]$LogPath,
    [Parameter(Mandatory=$true)] [string]$RsRoot,
    [Parameter(Mandatory=$false)] [string]$DataSourceUser,
    [Parameter(Mandatory=$false)] [string]$DataSourcePwd,
    [Parameter(Mandatory=$false)] [string]$ConnectionString,
    [Parameter(Mandatory=$false)] [string]$OverwriteReports = 2,
    [switch]$RemoveAllItems = $false
)


Import-Module -Force ScriptLogger
Import-Module -Force ReportingServicesTools
Import-Module -Force "$PSScriptRoot\SSRS.psm1"

[string]$logFile = 'SSRS_Solution_Deploy.log'
$LogPath = $LogPath.TrimEnd('\')

Write-Host "LogPath: $LogPath"
Write-Host "Current root: " $PSScriptRoot

# ensure log path folders exist
New-Item -Type directory -Path $LogPath -Force | Out-Null

# enable logging
Start-ScriptLogger -Path $LogPath\$logFile -Format '{0:yyyy-MM-dd}   {0:HH:mm:ss:ms}   {1}   {2}   {3,-11}   {4}' -NoEventLog | Out-Null
Write-InformationLog -Message "*** $PSCommandPath started"

# log all cmdline params
Write-InformationLog -Message "Passed parameters: "
foreach ($p in $PSBoundParameters.GetEnumerator()) {
    if ($p.Key -ieq 'datasourcepwd' ) {
	   Write-InformationLog -Message "   - $($p.Key): *****"
    } else {
	   Write-InformationLog -Message "   - $($p.Key): $($p.Value)"
    }
}

$proxy = New-RsWebServiceProxy -ReportServerUri $ReportServerURI

if (rsFolderExists -Proxy $proxy -rsFolder $RsRoot) {
    if ($RemoveAllItems -eq $true) {
	   Write-InformationLog -Message "Removing $RsRoot folder and its contents"
	   Remove-RsCatalogItem -Proxy $proxy -RsItem $RsRoot -Confirm:$false
    } else {
        $items = Get-RsFolderContent -Proxy $proxy -RsFolder $RsRoot -Recurse
        Write-InformationLog -Message "Listing current hierarchy for $RsRoot"
        foreach($item in $items) 
        {
	       Write-InformationLog -Message "Type: $($item.TypeName) -- CreationDate: $($item.CreationDate) -- ModifiedDate: $($item.ModifiedDate) -- Path: $($item.Path)"
	   }
    }
} else {
    Write-InformationLog -Message "$RsRoot does not exist"
}

if ($Solution.Length -gt 1) {

    Write-InformationLog -Message 'Starting main function Publish-SSRSSolution'
    Publish-SSRSSolution -Verbose -Solution $Solution -Configuration $Configuration -OverwriteReports $OverwriteReports -RemoveNonExistingItems $true `
				    -DataSourceUser $DataSourceUser -DataSourcePwd $DataSourcePwd -OverwriteDataSources $true `
				    -ConnectionString $ConnectionString -ServerUrl $ReportServerURI
    Write-InformationLog -Message 'Main function Publish-SSRSSolution ended'

}


# stop logging
Write-InformationLog -Message "*** $PSCommandPath ended"
Stop-ScriptLogger







