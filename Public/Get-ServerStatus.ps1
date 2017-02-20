<#
.SYNOPSIS
    Get-ServerStatus.ps1 - Test an RPC and RDP connection against one or more computers
.DESCRIPTION
    Get-ServerStatus.ps1 - Test an RPC connection (WMI request) against one or more computer(s)
    with test-connection before to see if the computer is reachable or not first
.PARAMETER ComputerName
    Defines the computer name or IP address to test the RPC connection. Could be an array of servernames
    Mandatory parameter.
.NOTES
    File Name    : Get-ServerStatus.ps1
    Author       : Marcus Daniels - danielm1@mskcc.org
    Adapted From : RPC-Ping.ps1 by Fabrice ZERROUKI - fabricezerrouki@hotmail.com
.EXAMPLE
    PS D:\> .\Get-ServerStatus.ps1 -ComputerName SERVER1
    Test connections against SERVER1
.EXAMPLE
    PS D:\> .\Get-ServerStatus.ps1 -ComputerName SERVER1,192.168.0.23
    Test connections against SERVER1 and 192.168.0.23
#>

function Get-ServerStatus {

[CmdletBinding(DefaultParameterSetName='ByComputerList')]

Param(

    [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerList')]
    [array]$ComputerList,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerName')]
    [array]
    $ComputerName,

    <#
    [Parameter(Mandatory=$true, HelpMessage="You must provide a hostname or an IP address to test")]
    #[array[]]$ComputerName,
    [string[]]$ComputerName,
    #>

    [Parameter()]
    [string[]]$User,

    [Parameter()]
    $Pass,

    [Parameter()]
    [string[]]
    $ExportPath,

    [Parameter()]
    [int32]$OptionalPort 
    
    )

if ($ExportPath -eq $null) {
$ReportsDir = $ExportPath
$WriteReport = $false
}
else {
$ReportsDir = $ExportPath
$WriteReport = $true
}

if ($WriteReport -eq $true -and (!(Test-Path $ReportsDir)) ) {
    New-Item -Path $ReportsDir -ItemType Directory | Out-Null 
    }

<#Temporarily dot source other functions until module is finished

try {
    . "G:\My Documents\GitHub\PSSystemInfo\Public\Get-Uptime.ps1"
    . "G:\My Documents\GitHub\PSSystemInfo\Public\Get-PendingReboot.ps1"
}
catch {
    Write-Host "Dot sourced module(s) not loaded.  Error: $_"
}
#>

if ($PSCmdlet.ParameterSetName -eq 'ByComputerList') {

$ComputerName = (Get-Content $ComputerList) 

}

$RunAsUser = $null

if ($User -eq $null -and $Pass -eq $null) { 
$RunAsUser = $True
}
if ($User -ne $null -and $Pass -eq $null) {
$Pass = Read-Host "Enter Password" -AsSecureString
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass)
}

#Create an empty array for our end results
$Results = @()

#Set the report filename
$time = (Get-Date -UFormat %H.%M.%S)
$Reportname = "ServerStatusReport_" + (Get-Date -Format MM.dd.yyyy) + "_$time.csv"


# Begin for loop on the computer array

ForEach ($Computer in $ComputerName) {
    
    #Create an object to hold each machine's results

    $Result = New-Object System.Object    
    
    #Write the hostname to the array

    $Result | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $Computer
    #Write-Host "Starting $Computer test"
    if (Test-Connection -ComputerName $Computer -Quiet -Count 1) {
        
        
        
        $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "OK"
        

        <# Commenting out the optional port code - will move to seperate function #
        if (!($OptionalPort)) {
            }
        elseif ($OptionalPort -eq '80') {
            #Write-Host "Starting port $OptionalPort test on $Computer"
            try {
            #Write-Host "$Computer debug"
            $status = Invoke-WebRequest $Computer
            #Write-Host "$Computer debug"
            $StatusCode = $status.StatusCode
            $StatusDesc = $status.StatusDescription
            #Write-Host "Port $OptionalPort on $Computer : $StatusCode $StatusDesc" -ForegroundColor Green
            }
            catch {
            #Write-Host "Port $OptionalPort on $Computer is unresponsive"  -ForegroundColor Red
            }
        $Result | Add-Member -MemberType NoteProperty -Name "Optional Port" -Value $OptionalPort
        $Result | Add-Member -MemberType NoteProperty -Name "Status Code" -Value $StatusCode
        $Result | Add-Member -MemberType NoteProperty -Name "Status Desc" -Value $StatusDesc
        }
        else {
        #Write-Host "Warning: No current checks for port $OptionalPort" -ForegroundColor Yellow
    }
    #>




$tcpport = '135'
#$Computer = "VSMSKPAUTO1"
$Computer = "badtest"

    #   Testing timout config 
    
<#
    [ScriptBlock]$tcptest = {
    $tcpobject = New-Object System.Net.Sockets.TcpClient 
    #Connect to remote machine's port               
    try {
    $connect = Invoke-Command $tcpobject.BeginConnect($computer,$tcpport,$null,$null) -ErrorAction Stop
    #Configure a timeout before quitting - time in milliseconds 
    $wait = $connect.AsyncWaitHandle.WaitOne(1000,$false) 
        If (-Not $Wait) {
            Return $false
    } Else {
    $error.clear()
    $tcpobject.EndConnect($connect) | out-Null 
    If ($Error[0]) {
        #Write-warning ("{0}" -f $error[0].Exception.Message)
    } 
    Else {
        Return $true
        }
        }
        }
    
    catch {
    $RPCOnline = $false
    Return $false
    #Write-host $_
    }
    $tcpobject = $null
}
#>

$result = $null
$Result = New-Object System.Object


#temp line
#Invoke-Command -ScriptBlock $tcptest -ArgumentList $Computer,$tcpport -OutVariable $RPCOnline -ErrorAction Stop

try {
        (Invoke-Command -ScriptBlock $tcptest -ArgumentList $Computer,$tcpport -OutVariable $RPCOnline -ErrorAction Stop)
        #$RPCOnline | Out-Null
        #$RPCOnline = (Invoke-Command -ScriptBlock $tcptest -ArgumentList $Computer,$tcpport -ErrorAction Stop)
        #(New-Object System.Net.Sockets.TCPClient -ArgumentList "$Computer",135 -ErrorAction Stop | Out-Null)
        #$RPCOnline = $true             
        if ($Computer -eq "localhost" -or $RunAsUser -eq $True) {        
            try {
                (Get-WmiObject win32_computersystem -ComputerName $Computer -ErrorAction Stop | Out-Null)
                #Write-Host "RPC connection on computer $Computer successful." -ForegroundColor Green;
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Online"
                }
            catch {
                #Write-Host "RPC connection on computer $Computer failed: $_" -ForegroundColor Red
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
                }
            }
        else {
            try {
                (Get-WmiObject win32_computersystem -ComputerName $Computer -Credential $Mycreds -ErrorAction Stop | Out-Null)
                #Write-Host "RPC connection on computer $Computer successful." -ForegroundColor Green;
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Online"
                #$Results += $Result       
                }
            catch {
                #Write-Host "RPC connection on computer $Computer failed: $_" -ForegroundColor Red
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
                #$Results += $Result       
                }
               }
}
catch {
#$Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
$Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: Port Closed"
$RPCOnline = $false
}
$RPCOnline
#$Result

       try {
       (New-Object System.Net.Sockets.TCPClient -ArgumentList "$Computer",3389 -ErrorAction Stop | Out-Null)
       #Write-Host "RDP is responsive on $Computer" -ForegroundColor Green
       $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Up"
       #$Results += $Result       
       }
       catch {
       #Write-Host "RDP is down on $Computer" -ForegroundColor Red
       $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Down"
       }


if ($RPCOnline -eq $true -and $RunAsUser -eq $True) {
       try {
       $uptime = (Get-Uptime -ComputerName $Computer)
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $uptime
       }
       
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $_
       }
    }
elseif ($RPCOnline -eq $true) {
       
       try {
       $uptime = (Get-Uptime -ComputerName $Computer -Credential $Mycreds )
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $uptime
       }
       
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $_
       }
}
else {
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value "Unknown"
}
       
       #Clear pending reboot to avoid false positives
       
       $PendingReboot = $null 


if ($Mycreds -eq $null) {       
       try {
       (Get-PendingReboot -ComputerName $Computer -ErrorAction Stop | Out-Null)
       $PendingReboot = (Get-PendingReboot -ComputerName $Computer -ErrorAction Stop)
       }
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $_
       }
    }

else {       
       try {
       (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop | Out-Null)
       $PendingReboot = (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop)
       }
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $_
       }
    }
       
       if ($PendingReboot -eq "True") {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'True'
       }
       elseif ($PendingReboot -eq "False") {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'False'
       }
       else {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $PendingReboot
       }
  
}
    else {
            # Computer doesn't even respond to ping..."
            $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Failed"
            }

# Write this machine's results to the array    
 
$Results += $Result

}

# End for loop on the computer array

# Export the array to the CSV report

$ExportPath

if ($WriteReport -eq $true) {
$Results | Export-Csv -NoTypeInformation -Path "$ReportsDir\$Reportname"       
Write-Host "Report exported to $ReportsDir\$Reportname" -BackgroundColor DarkGreen
}
else {
$Results
}

}