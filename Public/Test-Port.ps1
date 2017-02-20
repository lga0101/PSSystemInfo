Function Test-Port {

[cmdletbinding(   
    DefaultParameterSetName = '',   
    ConfirmImpact = 'low'   
)]   

Param(

    [Parameter(   
    Mandatory = $True,   
    Position = 0,   
    ParameterSetName = '',   
    ValueFromPipeline = $True)]   
    [array]$Computer,
    
    [Parameter(   
    Position = 1,   
    Mandatory = $True,   
    ParameterSetName = '')]   
    [string]$Port,
    
    [Parameter(   
    Mandatory = $False,   
    ParameterSetName = '')]   
    [int]$TCPtimeout=1000      

)
$Report = @() 

foreach ($pc in $computer) {
                    $temp = "" | Select Server, Port, TypePort, Open, Notes   
                    $tcpobject = new-Object system.Net.Sockets.TcpClient   
                    #Connect to remote machine's port                 
                    $connect = $tcpobject.BeginConnect($pc,$port,$null,$null)   
                    #Configure a timeout before quitting   
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)   
                    #If timeout   
                    If(!$wait) {   
                        #Close connection   
                        $tcpobject.Close()   
                        Write-Verbose "Connection Timeout"   
                        #Build report   
                        $temp.Server = $pc   
                        $temp.Port = $port   
                        $temp.TypePort = "TCP"   
                        $temp.Open = "False"   
                        $temp.Notes = "Connection to Port Timed Out"   
                    } Else {   
                        $error.Clear()   
                        $tcpobject.EndConnect($connect) | out-Null   
                        #If error   
                        If($error[0]){   
                            #Begin making error more readable in report   
                            [string]$string = ($error[0].exception).message   
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()   
                            $failed = $true   
                        }   
                        #Close connection       
                        $tcpobject.Close()  
      #If unable to query port to due failure   
                        If($failed){   
                            #Build report   
                            $temp.Server = $pc   
                            $temp.Port = $port   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "False"   
                            $temp.Notes = "$message"   
                        } Else{   
                            #Build report   
                            $temp.Server = $pc   
                            $temp.Port = $port   
                            $temp.TypePort = "TCP"   
                            $temp.Open = "True"     
                            $temp.Notes = ""   
                        }   
                    }      

$failed = $Null
#Merge temp array with report               
$report += $temp                   
}       
                   

$report
}