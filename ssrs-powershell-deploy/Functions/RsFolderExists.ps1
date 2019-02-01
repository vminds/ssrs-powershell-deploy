
function rsFolderExists ($Proxy, $RsFolder){
    try {
        $parent = (Split-Path -Path $RsFolder -Parent).Replace('\','/')
	   $leaf = Split-Path -Path $RsFolder -Leaf
        $targetFolder = Get-RsFolderContent -Proxy $Proxy -RsFolder $parent | Where-Object { $_.Name -eq $leaf }
        if ($null -eq $targetFolder) { return $false } else { return $true }    
    }
    catch {
        return $false
    }
}
