function Publish-SSRSSolution{
	#requires -version 2.0
	[CmdletBinding()]
	# Path is the full path to the solution file, including the file name.
	# i.e. D:\dev\Reports\Reports.sln
	param (
		[parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]
		$Solution,

		[parameter(
			ParameterSetName='Configuration',
			Mandatory=$true)]
		[string]
		$Configuration,

		[System.Management.Automation.PSCredential]
		$credentials,

		[parameter(Mandatory=$false)]
		[ValidatePattern('^https?://')]
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
		$ConnectionString
	)

	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest

	$Solution = ($Solution | Resolve-Path).ProviderPath

	$SolutionRoot = $Solution | Split-Path

	# Guid is for the Reports project type.
	$SolutionProjectPattern = @"
(?x)
^ Project \( " \{ F14B399A-7131-4C87-9E4B-1186C45EF12D \} " \)
\s* = \s*
" (?<name> [^"]* ) " , \s+
" (?<path> [^"]* ) " , \s+
"@

	Get-Content -Path $Solution |
		ForEach-Object {
			if ($_ -match $SolutionProjectPattern) {
				$ProjectPath = $SolutionRoot | Join-Path -ChildPath $Matches['path']
				$ProjectPath = ($ProjectPath | Resolve-Path).ProviderPath
				#"$ProjectPath" = full path to the project file

				& Publish-SSRSProject -path $ProjectPath -configuration $configuration -verbose -credential $credentials `
				    -ServerUrl $ServerUrl -Folder $Folder -DataSourceFolder $DataSourceFolder -DataSetFolder $DataSetFolder `
				    -OutputPath $OutputPath -OverwriteDataSources $OverwriteDataSources -OverwriteDatasets $OverwriteDatasets `
				    -OverwriteReports $OverwriteReports -RemoveNonExistingItems $RemoveNonExistingItems `
				    -DataSourceUser $DataSourceUser -DataSourcePwd $DataSourcePwd -ConnectionString $ConnectionString
			}
		
	   }

}
