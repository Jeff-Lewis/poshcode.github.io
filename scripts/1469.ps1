################################################################################
# Get-GprsTime.ps1(V 1008)
#       Check the total connect time of any GPRS devices from a specified date. 
# Use the -Verbose switch for some extra information if desired. A default value
# can be set with the -Monthly switch but can be temporarily overridden with any
# -Start value and deleted by entering an invalid date.  Now uses .NET Parse to 
# use any culture date input. Switches -M and -S cannot be used together.
#       A Balloon prompt will be issued in the Notification area for the 5 days
# before the nominal month end, and a suitable Icon (exclamation.ico) file needs 
# to be available in the $PWD directory for this to work.
# NOTE:  this can effectively be suppressed by using a value higher than the SIM
# card term, ie something like -Account 90 for a 30 day card which will override 
# the default setting. Use -Today to check only today's usage.
# Use 'Set-Alias Get-GprsTime -Account 30' to set value permanently to 30 days.
# Examples:
#    .\Get-GprsTime.ps1 -Monthly 4/8/2009
#    .\Get-GprsTime.ps1 -Start 12/07/2009 -Account 100 -Verbose
#    .\Get-GprsTime.ps1 -m 5/9/2009
#    .\Get-GprsTime.ps1  10/4/2009 -v
#    .\Get-GprsTime.ps1 -v
#    .\Get-GprsTime.ps1 -Today
#    .\Get-GprsTime.ps1
#
# The author can be contacted at www.SeaStarDevelopment.Bravehost.com and the
# 'exclamation.ico' file is included in the Gprs100x.zip download there.
################################################################################
Param ([String] $start,
       [String] $monthly,
       [Int]    $account = 0,     #Start warning prompt 5 days before month end.
       [Switch] $today,
       [Switch] $verbose,
	   [Switch] $debug)
 
Trap [System.Management.Automation.MethodInvocationException] {
    [Int]$line = $error[0].InvocationInfo.ScriptLineNumber
	[System.Media.SystemSounds]::Hand.Play()
    If ($line -eq  165) {
	    Write-Warning "[$name] Current GPRS variable has been deleted."
	    $monthly = ""
	    [Environment]::SetEnvironmentVariable("GPRS",$monthly,"User")
    }
	Else {
		Write-Warning "[$name] Date is missing or invalid $SCRIPT:form"
	}
    Exit 1
}

$name = $myInvocation.MyCommand
$newLine = "[$name] The switches -Start and -Monthly can only be used separately."
If ($debug) {
	$DebugPreference = 'Continue'
}
If ($start -and $monthly) {
    [System.Media.SystemSounds]::Hand.Play()
    Write-Warning "$newLine"
    Exit 1
}
$SCRIPT:form = ""

#In certain cases Culture & UICulture can be different and have been known to
# return conflicting results regarding '-is [DateTime]' queries, etc.
If ($Host.CurrentCulture -eq $Host.CurrentUICulture) {
    $SCRIPT:form = '-Use format mm/dd/year'               
    [Int]$culture = "{0:%d}" -f [DateTime] "6/5/2009"        #Returns local day.
    If ($culture -eq 6) {
		$SCRIPT:form = '-Use format dd/mm/year'
    }
}
$ErrorActionPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$conn = $disc = $default = $print = $null              
$timeNow = [DateTime]::Now 
$total = $timeNow - $timeNow                     #Set initial value to 00:00:00.
$insert = "since"
If ($verbose) {
    $VerbosePreference = 'Continue'
}

Function CreditMsg ($value, $value2) {
    $value = [Math]::Abs($value)
    $prefix = "CURRENT"
    [DateTime] $creditDT = $value2 
	$creditDT = $creditDT.AddDays($value)                #Add the -Account days.
	$thisDay = "{0:M/d/yyyy}" -f [DateTime]::Now               #Force US format.
	#If we use '$number = $creditDT - (Get-Date)' instead of the line below we
	#can sometimes get a value of 1 returned instead 2, hence the  above  lines.
	$number = $creditDT - [DateTime] $thisDay
	[String] $credit = $creditDT   
	$credit = $credit.Replace('00:00:00','')          #Remove any trailing time.
	$credit = "{0:d}" -f [DateTime]$credit
	Switch($number.Days) {
            1            {$prefix = "($value days) will expire tomorrow"; break}
            0            {$prefix = "($value days) will expire today"; break}
            -1           {$prefix = "($value days) expired yesterday"; break}
            {($_ -lt 0)} {$prefix = "($value days) expired on $credit"; break}
            {($_ -le 5)} {$prefix = "($value days) will expire on $credit"}
            Default      {$prefix = "CURRENT"}   #Only come here if over 5 days.
	}
    Return $prefix
}

Function Interval ([String] $value) {
    Switch($value) {
   		{ $_ -match '^00:00:\d+(.*)$' } {$suffix = "seconds"; break}
		{ $_ -match '^00:\d+:\d+(.*)$'} {$suffix = "minutes"; break}
		Default                         {$suffix = "  hours"}
    }
    Return $suffix
}

