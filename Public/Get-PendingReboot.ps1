function Get-PendingReboot {


Param(
    
    [Parameter(Mandatory = $true)]
    $ComputerName
    )



[ScriptBlock]$RebootCheck = {

param($computer) $Computername

$CBSRebootPend,$WUAURebootReq = $null
$CompPendRen = $false


$HKLM = [UInt32] "0x80000002" 
$WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv" 
$RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\") 
$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"

$RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\") 
$WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"



$ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")       
$CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName") 

If ($ActCompNm -ne $CompNm) { 
$CompPendRen = $true 
} 

#Write-Host "End of scriptblock..$CBSRebootPend,$WUAURebootReq,$CompPendRen"
}



try {
(New-Object System.Net.Sockets.TCPClient -ArgumentList "$ComputerName",5985 -ErrorAction Stop | Out-Null)             
Invoke-Command -ComputerName $ComputerName -ScriptBlock $RebootCheck -ArgumentList $ComputerName 
}
catch {
Return "Error: $_"
}

If ($CBSRebootPend,$WUAURebootReq,$CompPendRen -eq $True) {
    $NeedsReboot = "True"
    Return "True"
    }
ElseIf ($CBSRebootPend,$WUAURebootReq,$CompPendRen -eq $False) {
    $NeedsReboot = "False"
    Return "False"
    }
Else {
    Return "Unknown"  
}
}