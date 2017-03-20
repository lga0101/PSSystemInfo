<#
.SYNOPSIS
    Get-ServerStatus.ps1 - Test network, RPC, and RDP connections, as well as gathering uptime and 
    pending reboot status against one or more computers.
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

[CmdletBinding(DefaultParameterSetName='ByComputerName')]

Param(

    [Parameter(
    Mandatory = $true, 
    ParameterSetName = 'ByComputerList')]
    [array]$ComputerList,
    
    [Parameter(
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true,
    ParameterSetName = 'ByComputerName')]
    [array]$ComputerName="$env:COMPUTERNAME",


    [Parameter()]
    [string[]]$User,

    [Parameter()]
    $Pass,

    [Parameter()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,

    [Parameter()]
    [string]$ExportPath=$(Get-Location).Path,

    #[switch]$ErrorLog,

    [switch]$ExportCSV,
    
    [switch]$ExportXLSX

    )

$WriteReport = $false

if ($ExportXLSX) {
    try {
        Import-Module ImportExcel -ErrorAction Stop | Out-Nulll
        }
    catch {
        Write-Host "`nYou must install the ImportExcel module first to export to XLSX" -BackgroundColor DarkRed -ForegroundColor White
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            Write-Host "Choose " -NoNewline 
            Write-Host "-ExportCSV " -BackgroundColor Yellow -ForegroundColor Black -NoNewline        
            Write-Host "or run "  -NoNewline 
            Write-Host "Install-Module ImportExcel -scope CurrentUser"  -BackgroundColor Yellow -ForegroundColor Black -NoNewline
            Write-Host " to install`n" 
        }
        else {
            Write-Host "Choose " -NoNewline 
            Write-Host "-ExportCSV " -BackgroundColor Yellow -ForegroundColor Black -NoNewline        
            Write-Host "or visit "  -NoNewline 
            Write-Host "https://github.com/dfinke/ImportExcel "  -BackgroundColor Yellow -ForegroundColor Black -NoNewline
            Write-Host "for install instructions" 
        }
        break
        }
}

if ($ExportCSV -or $ExportXLSX) {
$WriteReport = $true
}

if ($ExportCSV -and $ExportXLSX) {
$ExportXLSX = $null
Write-Host "Multiple export options set; disabling ExportXLSX, only one is allowed"
}

$time = (Get-Date -UFormat %H.%M.%S)

$ExtensionCheck = $null

#if ($ExportPath) {
#    write-host "export path specified"
#    $WriteReport = $true
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
#}
<#
else  {
#$WriteReport = $false
$WriteReport = $true
$ExportPath = (Get-Location).Path
write-host "$exportpath should be the current working dir"
}#>


if ($WriteReport -eq $true -and $ExportPath[-1] -eq "\") {
    $ExportPath = $ExportPath.Substring(0,$ExportPath.Length-1)
    write-host "debug write report file ext check, exportpath is $ExportPath"
    }  


$ErrorLog = $true

if ($ErrorLog) {

try {
    #Import-Module PSLogging -ErrorAction Stop 
    #$LogPath = ".\"
    $LogPath = $ExportPath
    $LogName = “ServerStatus_ErrorLog_" + (Get-Date -Format MM.dd.yyyy) + "_$time.log”
    Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion “1.0” | Out-Null
    $Log = "$LogPath\$LogName"
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
$SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
}

elseif ($User -ne $null -and $Pass -eq $null) {
$SecPass = Read-Host "Enter Password" -AsSecureString
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
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
         $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Online"
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
                       $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error"
                       Write-LogError -LogPath $Log -Message “$Computer : Error: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                       }
                   
      #     Uptime Try/Catch             
                   try {
                    $uptime = (Get-Uptime -ComputerName $Computer -Credential $mycreds)
                    $Result | Add-Member -MemberType NoteProperty -Name "Uptime (DD:HH:MM)" -Value $uptime
                    }
                   catch{
                    $Result | Add-Member -MemberType NoteProperty -Name "Uptime (DD:HH:MM)" -Value "Unknown"
                    Write-LogError -LogPath $Log -Message “$Computer : Error: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                   }


      #  Pending Reboot Try/Catch - clear pending reboot to avoid false positives

                    $PendingReboot = $null

                    try {
                        $PendingReboot = (Get-PendingReboot -ComputerName $Computer -Credential $mycreds -ErrorAction Stop)
                        }                        
                    catch {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value "Error"
                        Write-LogError -LogPath $Log -Message “$Computer : Error: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                        }

                        if ($PendingReboot -eq "" -or $PendingReboot -eq "Unknown" -or $PendingReboot -eq "Pending Reboot") {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value $pendingreboot
                        }
                        elseif ($PendingReboot -eq "False") {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value ""
                        }
                        elseif ($PedingReboot -notmatch "^\d{2}.\d{2}.\d{2}") {
                        $Result | Add-Member -MemberType NoteProperty -Name "Pending Reboot" -Value "Error"
                        Write-LogError -LogPath $Log -Message “$Computer : Pending Reboot Error from catch: $_ ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
                        }
                        
                    
}

         
}           
                

    }
       
    else {
            # Computer doesn't even respond to ping...
            $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Failed"
            Write-LogError -LogPath $Log -Message “$Computer Error: Ping Failed ” -ErrorAction SilentlyContinue -TimeStamp | Out-Null
        }

# Write this machine's results to the array    
 
$Results += $Result

}

# End for loop on the computer array

# Export the array to the CSV report

if ($WriteReport -eq $true) {
#$Results | Export-Csv -NoTypeInformation -Path "$ExportPath\$Reportname"    
$Results | Export-Excel $ExportPath\$Reportname 
Write-Host "Report exported to $ExportPath\$Reportname" -BackgroundColor DarkGreen
}
elseif ($ExportCSV) {
$ReportName =  ($Reportname).Replace("xlsx","csv")
$Results | ConvertTo-CSV -NoTypeInformation | Out-File  "$ExportPath\$Reportname"
}

else {
$Results | fl *
}

if ($ErrorLog) {
Stop-Log -LogPath $Log -NoExit
Write-Host "Error log written to $Log" -BackgroundColor DarkGreen
}

}