function Get-PendingReboot {


Param(
    
    [Parameter(Mandatory = $true)]
    $ComputerName,

    [Parameter()]
    $Credential
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

    If ($CBSRebootPend,$WUAURebootReq,$CompPendRen -eq $True) {
        #Return $CBSRebootPend,$WUAURebootReq,$CompPendRen
        Return "True"
        }
    ElseIf ($CBSRebootPend,$WUAURebootReq,$CompPendRen -eq $False) {
        #Return $CBSRebootPend,$WUAURebootReq,$CompPendRen
        Return "False"
        }
    Else {
        #Return $CBSRebootPend,$WUAURebootReq,$CompPendRen
        Return "Unknown"
        }
}



try {
(New-Object System.Net.Sockets.TCPClient -ArgumentList "$ComputerName",5985 -ErrorAction Stop | Out-Null)             
if ($Credential -eq $null) {
Invoke-Command -ComputerName $ComputerName -ScriptBlock $RebootCheck -ArgumentList $ComputerName 
}
else {
     Invoke-Command -ComputerName $ComputerName -ScriptBlock $RebootCheck -ArgumentList $ComputerName -Credential $Credential   
    }
}
catch {
Return "Error: $_"
}
}