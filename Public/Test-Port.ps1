function Test-Port {


Param(
    
    [Parameter(Mandatory = $true)]
    $Computer,

    [Parameter()]
    $TCPPort
    )



    [ScriptBlock]$tcptest = {
    $tcpobject = New-Object System.Net.Sockets.TcpClient 
    #Connect to remote machine's port               
    try {
    $connect = Invoke-Command $tcpobject.BeginConnect($computer,$tcpport,$null,$null) -ErrorAction Stop
    #Configure a timeout before quitting - time in milliseconds 
    $wait = $connect.AsyncWaitHandle.WaitOne(1000,$false) 
        If (-Not $Wait) {
            Return $false
    } Else {
    $error.clear()
    $tcpobject.EndConnect($connect) | out-Null 
    If ($Error[0]) {
        #Write-warning ("{0}" -f $error[0].Exception.Message)
    } 
    Else {
        Return $true
        }
        }
        }
    
    catch {
    $RPCOnline = $false
    Return $false
    Write-host $_
    }
        
    }

    $computer = "VSMSKPAUTO1"
    $TCPPort = "135"

    Invoke-Command -ScriptBlock $tcptest -ArgumentList $Computer,$tcpport -ErrorAction Stop

}