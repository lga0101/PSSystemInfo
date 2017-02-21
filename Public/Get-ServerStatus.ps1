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

    $Result | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $Computer -Verbose

    #Write-Host "Starting $Computer test"
    if (Test-Connection -ComputerName $Computer -Quiet -Count 1) {
        $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Online"
        

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


    $RPCOnline = (Test-Port $Computer -Port 135 -ErrorAction Stop)
        Switch ($RPCOnline) {
        "False" {
            $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: Port Closed"
        }
        "True" {
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
        }

       try {
       $RDPOnline = (Test-Port $Computer -Port 3389 -ErrorAction Stop)
       Switch ($RDPOnline) {
       "False" {
            $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Down"
            }
       "True" {
            $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Up"
       }
       }
       }
       catch {
       Write-Host $_
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

try {
    $WSManOnline = (Test-Port $Computer -Port 5985 -ErrorAction Stop)
}
catch {
    $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required"  -Value 'Unknown'
}


switch ($WSManOnline) {
    "False" { 
        $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'Unkown'
     }
    Default {
        
    }
}
if ($Mycreds -eq $null) {
    $command = (Get-PendingReboot -ComputerName $Computer -ErrorAction Stop | Out-Null)
}
else {
    $command = (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop)
}

if ($Mycreds -eq $null) {       
       try {
       (Get-PendingReboot -ComputerName $Computer -ErrorAction Stop | Out-Null)
       $PendingReboot = (Get-PendingReboot -ComputerName $Computer -ErrorAction Stop)
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $PendingReboot
       }
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $_
       }
    }

else {       
       try {
       $WSManOnline = (Test-Port $Computer -Port 5985 -ErrorAction Stop)
       Switch ($WSManOnline) {
       "False" {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'False'
       }
       "True" {
       $PendingReboot = (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop)
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'True'
       }
       Default {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value 'Unkown'
       }
       }
       }
       catch {
       $Result | Add-Member -MemberType NoteProperty -Name "Reboot Required" -Value $_
       }
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