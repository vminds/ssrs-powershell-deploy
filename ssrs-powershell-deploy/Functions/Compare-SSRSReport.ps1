function Compare-SSRSReport (
	$Proxy)
{

if ($ReportExists -eq $false) { return $true }

Write-InformationLog -Message "Hash compare requested"

Out-RsCatalogItem -Proxy $Proxy -RsItem "$Folder/$Name" -Destination $env:TEMP

$filefromserver = "$env:TEMP\$Name.rdl"
$filefromproject = $RdlPath

$hashfromserver = Get-FileHash -Path $filefromserver -Algorithm MD5
$hashfromproject = Get-FileHash -Path $filefromproject -Algorithm MD5

Write-InformationLog -Message "Hash from server report: $($hashfromserver.Hash)  // Hash from project RDL file: $($hashfromproject.Hash)"

if(($hashfromserver.Hash) -ne ($hashfromproject.Hash)) {
    Write-InformationLog -Message " - hashing differs"
    return $true # if not the same returning true will instruct an overwrite
}
else {
    Write-InformationLog -Message " - hashing matches"
    return $false
}


}

