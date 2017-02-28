function Get-Extension {
    Write-Host $ExportPath
    [string]$Extension = ($ExportPath[-4..-1])
    $Extension = $Extension.Replace(" ","")
    Write-Host "Extension Is $Extension"
    if  ($Extension -eq "xlsx" -or $Extension -eq ".xls" -or $Extension -eq ".csv" -or $Extension -eq ".txt") {
        $ExtensionCheck = "True"
        Write-Host $Extension
        Write-Host $ExtensionCheck
    }
    else { 
        Write-Host $Extension 
        $ExtensionCheck = "False"
        Write-Host $ExtensionCheck
}
}