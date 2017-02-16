<#
.SYNOPSIS
    Get-ServerStatus.ps1 - Test an RPC and RDP connection against one or more computers
.DESCRIPTION
    Get-ServerStatus.ps1 - Test an RPC connection (WMI request) against one or more computer(s)
    with test-connection before to see if the computer is reachable or not first
.PARAMETER ComputerName
    Defines the computer name or IP address to tet the RPC connection. Could be an array of servernames
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
    [int32]$OptionalPort 
    
    )

$ReportsDir = "G:\My Documents\Reports\"

if (!(Test-Path $ReportsDir)) {
    New-Item -Path "G:\My Documents\Reports\" -ItemType Directory | Out-Null 
    }

#Temporarily dot source other functions until module is finished

try {
    . "G:\My Documents\GitHub\PSSystemInfo\Public\Get-Uptime.ps1"
    . "G:\My Documents\GitHub\PSSystemInfo\Public\Get-PendingReboot.ps1"
}
catch {
    Write-Host "Dot sourced module(s) not loaded.  Error: $_"
}

if ($PSCmdlet.ParameterSetName -eq 'ByComputerList') {

$ComputerName = (Get-Content $ComputerList) 
}

if ($User -eq $null -and $Pass -eq $null) { 
#Write-Host "debug null user"
#$User = Read-Host "Enter Username"
$User = (whoami)
$Pass = Read-Host "Enter Password" -AsSecureString
#$Secpasswd = ConvertTo-SecureString $Pass -Force 
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass) 
}
if ($User -ne $null -and $Pass -eq $null) {
$Pass = Read-Host "Enter Password" -AsSecureString
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass)
}
#else {
#Write-Host "debug non null user"
#$Secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force 
#$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Secpasswd)
#}

#Create an empty array for our end results
$Results = @()

#Set the report filename
$time = (Get-Date -UFormat %H.%M.%S)
$Reportname = "ServerStatusReport_" + (Get-Date -Format MM.dd.yyyy) + "_$time.csv"


#Begin forloop on the computer array
ForEach ($Computer in $ComputerName) {
    
    #Create an object to hold each machine's results

    $Result = New-Object System.Object    
    
    #Write the hostname to the array

    $Result | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $Computer
    #Write-Host "Starting $Computer test"
    if (Test-Connection -ComputerName $Computer -Quiet -Count 1) {
        
        
        
        $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "OK"
        
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


try {
        (New-Object System.Net.Sockets.TCPClient -ArgumentList "$Computer",135 -ErrorAction Stop)
        $RPCOnline = $true             
        if ($Computer -eq "localhost") {        
            try {
                (Get-WmiObject win32_computersystem -ComputerName $Computer -ErrorAction Stop )
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
                (Get-WmiObject win32_computersystem -ComputerName $Computer -Credential $Mycreds -ErrorAction Stop)
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
$Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
$RPCOnline = $false
}

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


if ($RPCOnline -eq $true) {
       try {
       Get-Uptime -ComputerName $Computer -ErrorAction Stop
       $uptime = (Get-Uptime -ComputerName $Computer)
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $uptime
       }
       
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $_
       }
    }
else {
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value "Unknown"
}

       try {
       Get-PendingReboot -ComputerName $Computer -ErrorAction Stop
       $PendingReboot = Get-PendingReboot -ComputerName $Computer
       }
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $_
       }

       if ($PendingReboot -eq "True") {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'True'
       }
       elseif ($PendingReboot -eq 'False') {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'False'
       }
       elseif ($PendingReboot -ne $exception)  {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'Unknown'
       }
       #Write-Host "$Computer needs a reboot? $PendingReboot" 
    }
    else {
            #Write-Host "$Computer doesn't even respond to ping... `r" -ForegroundColor Red;
            $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Failed"
            #$Results += $Result
            #$Results | Export-Csv -NoTypeInformation -Path "$ReportsDir\$Reportname"
            }
$Results += $Result
}
#Write-Host $Computer
#$Results

#Write the results to the array and export to the reports path

$Results | Export-Csv -NoTypeInformation -Path "$ReportsDir\$Reportname"       
}