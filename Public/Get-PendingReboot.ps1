function Get-PendingReboot {


Param(
    
    [Parameter(Mandatory = $true)]
    $ComputerName
    )

$CBSRebootPend,$WUAURebootReq,$CompPendRen = $null

[ScriptBlock]$RebootCheck = {

param($computer) $Computername

$CompPendRen = $false
$CBSRebootPend = $null

$HKLM = [UInt32] "0x80000002" 
$WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv" 
$RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\") 
$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"

$RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\") 
$WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"



$ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")       
$CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName") 
}

If ($ActCompNm -ne $CompNm) { 
$CompPendRen = $true 
} 

If ($CBSRebootPend -or $WUAURebootReq -or $CompPendRen -eq $true) {
    Return "True"
    }
ElseIf ($CBSRebootPend -or $WUAURebootReq -or $CompPendRen -eq $false) {
    Return "False"
    }
Else {
}

try {

(New-Object System.Net.Sockets.TCPClient -ArgumentList "$ComputerName",5985 -ErrorAction Stop)             
Invoke-Command -ComputerName $ComputerName -ScriptBlock $RebootCheck -ArgumentList $ComputerName 
}
catch {
$error = $_
}
}