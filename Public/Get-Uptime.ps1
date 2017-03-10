Function Get-Uptime {
       
       param (
       
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]
        $ComputerName="$env:COMPUTERNAME",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty

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
       Return '{0:D2}:{1:00}:{2:00}' -f $Time.Days, $Time.Hours, $Time.Minutes
       }
       catch {
       Return $_
       }
}    