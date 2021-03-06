#requires -version 2.0


function Scan-EventLogs
{
    <#
        .SYNOPSIS
        Scan event logs on specified computer(s) and return a sorted collection events to review.
        
        .Description
        Uses PowerShell Remoting with Invoke-Command and Get-EventLog to fetch a list of enabled event logs from one or more computers and sort output.
        
        .PARAMETER ComputerName
        Specifies one or more computers to scan and report event logs info from. The default is the local computer.
        
        .PARAMETER Sort
        Specifies a property to sort by. The default is MachineName, but 
        any property of EventLogConfiguration class could be used, including "IsClassicLog" and "FileSize".
        
        .PARAMETER Descending
        Indicates whether to be descending or ascending sort order. Default is descending = true.
        
        .PARAMETER Exclude
        An array of psobjects created by the New-EventId cmdlet which will be excluded from the output.
        
        .PARAMETER Credential
        The network credential to use when connecting to a remote compiuter.

        .EXAMPLE
        PS > $Exclusions =   (New-EventId -Source "W32Time" -EventId 29), (New-EventId -Source "Netlogon" -EventId 5719)
        PS > Get-EnabledEvtLogs -CN "ANY-SERVER", "Localhost" -Sort "Source" -Descending $true
    #>
    
    # Parameters
    Param
    ( 
        [parameter(Mandatory=$false)]
        [alias("CN")]
        [String[]] $ComputerName = $ENV:COMPUTERNAME,

        [parameter(Mandatory=$false)]
        [String] $Sort = "MachineName",
        
        [parameter(Mandatory=$false)]
        [Boolean] $Descending = $true,
        
        [parameter(Mandatory=$false)]
        [psobject[]] $Exclude,
        
        [parameter(Mandatory=$false)]
        [PSobject] $Credential
    )
    
    Process
    { 
        # Help enforcing coding rules...
        Set-StrictMode -Version Latest
        
        # The logs we want to scan...
        $LogNames = "Security", "System";
        $EntryTypes = "FailureAudit", "Error";
        $list = $null;

        foreach($cn in $ComputerName)
        {        
            foreach($logName in $LogNames)
            {
                # Determine dates for last month
                $LastMonth = (get-date).AddMonths(-1);
                $LastMonthFirst = get-date -year $LastMonth.Year -month $LastMonth.Month -day 1
                $ThisMonthFirst = get-date -year (get-date).Year -month (get-date).Month -day 1
            
            
                $EventLogArgs = @{
                                ComputerName = $cn
                                LogName = $logName
                                After = $LastMonthFirst
                                Before = $ThisMonthFirst
                                EntryType = $EntryTypes
                                AsBaseObject = $true
                }
                                            
                # Build args struct
                $remoteScript = { param($elArgs) & get-eventlog @elArgs }
                
                # get events...
                $events = Invoke-Command -ScriptBlock $remoteScript -ComputerName $cn -Credential $Credential -ArgumentList $EventLogArgs;
                
                # Build the filter algorithm for the where object...
                $filterScript = 
                {
                    # Loop through the exclusions...
                    $bInc = $true; 
                    foreach($ex in $Exclude) 
                    { 
                        # first check to make sure the incoming object has a Source property..
                        $hasSource = get-member -name "Source" -InputObject $_
                        
                        # if not has Source 
                        if($hasSource -eq $null)
                        {
                            $bInc = $false;
                        }
                        # in our exlucde list, then not include.
                        else 
                        {
                            if($_.Source -eq $ex.Source -and $_.EventID -eq $ex.EventID)
                            {
                                $bInc = $false; 
                            }
                        } 
                    } 
                    
                    $bInc; 
                };
                
                # Do the actual filtering...
                [psobject[]]$filtered = $null;
                foreach($evt in $events)
                {
                    $filtered += where -FilterScript $filterScript -InputObject $evt;
                }
                
                # prepare final list...
                $list += ($filtered | select MachineName, EntryType, TimeGenerated, Source, EventId, Message, UserName);
            }
        }
        
        
        # Sort the collection according to callers wishes and format for output...
        $list | sort -property @{Expression=$Sort;Descending=$Descending}
    }
}

function New-EventId
{
    Param
    (
        [ValidateNotNullOrEmpty()] 
        [string] $Source,
        
        [ValidateNotNullOrEmpty()] 
        [int] $EventId
    )
    
    process
    {
        $EventIdItem = new-object psobject;
        $EventIdItem | add-member -membertype noteproperty -name Source -value $Source;
        $EventIdItem | add-member -membertype noteproperty -Name EventID -value $EventId;
        $EventIdItem; 
    }
}
