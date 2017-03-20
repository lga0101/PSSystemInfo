# PSSystemInfo

PSSystemInfo is a PowerShell module to query and display machine stats including Ping Results, RDP status, RPC status, Uptime, and Pending Reboot status. You can also export to CSV and XLSX (with additional module install).    

## Installation

#### [Powershell V5](https://www.microsoft.com/en-us/download/details.aspx?id=50395) and Later can install PSSystemInfo directly from the Powershell Gallery

* [Recommended] Install to your personal Powershell Modules folder
```powershell
Install-Module PSSystemInfo -scope CurrentUser
```
* [Requires Elevation] Install for Everyone (computer Powershell Modules folder)
```powershell
Install-Module PSSystemInfo 
```

#### Powershell V4 and Earlier

* Download ZIP and extract to one of your Powershell Modules folder

## Usage and Examples

* Query the local machine

```powershell

Get-ServerStatus 

```

* Query a list of servers and export to CSV

```powershell

Get-ServerStatus -ComputerList Servers.txt -ExportCSV

```

* Query a list of servers as another user (you will be prompted with a secure credential input) and export to XLSX

Note: You MUST install [ImportExcel](https://github.com/dfinke/ImportExcel) in order to export to an XLSX. To do so:

#### ImportExcel install
* Powershell v5
```powershell
Install-Module ImportExcel -scope CurrentUser
```
* Powershell V4 and Earlier
```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/dfinke/ImportExcel/master/Install.ps1')
```

```powershell

Get-ServerStatus -ComputerList Servers.txt -Credential AdminUser 

```

* Query a list of servers as another user with password specified in plain text. Not best practices since the string will be insecure in memory, but useful for scripting

```powershell

Get-ServerStatus -ComputerList Servers.txt -User AdminUser -Pass AdminPass

```