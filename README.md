# PSSystemInfo

PSSystemInfo is a PowerShell module to query and display machine stats including Ping Results, RDP status, RPC status, Uptime, and Pending Reboot status. You can also export to CSV and XLSX (with additional module install).    

Installation
-
[Powershell V5](https://www.microsoft.com/en-us/download/details.aspx?id=50395) and Later
can install PSSystemInfo directly from the Powershell Gallery

* [Recommended] Install to your personal Powershell Modules folder
```powershell
Install-Module PSSystemInfo -scope CurrentUser
```
* [Requires Elevation] Install for Everyone (computer Powershell Modules folder)
```powershell
Install-Module PSSystemInfo 
```

Powershell V4 and Earlier
Download ZIP and extract to one of your PSModulePath's


```powershell

Get-ServerStatus -ComputerList Servers.txt 


```