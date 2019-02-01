function New-SSRSReport (
	$Proxy,
	[string]$RdlPath,
    $RdlName,
    $OverwriteBehavior,
    $ReportExists
)
{
	$script:ErrorActionPreference = 'Stop'

	[xml]$Definition = Get-Content -Path $RdlPath
	$NsMgr = New-XmlNamespaceManager $Definition d

	$RawDefinition = Get-Content -Encoding Byte -Path $RdlPath

	$Name = $RdlName -replace '\.rdl$',''

	$DescProp = New-Object -TypeName SSRS.ReportingService2010.Property
	$DescProp.Name = 'Description'
	$DescProp.Value = ''
	$HiddenProp = New-Object -TypeName SSRS.ReportingService2010.Property
	$HiddenProp.Name = 'Hidden'
	$HiddenProp.Value = 'false'
	$Properties = @($DescProp, $HiddenProp)

	$Xpath = 'd:Report/d:Description'
	$DescriptionNode = $Definition.SelectSingleNode($Xpath, $NsMgr)

	if($DescriptionNode)
	{
		$DescProp.Value = $DescriptionNode.Value
	}

	if($Name.StartsWith('_'))
	{
		$HiddenProp.Value = 'true'
	}
     
    if ($ReportExists -eq $true) {
		  Write-InformationLog -Message " - already exists on reportserver"
	   } else {
		 Write-InformationLog -Message " - does not yet exist on reportserver"
    }

    switch($OverwriteBehavior)
    {
        0 { $Overwrite = $false; }
        1 { $Overwrite = $true; }
        2 { $Overwrite = Compare-SSRSReport -Proxy $Proxy; }
    }
       
    
    Write-InformationLog -Message "Overwrite flag set to $Overwrite"
    

    if ($ReportExists -eq $false -or $Overwrite -eq $true) {

    		   $warnings = $null
		   $Results = $Proxy.CreateCatalogItem("Report", $Name, $Folder, $Overwrite, $RawDefinition, $Properties, [ref]$warnings)

		   $Xpath = 'd:Report/d:DataSources/d:DataSource/d:DataSourceReference/..'
		   $DataSources = $Definition.SelectNodes($Xpath, $NsMgr) |
			   ForEach-Object {
				   $DataSourcePath = $DataSourcePaths[$_.DataSourceReference]
				   if (-not $DataSourcePath) {
					   Write-ErrorLog -Message "Invalid data source reference '$($_.DataSourceReference)' in $RdlPath"
					   throw "Invalid data source reference '$($_.DataSourceReference)' in $RdlPath"
				   }
				   $Reference = New-Object -TypeName SSRS.ReportingService2010.DataSourceReference
				   $Reference.Reference = $DataSourcePath
				   $DataSource = New-Object -TypeName SSRS.ReportingService2010.DataSource
				   $DataSource.Item = $Reference
				   $DataSource.Name = $_.Name
				   $DataSource
			   }
		   if ($DataSources) {
			   $Proxy.SetItemDataSources($Folder + '/' + $Name, $DataSources)
		   }

		   $Xpath = 'd:Report/d:DataSets/d:DataSet/d:SharedDataSet/d:SharedDataSetReference/../..'
		   $References = $Definition.SelectNodes($Xpath, $NsMgr) |
			   ForEach-Object {
				   $DataSetPath = $DataSetPaths[$_.SharedDataSet.SharedDataSetReference]
				   if ($DataSetPath) {
					   $Reference = New-Object -TypeName SSRS.ReportingService2010.ItemReference
					   $Reference.Reference = $DataSetPath
					   $Reference.Name = $_.Name
					   $Reference
				   }
			   }
		   if ($References) {
			   $Proxy.SetItemReferences($Folder + '/' + $Name, $References)
		   }
		  
		  $lastModifiedDate = (Get-Item $RdlPath).LastWriteTime
		  Write-InformationLog -Message "$Name (re)uploaded to catalog (.rdl file last modified date: $lastModifiedDate)"
	   
	   } else {
	  
		  Write-InformationLog -Message "No (re)upload required for $Name"

	  }



}