Function CheckSetting ($value) {
	If ($value) {
		$print = $default.ToShortDateString()        #Correct for local culture.
	}
	Else {
		$print = "(Value not set)"
	}
	Return $print
}
#The Script effectively starts here.............................................
$getGprs = [Environment]::GetEnvironmentVariable("GPRS","User")
#First check for GPRS variable and change from US date format to current locale.
If ([DateTime]::TryParse($getGprs, [Ref]$timeNow)) { #No error as date is valid.
	$default = "{0:d}" -f [datetime]$getGprs 
	$default = [DateTime]::Parse($default)  
	$checkYear = "{0:yyyy}" -f $default
	$checkMonth = "{0:%M}" -f $default
	$dayCount = [DateTime]::DaysInMonth($checkYear,$checkMonth)    #Range 28-31.
	If($account -eq 0) {
		$account = $dayCount
		$summary = "$($dayCount.ToString()) days" 
	}
	Else {
		$summary = "$($account.Tostring()) days"
	}
	$text = CreditMsg $account $getGprs  #Check if within 5 days of expiry date.
	If (($text -ne "CURRENT") -and (Test-Path "$pwd\exclamation.ico") ) {
    	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    	$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 
    	$objNotifyIcon.Icon = "$pwd\exclamation.ico" 
    	$objNotifyIcon.BalloonTipIcon  = "Info" 
    	$objNotifyIcon.BalloonTipTitle = "GPRS online account"
    	$objNotifyIcon.BalloonTipText  = "Credit $text"
    	$objNotifyIcon.Visible = $True 
    	$objNotifyIcon.ShowBalloonTip(10000)
	}
}
Else {
	$summary = "(Days not set)"
	If ((!$today) -and (!$monthly) -and (!$start)) {
		[System.Media.SystemSounds]::Hand.Play()
		Write-Warning("Monthly date is either invalid or not set.")
		Exit 1
	}
}
If ($start) {
    $start = [DateTime]::Parse($start)                 #Trigger TRAP if invalid!
	[DateTime]$limit = $start
    $convert = "{0:D}" -f $limit
	$print = CheckSetting $default
} 

If ($monthly) {
    $start = [DateTime]::Parse($monthly)               #Trigger TRAP if invalid!
	Write-Output "Setting GPRS (monthly) environment variable to: $monthly"
    $gprs = [String]$start.Replace('00:00:00','')
    [Environment]::SetEnvironmentVariable("GPRS",$gprs,"User")
    [DateTime] $limit = $start               #Change to required US date format.
    $convert = "{0:D}" -f $limit
	$print = $limit.ToShortDateString()
	$summary = "(Days undetermined)"                #Will show next time around.
}

If ($today) {                    
    $verBosePreference = 'Continue'                    #Show VERBOSE by default.
    [DateTime] $limit = (Get-Date)
    $convert = "{0:D}" -f $limit
    $limit = $limit.Date         #Override any start date if using -Today input.
    $insert = "for today"
	$print = CheckSetting $default
}
If ((!$today) -and (!$monthly) -and (!$start)) {        
	If ($default) {
    	$monthly = $default
		[DateTime] $limit = $monthly
		$convert = "{0:D}" -f $limit
		$print = CheckSetting $default
	}
}
Write-Verbose "All records $($insert.Replace('for ','')) - $convert"
Write-Verbose "Script activation - User [$($env:UserName)] Computer [$($env:ComputerName)]"
Write-Output ""
Write-Output "Calculating total connect time of all GPRS modem devices..."
                    #We cannot proceed beyond here without a valid $limit value.
Write-Debug "Using - [Search date] $($limit.ToShortDateString()) [Account] $summary [GPRS Monthly] $print"					

$lines = Get-EventLog system | Where-Object {($_.TimeGenerated -ge $limit) -and `
    ($_.EventID -eq 20159 -or $_.EventID -eq 20158)} 
If ($lines) {
    Write-Verbose "A total of $([Math]::Truncate($lines.Count/2)) online sessions extracted from the System Event Log."
}
Else {
    Write-Output "(There are no events indicated in the System Event Log)"
}
$lines | ForEach-Object {
    $source = $_.Source
    If ($_.EventID -eq 20159) {                      #Event 20159 is Disconnect.
       $disc = $_.TimeGenerated
    } 
    Else {                                              #Event 20158 is Connect.
       $conn = $_.TimeGenerated	
    }                  #We are only interested in matching pairs of DISC/CONN...
    If ($disc -ne $null -and $conn -ne $null -and $disc -gt $conn) {
       $diff = $disc - $conn
       $total += $diff
       $convDisc = "{0:G}" -f $disc
       $convConn = "{0:G}" -f $conn
       $period = Interval $diff
       Write-Verbose "Disconnect at $convDisc. Online - $diff $period"
       Write-Verbose "   Connect at $convConn."
    }
}   #End ForEach
If (!$source) {
    $source = '(Undetermined)'
}
Write-Verbose "Using local event source - System Event Log [$source]"
$period = Interval $total
Write-Output "Total online usage $insert $convert is $total $($period.Trim())."
Write-Output ""
