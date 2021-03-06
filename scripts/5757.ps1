function Start-ScriptThreading{
<#   
.SYNOPSIS
   
    Runs a scriptblock against multiple computers simultaneously 

.DESCRIPTION
 
    The ThreadedFunction function takes an array (usually a list of computers) and a scriptblock. The scriptblock will be run against
    each item in the array expecting each item of the array to also be a parameter expected in the scriptblock. 

.PARAMETER arComputers
 
    List of computers to run scriptblock against. 

.PARAMETER ScriptBlock
 
    Block of script to run against list from parameter -Computers   

.PARAMETER maxThreads
 
    Maximum number of threads to run at a time  

.PARAMETER SleepTimer
 
    Time to wait between loops. This is a spacing timer to prevent the main loop from hogging cpu time. 
    A smaller number may create and check for jobs faster.
    A large number will allow the separate threads more cpu time.  
    Any longer than 1000 milliseconds may render the progress indicator incorectly.
    (default is 500 milliseconds)   

.PARAMETER MaxWaitAtEnd

    Sets a timeout for threads before killing jobs. This timer is started after the last thread is created.
    (default is 180 seconds)              

.NOTES
   
    Name: ThreadedScript
    Author: Kenneth W Hightower JR (The13thDoctor)
    DateCreated: 11Feb2015
    DateModified: 25Feb2015


    
    To load this function into the current shell for use, or to use this file seperate from your main script,
 
    dot-source as follows '. .\ThreadedFunction.ps1'    

.EXAMPLE
   
    ThreadedScript -Computers 'server01', 'server02' -ScriptBlock {ping $Computer}

    The command 'ping' is threaded and ran against both server01 and server02. Declaring $Computer is required as is.

.EXAMPLE
   
    'server01', 'server02' | ThreadedScript -ScriptBlock {Get-WMIObject win32_computersystem -ComputerName $Computer}
 
    Pipes the array as Computers and gets the Win32_ComputerSystem WMI object from server01 and server02 simultaneously.   

.INPUTS

    System.String. Function will accept an array of strings and assume each as a parameter for the provided scriptblock.

.OUTPUTS

    System.Object. All returned data from each iteration that the scriptblock may create is returned as a single array.
           

#>  
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$arComputers,
        [parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory=$false)]
        [int]$maxThreads = 30,
        [parameter(Mandatory=$false)]
        [int]$SleepTimer = 500,
        [parameter(Mandatory=$false)]
        [int]$MaxWaitAtEnd = 180
    )
    BEGIN{
        Write-Verbose "Initializing..."
        $return = @()
        $StartTime= Get-Date
    
        #Create working scriptblock
        $Script = [ScriptBlock]::Create( @"
param(`$Computer)
&{ $ScriptBlock } @PSBoundParameters
"@ )
    $Computers = @()
    }
    PROCESS{
    
        foreach($Computer in $arComputers){
            $Computers += $Computer #Yes, this will flatten multi-dimentional arrays... 
        }
    } 
#when you pipeline to this function the begin section is called once, then for each item in the pipeline the entire process block is called.
#In order to collect all items in the pipeline so that everything passed in can be threaded simultaneously as intended, we handle the threading at the end.
#Otherwise each item will get threaded and collected before the next item is threaded.
    END{
        #Start Making Jobs
        Write-Verbose "creating threads..."
        Foreach($Computer in $Computers){
        
            #Check for running threads
            while ($(Get-Job -State Running | measure-object).count -ge $maxThreads){
    		    write-host "$((Get-Job -State Running | measure-object).count) threads running, please wait..."
    		    start-sleep -s 3
    	    } # End while ($(Get-Job -State Running
        
            Write-Verbose "starting $($Computer)"
            Start-Job -name $Computer -scriptblock $Script -ArgumentList $Computer
        
            #Pretty progress indicator
            $ComputersStillRunning = ""
            ForEach ($System  in $(Get-Job -state running)){
                $ComputersStillRunning += ", $($System.name)"
            }
            $ComputersStillRunning = $ComputersStillRunning.TrimStart(", ")
            Write-Progress  -Activity "Creating Jobs" `
                            -Status "$($(Get-Job -State Running).count) threads running..." `
                            -CurrentOperation "$ComputersStillRunning" `
                            -PercentComplete ($(Get-Job -State Completed).count / $(Get-Job).count * 100)

            #Check for completed Jobs. Depending on number of jobs, we might as well collect data as we go.
            ForEach($Job in $(Get-Job -State Completed)){
                If($Job.HasMoreData -eq "True"){
                    Write-Verbose "Job $($Job.Id) finished early"
                    $Data = Receive-Job $Job
                    $Return+=$Data
                }#end if($job.hasmoredata...
            }#end foreach($Job...
        }#end Foreach($Computer in...
    
        #Done creating jobs.
        Write-Verbose "Waiting for final threads..."
        $Complete = Get-date

        #Wait for the last created jobs to finish
        #Following loop gets skipped if pipeline is used to pass $Computers
        While ($(Get-Job -State Running | measure-object).count -gt 0){
        
            #random information for progress screen
            $ComputersStillRunning = ""
            $TimeDiff = New-TimeSpan $StartTime $(Get-Date)
            [string]$strTimingStatus = "{0} minutes, {1} seconds so far" -f $TimeDiff.Minutes, $TimeDiff.Seconds
            ForEach ($System  in $(Get-Job -state running)){
                $ComputersStillRunning += ", $($System.name)"
            }
            $ComputersStillRunning = $ComputersStillRunning.TrimStart(", ")
            Write-Progress  -Activity "Waiting for completion..." `
                            -Status "$($(Get-Job -State Running).count) threads remaining: $strTimingStatus" `
                            -CurrentOperation "$ComputersStillRunning" `
                            -PercentComplete ($(Get-Job -State Completed).count / $(Get-Job).count * 100)

            #Collecting jobs as we wait
            ForEach($Job in $(Get-Job -State Completed)){
                If($Job.HasMoreData -eq "True"){
                    Write-Verbose "Job $($Job.Id) just completed"
                    $Data = Receive-Job $Job
                    $return+=$Data
                }#end if($job.hasmoredata
            }#end foreach($Job

            #Done waiting. Threads most likely hung up on something, throw them away.
            If ($(New-TimeSpan $Complete $(Get-Date)).totalseconds -ge $MaxWaitAtEnd){
        	    Write-Verbose "Killing all jobs still running, tired of waiting..."
        	    Get-Job -State Running | Remove-Job -Force
    	    }

            #Lets not bog the CPU with lightning speed looping
            Start-Sleep -Milliseconds $SleepTimer
        }
    
        #Final cleaning, just in case....
        ForEach($Job in $(Get-Job -State Completed)){
            If($Job.HasMoreData -eq "True"){
                Write-Verbose "Job $($Job.Id) completed late"
                $Data = Receive-Job $Job
                $return+=$Data
            }#end if($job.hasmoredata
        }#end foreach($Job

        Write-Verbose "Cleaning up threads"
        Get-Job | Remove-Job -Force | Out-Null

        #All this data needs to go somewhere....
        return $return
    }
}#end function ThreadedScript
