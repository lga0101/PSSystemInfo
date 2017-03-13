<#
.SYNOPSIS
    Get-ServerStatus.ps1 - Test network, RPC, and RDP connections, as well as gathering uptime and pending reboot status against one or more computers.
.DESCRIPTION
    Get-ServerStatus.ps1 - Test an RPC connection (WMI request) against one or more computer(s)
    with test-connection before to see if the computer is reachable or not first
.PARAMETER ComputerList
    Defines the path to the file containing a list of servers to test against, either by hostname or IP address.
.PARAMETER ComputerName
    Defines the computer name or IP address to test against. Could be an array of server names.
.PARAMETER User
    Username 
.PARAMETER Pass
    Password
.NOTES
    File Name    : Get-ServerStatus.ps1
    Author       : Marcus Daniels - danielm1@mskcc.org
    Adapted From : RPC-Ping.ps1 by Fabrice ZERROUKI - fabricezerrouki@hotmail.com
.EXAMPLE
    PS D:\> Get-ServerStatus.ps1 -ComputerList C:\servers.txt -ExportPath C:\Reports\
    Get server status from a list of servers and export to a CSV at the defined path. 
.EXAMPLE
    PS D:\> Get-ServerStatus.ps1 -ComputerName SERVER1
    Get server status for SERVER1 as current user
.EXAMPLE
    PS D:\> Get-ServerStatus.ps1 -ComputerName SERVER1,192.168.0.23 -Credential JSMith
    Get server status for SERVER1 and 192.168.0.23 as a supplied user.  Can also pass "-Credential (Get-Credential)" for a Windows security prompt. 
#>

function Get-ServerStatus {

[CmdletBinding(DefaultParameterSetName='ByComputerList')]

Param(

    [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerList')]
    [array]$ComputerList,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerName')]
    [array]
    $ComputerName,


    [Parameter()]
    [string[]]
    $User,

    [Parameter()]
    $Pass,

    [Parameter()]
    [string]
    $ExportPath,

     
    [switch]
    $ErrorLog

    )


Import-Module ImportExcel

$time = (Get-Date -UFormat %H.%M.%S)

$ExtensionCheck = $null

if ($ExportPath) {
    $WriteReport = $true
    $ExtensionCheck = (Get-Extension -ExportPath $ExportPath)
    Switch ($ExtensionCheck) {
    "True" {
            do { 
                $ExportPath = Read-Host "Invalid path or directory. Filenames are not allowed"
                $ExtensionCheck = (Get-Extension -ExportPath $ExportPath)
                }
            while ($ExtensionCheck -eq "True")
            }
    "False" {
            }
        }
}

else  {
$WriteReport = $false
}


if ($WriteReport -eq $true -and $ExportPath[-1] -eq "\") {
    $ExportPath = $ExportPath.Substring(0,$ExportPath.Length-1)
    }  

if ($ErrorLog) {

try {
    Import-Module PSLogging -ErrorAction Stop 
    $LogPath = ".\"
    $LogName = “ServerStatus_ErrorLog_" + (Get-Date -Format MM.dd.yyyy) + "_$time.log”
    Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion “1.0” | Out-Null
    $Log = $LogPath + $LogName
    }
catch {
    Write-Host $_
    }
}


if ($WriteReport -eq $true -and (!(Test-Path $ExportPath)) ) {
    New-Item -Path $ExportPath -ItemType Directory | Out-Null 
    }

if ($PSCmdlet.ParameterSetName -eq 'ByComputerList') {
$ComputerName = (Get-Content $ComputerList) 
}

# Reset the user just in case

$RunAsUser = $null

# Authentication logic

if ($User -and $Pass) {
$Pass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass)
}

elseif ($User -ne $null -and $Pass -eq $null) {
$Pass = Read-Host "Enter Password" -AsSecureString
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass)
}

#elseif ($User -eq $null -and $Pass -eq $null) { 
else { 
$RunAsUser = $True
$mycreds = [System.Management.Automation.PSCredential]::Empty
}

# Create an empty array for our end results #
$Results = @()

# Set the report filename #
$Reportname = "ServerStatusReport_" + (Get-Date -Format MM.dd.yyyy) + "_$time.xlsx"

# Begin main for loop on the computer array

ForEach ($Computer in $ComputerName) {

    # Start progress bar
    $i++
    $progress = [math]::truncate(($i / $computername.length)  * 100) 
    Write-Progress -activity "Checking $computer" -status "$Progress percent complete: " -PercentComplete (($i / $computername.length)  * 100)
    
    # Create an object to hold each machine's results #
    $Result = New-Object System.Object    
    
    # Write the hostname to the array #
    $Result | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $Computer -Verbose

    # Starting main if/else statement: pass/fail ping test #
    if (Test-Connection -ComputerName $Computer -Quiet -Count 1) {
        $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Online"
    #   RDP Try/Catch
                
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
    $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Unknown"
     }        

  #   First an RPC port test

  $RPCOnline = (Test-Port $Computer -Port 135 -ErrorAction Stop)

    Switch ($RPCOnline) {
        "False" {
            $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Down"
        }
        "True" {
        #   RPC Try/Catch via WMI call
        
                   try {
                       (Get-WmiObject win32_computersystem -ComputerName $Computer -Credential $Mycreds -ErrorAction Stop | Out-Null)
                       $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Online"
                       }
                   catch {
                       $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
                       }
                   
      #     Uptime Try/Catch             
                   try {
                    $uptime = (Get-Uptime -ComputerName $Computer -Credential $mycreds)
                    $Result | Add-Member -MemberType NoteProperty -Name "Uptime (DD:HH:MM)" -Value $uptime
                    }
                   catch{
                    $Result | Add-Member -MemberType NoteProperty -Name "Uptime (DD:HH:MM)" -Value "Unknown"
                   }

      #  Pending Reboot Try/Catch - clear pending reboot to avoid false positives

                    $PendingReboot = $null

                    try {
                        $PendingReboot = (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop)
                        if ($PendingReboot -eq "" -or $PendingReboot -eq "Unknown" -or $PendingReboot -eq "Pending Reboot") {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value $pendingreboot
                        }
                        elseif ($PendingReboot -eq "False") {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value ""
                        }
                        <#
                        else {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value "Error"
                        Write-LogError -LogPath $Log -Message “$Computer : Pending Reboot Error from last else: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                        }
                        #>
                    }
                    catch {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value "Error"
                        Write-LogError -LogPath $Log -Message “$Computer : Pending Reboot Error from catch: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                    }
            }

         
}           
                

    }
       
    else {
            # Computer doesn't even respond to ping...
            $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Failed"
        }

# Write this machine's results to the array    
 
$Results += $Result

}

# End for loop on the computer array

# Export the array to the CSV report

if ($WriteReport -eq $true) {
#$Results | Export-Csv -NoTypeInformation -Path "$ExportPath\$Reportname"    
$Results | Export-Excel $Reportname 
Write-Host "Report exported to $ExportPath\$Reportname" -BackgroundColor DarkGreen
}
else {
#($Results | Export-Excel ((Get-Date -Format MM.dd.yyyy) + "_$time.xlsx"))
$Results | fl *
}

if ($ErrorLog) {
Stop-Log -LogPath $Log -NoExit
Write-Host "Error log written to $log"
}

}