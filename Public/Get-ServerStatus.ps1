<#
.SYNOPSIS
    Get-ServerStatus.ps1 - Test an RPC and RDP connection against one or more computer(s)
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
    $ComputerList,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ByComputerName')]
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

#Temporarily dot source other functions until module is finished

try {
    . "C:\backup\Scripts\PSSystemInfo\Public\Get-Uptime.ps1"
}
catch {
    Write-Host "Uptime module not loaded.  Error: $_"
}

#Import-Module .\Get-PendingReboot.ps1


#If list is specified, try to get content from that list

<#
if ($List) {
$ComputerName = (Get-Content $List)
#$ComputerName = (Read-Host "Please enter the path to the computer list")
#$ComputerName = Get-Content $ComputerName
}
#>

if ($PSCmdlet.ParameterSetName -eq 'ByComputerList') {
$ComputerName = (Get-Content $ComputerList)
#foreach ($pc in $ComputerName)
#{Write-Host $pc}
#$ComputerName | gm
#$ComputerName = (Read-Host "Please enter the path to the computer list")
#$ComputerName = Get-Content $ComputerName
}



if ($User -eq $null -and $Pass -eq $null) { 
Write-Host "debug null user"
$User = Read-Host "Enter Username"
$Pass = Read-Host "Enter Password" -AsSecureString
#$Secpasswd = ConvertTo-SecureString $Pass -Force 
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass) 
}
if ($User -ne $null -and $Pass -eq $null) {
$Pass = Read-Host "Enter Password" -AsSecureString
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Pass)
}
else {
Write-Host "debug non null user"
$Secpasswd = ConvertTo-SecureString $Pass -AsPlainText -Force 
$Mycreds = New-Object System.Management.Automation.PSCredential ($User, $Secpasswd)
}

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

             
        if ($Computer -eq "localhost") {        
            try {
                (Get-WmiObject win32_computersystem -ComputerName $Computer -ErrorAction SilentlyContinue | Out-Null)
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
                (Get-WmiObject win32_computersystem -ComputerName $Computer -ErrorAction SilentlyContinue -Credential $Mycreds | Out-Null)
                #Write-Host "RPC connection on computer $Computer successful." -ForegroundColor Green;
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Online"
                }
            catch {
                #Write-Host "RPC connection on computer $Computer failed: $_" -ForegroundColor Red
                $Result | Add-Member -MemberType NoteProperty -Name "RPC" -Value "Error: $_"
                }
               }

       try {
       (New-Object System.Net.Sockets.TCPClient -ArgumentList "$Computer",3389 -ErrorAction SilentlyContinue | Out-Null)
       #Write-Host "RDP is responsive on $Computer" -ForegroundColor Green
       $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Up"
       }
       catch {
       #Write-Host "RDP is down on $Computer" -ForegroundColor Red
       $Result | Add-Member -MemberType NoteProperty -Name "RDP" -Value "Down"
       }
       
       try {
       #(Get-Command Get-Uptime)
       $uptime = (Get-Uptime -ComputerName $Computer)
       #Write-Host "$Computer has been up for $uptime"
      
       $Result | Add-Member -MemberType NoteProperty -Name "System Uptime" -Value $uptime
       $Results += $Result       
       $Results | Export-Csv -NoTypeInformation -Path "C:\backup\Reports\$Reportname"
       
       }
       catch {
       Write-Host $_
       }
    
    }
    else {
            #Write-Host "$Computer doesn't even respond to ping... `r" -ForegroundColor Red;
            $Result | Add-Member -MemberType NoteProperty -Name "Ping Result" -Value "Failed"
            $Results += $Result
            $Results | Export-Csv -NoTypeInformation -Path "C:\backup\Reports\$Reportname"
        }
       
}
}