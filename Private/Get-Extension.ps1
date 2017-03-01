function Get-Extension {

Param(
    
    [Parameter()]
    [string]
    $ExportPath

    )

    [string]$Extension = ($ExportPath[-4..-1])
    $Extension = $Extension.Replace(" ","")
    
    if ($Extension -eq "xlsx" -or $Extension -eq ".xls" -or $Extension -eq ".csv" -or $Extension -eq ".txt") {
        Return "True"
        }
    else { 
        Return "False"
        }
}