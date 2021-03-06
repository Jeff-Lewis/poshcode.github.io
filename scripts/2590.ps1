function Get-CountDown() {

<#
    .Synopsis
       CountDown timer and progress bar
    
    .Description
       A simple countdown timer as an advanced function. 
       Displays the time remaining along with a_ 
       progress bar displaying percentage time elapsed.  
       If no parameters are passed, the script will_
       default to 1 hour. 
       
    .parameter hours
       Hours
    .parameter Minutes
       Minutes
    .parameter Seconds
       Seconds
       
    .Example
       Get-CountDown -hours 1 -Mins 30 -Seconds 30
       
    Description
    -----------
    Will display a 1:30:30 countdown along with progress bar. 
           
    .Example 
       c:\> powershell c:\scripts\Get-CountDown.ps1 -hours 1
    
    Description
    -----------
    How to run script from a DOS command line, batch file or shortcut.
    Will display a 1 hour countdown
     
    .Notes
       NAME:      Get-CountDown.ps1
       VERSION:   2.0
       AUTHOR:    Matthew Painter
       LASTEDIT:  28/03/2011

       HISTORY:   1.0 02/22/2011 By xb90 at http://poshtips.com
                  2.0 28/03/2011 By MJP - Practice for Scripting games
       
#>


    [CmdletBinding()]

    param(
    [Parameter(
    Mandatory=$false)]
    [int]$hours=0,
  
    [Parameter(
    Mandatory=$false)]
    [int]$minutes=0,
  
    [Parameter(
    Mandatory=$false)]
    [int]$seconds=0
    )
    
    #if no time passed then default to 1 hour
    if($hours-eq0 -and $minutes-eq0 -and $seconds-eq0){
    $hours=1
    }
    
    #setup timespan variables
	$startTime = get-date
	$endTime = $startTime.addHours($hours)
	$endTime = $endTime.addMinutes($minutes)
	$endTime = $endTime.addSeconds($seconds)

    $Check=0
    $timeSpan = new-timespan $(get-date) $endTime
    
    #loop to update progress bar
    while ($timeSpan -gt 0) {
		$timeSpan = new-timespan $(get-date) $endTime
        if($Check -ne 1){$timeSpan2=$timeSpan;$Check=1}
                 
        #generate time remaining string                
		$TimeRemaining = $([string]::Format("Time Remaining: {0:d2}:{1:d2}:{2:d2}", `
		$timeSpan.hours, `
		$timeSpan.minutes, `
		$timeSpan.seconds))
        
        #calc percent time elapsed
        $percentRem = ([math]::round($timeSpan.ticks/$timeSpan2.ticks*100,0))
        if($percentRem-lt0){$percentRem=0}
        $percentRem=100-$percentRem
        
        write-progress -activity "Shutdown" -status $TimeRemaining -percentcomplete $percentRem 
        
		sleep 1
		}
	}

get-countdown

