
function New-SSRSDataSource (
	$Proxy,
	[string]$RdsPath,
	[string]$Folder,
     [bool]$Overwrite
)
{
	$script:ErrorActionPreference = 'Stop'

	Write-InformationLog -Message "Processing DataSource '$RdsPath'..."
    	
	$Folder = Normalize-SSRSFolder -Folder $Folder

	[xml]$Rds = Get-Content -Path $RdsPath
	$ConnProps = $Rds.RptDataSource.ConnectionProperties

	$Definition = New-Object -TypeName SSRS.ReportingService2010.DataSourceDefinition
	$Definition.ConnectString = if ($ConnectionString.length -gt 1) { $ConnectionString } else { $ConnProps.ConnectString }
	$Definition.Extension = $ConnProps.Extension

	$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
	$HiddenProp.Name = 'Hidden'
	$HiddenProp.Value = 'false'
	$Properties = @($HiddenProp)
     
     [string]$rdsName = Split-Path -Leaf $RdsPath
	if($rdsName.StartsWith('_'))
	{
		$HiddenProp.Value = 'true'
	}

	#Does the IntegratedSecurity property exist
	$integratedproperty = $ConnProps | Get-Member -MemberType Property | where {$_.name -like 'IntegratedSecurity'}

	if($integratedproperty -ne $null)
	{
		if ([Convert]::ToBoolean($ConnProps.IntegratedSecurity)) {
			Write-InformationLog -Message "Using integrated security"
			$Definition.CredentialRetrieval = 'Integrated'
		}
	}
	else{
		  Write-InformationLog -Message "Using stored username/pw ($DataSourceUser)"
		  $Definition.CredentialRetrieval = 'Store'
		  $Definition.UserName = $DataSourceUser
		  $Definition.Password = $DataSourcePwd
    }

	$DataSource = New-Object -TypeName PSObject -Property @{
		Name = $Rds.RptDataSource.Name
		Path = $Folder + '/' + $Rds.RptDataSource.Name
	}

	$exists = $Proxy.GetItemType($DataSource.Path) -ne 'Unknown'
	$write = $false
	if ($exists) {
		if ($Overwrite) {
			Write-InformationLog -Message " - overwriting"
			$write = $true
		} else {
			Write-InformationLog -Message " - skipped, already exists (overwrite not requested)"
		}
	} else {
		Write-InformationLog -Message " - creating new"
		$write = $true
	}

	if ($write) {
		# assign result to avoid polluting return value. http://stackoverflow.com/a/23225503/10245
		# Oh what an ugly language powerhell is. :-/
		$foo = $Proxy.CreateDataSource($DataSource.Name, $Folder, $Overwrite, $Definition, $Properties)
	}

	return $DataSource
}
