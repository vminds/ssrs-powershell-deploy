function New-SSRSFolder (
	$Proxy,
	[string]
	$Name,
	[switch]
	$Recursing
)
{
  $script:ErrorActionPreference = 'Stop'

	if (!$recursing) {
		Write-InformationLog -Message "Creating SSRS folder '$Name'"
	}

	$Name = Normalize-SSRSFolder -Folder $Name

	if ($Proxy.GetItemType($Name) -ne 'Folder') {
		$Parts = $Name -split '/'
		$Leaf = $Parts[-1]
		$Parent = $Parts[0..($Parts.Length-2)] -join '/'

		if ($Parent) {
			New-SSRSFolder -Proxy $Proxy -Name $Parent -Recursing
		} else {
			$Parent = '/'
		}

		# create folder, suppressing console output from proxy
		$Proxy.CreateFolder($Leaf, $Parent, $null) > $null
	} else {
		if (!$recursing) {
			Write-InformationLog -Message " - skipped, already exists"
		}
	}
}
