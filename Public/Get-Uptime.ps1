Function Get-Uptime {
       
       param (
       
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName       
        )

       try {
       $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
       $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
       $Time = (Get-Date) - $LastBootUpTime
       Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
       }
       catch {
       Return $_
       }
}    