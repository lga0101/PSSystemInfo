Function Get-Uptime {
       
       param (
       
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName,

        [Parameter()]
        $Credential
    
        )       
    

       try {
       if ($Credential -eq $null) {
       $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
       }
       else { 
       $Uptime = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop 
       }
       $LastBootUpTime = $Uptime.ConvertToDateTime($Uptime.LastBootUpTime)
       $Time = (Get-Date) - $LastBootUpTime
       #Return '{0:00} Days, {1:00} Hours, {2:00} Minutes, {3:00} Seconds' -f $Time.Days, $Time.Hours, $Time.Minutes, $Time.Seconds
       Return '{0:00}:{1:00}:{2:00}' -f $Time.Days, $Time.Hours, $Time.Minutes
       }
       catch {
       Return $_
       }
}    