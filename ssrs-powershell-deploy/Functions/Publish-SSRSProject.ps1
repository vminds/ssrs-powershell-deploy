function Publish-SSRSProject{
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$true)]
		[ValidatePattern('\.rptproj$')]
		[ValidateScript({ Test-Path -PathType Leaf -Path $_ })]
		[string]
		$Path,

		[parameter(Mandatory=$false)]
		[string]
		$Configuration,

		[parameter(Mandatory=$false)]
		[string]
		$ServerUrl,

		[parameter(Mandatory=$false)]
		[string]
		$Folder,

		[parameter(Mandatory=$false)]
		[string]
		$DataSourceFolder,

		[parameter(Mandatory=$false)]
		[string]
		$DataSetFolder,

		[parameter(Mandatory=$false)]
		[string]
		$OutputPath,

		[parameter(Mandatory=$false)]
		[bool]
		$OverwriteDataSources,

		[parameter(Mandatory=$false)]
		[bool]
		$OverwriteDatasets,
		
    		[parameter(Mandatory=$false)]
		[int]
		$OverwriteReports,

	     [parameter(Mandatory=$false)]
		[bool]
		$RemoveNonExistingItems,
		 
    	     [parameter(Mandatory=$false)]
		[string]
		$DataSourceUser,

		[parameter(Mandatory=$false)]
		[string]
		$DataSourcePwd,

		[parameter(Mandatory=$false)]
		[string]
		$ConnectionString,

		[System.Management.Automation.PSCredential]
		$Credential
		 
	   )


	$script:ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest

	$Path = $Path | Convert-Path
	$ProjectRoot = $Path | Split-Path
	[xml]$Project = Get-Content -Path $Path
     $nsp = New-XmlNamespaceManager $Project p


	#Argument validation
	if(![string]::IsNullOrEmpty($Configuration))
	{
		$Config = Get-SSRSProjectConfiguration -Path $Path -Configuration $Configuration

		if([string]::IsNullOrEmpty($ServerUrl))
		{
			Write-InformationLog -Message "Using Project Server URL: $($Config.ServerUrl)"
			$ServerUrl = $Config.ServerUrl
		}

		if([string]::IsNullOrEmpty($Folder))
		{
			Write-InformationLog -Message "Using Project Folder : $($Config.Folder)"
			$Folder = $Config.Folder
		}

		if([string]::IsNullOrEmpty($DataSourceFolder))
		{
			Write-InformationLog -Message "Using Project DataSourceFolder: $($Config.DataSourceFolder)"
			$DataSourceFolder = $Config.DataSourceFolder
		}

		if([string]::IsNullOrEmpty($DataSetFolder))
		{
			Write-InformationLog -Message "Using Project DataSetFolder: $($Config.DataSetFolder)"
			$DataSetFolder = $Config.DataSetFolder
		}

		if([string]::IsNullOrEmpty($OutputPath))
		{
			Write-InformationLog -Message "Using Project OutputPath: $($Config.OutputPath)"
			$OutputPath = $Config.OutputPath
		}

		if(!$PSBoundParameters.ContainsKey("OverwriteDataSources"))
		{
			Write-InformationLog -Message "Using Project OverwriteDataSources: $($Config.OverwriteDataSources)"
			$OverwriteDataSources = $Config.OverwriteDataSources
		}

		if(!$PSBoundParameters.ContainsKey("OverwriteDatasets"))
		{
			Write-InformationLog -Message "Using Project OverwriteDatasets: $($Config.OverwriteDatasets)"
			$OverwriteDatasets = $Config.OverwriteDatasets
		}

		if(!$PSBoundParameters.ContainsKey("OverwriteReports"))
		{
			Write-InformationLog -Message "Using Project OverwriteReports: $($Config.OverwriteReports)"
			$OverwriteReports = $Config.OverwriteReports
		}

		if(!$PSBoundParameters.ContainsKey("RemoveNonExistingItems"))
		{
			Write-InformationLog -Message "Using Project RemoveNonExistingItems: $($Config.RemoveNonExistingItems)"
			$RemoveNonExistingItems = $Config.RemoveNonExistingItems
		}
	}
     
    $projReports = $Project.SelectNodes("//p:Report", $nsp)
    $projReports | ForEach-Object {
	   $CompiledRdlPath = $ProjectRoot | Join-Path -ChildPath $OutputPath | Join-Path -ChildPath $_.Include
	   $RdlPath = $ProjectRoot | Join-Path -ChildPath $_.Include
		
	   if ((test-path $CompiledRdlPath) -eq $false)
	   {
		  Write-ErrorLog -Message "Report $CompiledRdlPath is listed in the project but wasn't found in the bin\ folder. Rebuild your project before publishing."
		  break;
	   }
	   $RdlLastModified = (get-item $RdlPath).LastWriteTime
	   $CompiledRdlLastModified = (get-item $CompiledRdlPath).LastWriteTime
	   if ($RdlLastModified -gt $CompiledRdlLastModified)
	   {
		  Write-ErrorLog -Message "Reports in bin\ are older than source file $RdlPath. Rebuild your project before publishing."
		  break;
	   }
    }
    
	$Folder = Normalize-SSRSFolder -Folder $Folder
	$DataSourceFolder = Normalize-SSRSFolder -Folder $DataSourceFolder
    
	$Proxy = New-SSRSWebServiceProxy -Uri $ServerUrl -Credential $Credential

	# get existing reports and datasources from reportserver
     if (rsFolderExists -Proxy $Proxy -RsFolder $Folder) {
		  $RsReportContent = Get-RsFolderContent -Proxy $proxy -RsFolder $Folder -Recurse | Where-Object{$_.TypeName -ieq 'report'}
		  $RsDataSourceContent = Get-RsFolderContent -Proxy $proxy -RsFolder $Folder -Recurse | Where-Object{$_.TypeName -ieq 'datasource'}
	   } else {
		 $RsReportContent = $null
		 $RsDataSourceContent = $null
	  }

	$FullServerPath = $Proxy.Url
	Write-InformationLog -Message "Connecting to: $FullServerPath"

	New-SSRSFolder -Proxy $Proxy -Name $Folder
	New-SSRSFolder -Proxy $Proxy -Name $DataSourceFolder
	New-SSRSFolder -Proxy $Proxy -Name $DataSetFolder

    $DataSourcePaths = @{}
    $projDataSources = $Project.SelectNodes("//p:DataSource", $nsp)
    $projDataSources |
	   ForEach-Object {
		  $RdsPath = $ProjectRoot | Join-Path -ChildPath $_.Include
		  $DataSource = New-SSRSDataSource -Proxy $Proxy -RdsPath $RdsPath -Folder $DataSourceFolder -Overwrite $OverwriteDataSources
		  $DataSourcePaths.Add($DataSource.Name, $DataSource.Path)
	   } 

	$DataSetPaths = @{}
	$Project.SelectNodes("//p:ProjectItem", $nsp) |
		ForEach-Object {
			$RsdPath = $ProjectRoot | Join-Path -ChildPath $_.FullPath
			$DataSet = New-SSRSDataSet -Proxy $Proxy -RsdPath $RsdPath -Folder $DataSetFolder -DataSourcePaths $DataSourcePaths -Overwrite $OverwriteDatasets
			if(-not $DataSetPaths.Contains($DataSet.Name))
			{
				$DataSetPaths.Add($DataSet.Name, $DataSet.Path)
			}
		}
    
    # images for reports
	$projReports |
	   ForEach-Object {

            $extension = $_.Include.Substring($_.Include.length - 3 , 3)

			if(ImageExtensionValid -ext $extension){

				$PathImage = $ProjectRoot | Join-Path -ChildPath $_.Include
				$RawDefinition = Get-Content -Encoding Byte -Path $PathImage

				$DescProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$DescProp.Name = 'Description'
				$DescProp.Value = ''
				$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$HiddenProp.Name = 'Hidden'
				$HiddenProp.Value = 'false'
				$MimeProp = New-Object -TypeName SSRS.ReportingService2010.Property
				$MimeProp.Name = 'MimeType'
				$MimeProp.Value = 'image/' + $extension

				$Properties = @($DescProp, $HiddenProp, $MimeProp)

				$Name = $_.Include
				Write-InformationLog -Message "Creating resource $Name"
				$warnings = $null
				$Results = $Proxy.CreateCatalogItem("Resource", $_.Include, $Folder, $true, $RawDefinition, $Properties, [ref]$warnings)
			}
		}

    # reports themselves
    if ($projReports.Count -eq 0) { Write-InformationLog -Message "No reports in this project"}
	$projReports |
	   ForEach-Object {
		  if($_.Include.EndsWith('.rdl')){
			 $existsonreportserver = $false
			 $CompiledRdlPath = $ProjectRoot | Join-Path -ChildPath $OutputPath | Join-Path -ChildPath $_.Include
			 Write-InformationLog -Message "Processing report '$($_.Include)'"
			 if ($RsReportContent -and $RsReportContent.Name -contains $_.Include.Replace('.rdl','')) { $existsonreportserver = $true }
			 New-SSRSReport -Proxy $Proxy -RdlPath $CompiledRdlPath -RdlName $_.Include -OverwriteBehavior $OverwriteReports -ReportExists $existsonreportserver
        }
	}


    if ($RemoveNonExistingItems -eq $true) {

	   # remove reports which are not in this project but exists in this project's reportserver folder
	   if ($RsReportContent) {
				if ($projReports.Item(0)) {
				    $ReportsToRemove = $RsReportContent | Where {$projReports.Include.Replace('.rdl','') -NotContains $_.Name}
				    $ReportsToRemove | ForEach-Object {
						  Write-InformationLog -Message "Removing non-existing project report $($_.Path) from reportserver"
						  Remove-RsCatalogItem -Proxy $Proxy -RsItem $_.Path -Confirm:$false
				    }
			 } else {
				    Write-InformationLog -Message "Project not longer contains any reports"
				    $RsReportContent | ForEach-Object {
						  Write-InformationLog -Message "Removing non-existing project report $($_.Path) from reportserver"
						  Remove-RsCatalogItem -Proxy $Proxy -RsItem $_.Path -Confirm:$false
				    }
			}
	   }

	   # remove data sources which are not in this project but exists in this project's reportserver folder
	   if ($RsDataSourceContent) {
			 if ($projDataSources.Item(0)) {
				$DataSourcesToRemove = $RsDataSourceContent | Where {$projDataSources.Include.Replace('.rds','') -NotContains $_.Name}
				$DataSourcesToRemove | ForEach-Object {
					   Write-InformationLog -Message "Removing non-existing project datasource $($_.Path) from reportserver"
					   Remove-RsCatalogItem -Proxy $Proxy -RsItem $_.Path -Confirm:$false
				 }
			 } else {
				Write-InformationLog -Message "Project not longer contains any data sources"
				$RsDataSourceContent | ForEach-Object {
					   Write-InformationLog -Message "Removing non-existing project datasource $($_.Path) from reportserver"
					   Remove-RsCatalogItem -Proxy $Proxy -RsItem $_.Path -Confirm:$false
				 }
			 }
	   }
    }
}


    

function ImageExtensionValid($ext){
    $valid = 0;

    Switch($ext)
    {
        'png' { $valid = 1; }
        'bmp' { $valid = 1; }
        'gif' { $valid = 1; }
        'jpg' { $valid = 1; }
    }

    return $valid;
}
