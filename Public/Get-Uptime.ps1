Function Get-Uptime {
       param ([string]$ComputerName)
       $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
       $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
       $Time = (Get-Date) - $LastBootUpTime
       Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
}