### WIP Excel formatting ###

function Export-ServerReportXLSX { 

Import-Module ImportExcel
$report = "severstatus.csv"
Get-Content $report | Export-Excel -Show -Now -ConditionalText (New-ConditionalText -ConditionalType ContainsText "RED" -ConditionalTextColor red)
}