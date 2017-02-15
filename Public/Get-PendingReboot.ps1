function Get-PendingReboot {

Invoke-Command -ComputerName $computer -ScriptBlock {

$RegSubKeysCBS = $WMI_Reg.EnumKey
($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\") 
$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"      
$CBSRebootPend

}

}