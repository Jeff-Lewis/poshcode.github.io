$Parser = [System.Management.Automation.PsParser]
$script:lastMemory = Get-Process -id $PID
$global:LastTweets = new-object System.Collections.Generic.List[PSObject]
$global:PerformanceHistory = @{}

if(!(Test-Path Variable:PrePerformanceTrackingPrompt -EA 0)){
   $Global:PrePerformanceTrackingPrompt = ${Function:Prompt}
}


function Global:Prompt {
   $currMemory = Get-Process -id $PID
   $lastCommand = Get-History -Count 1
   $global:PerformanceHistory[$lastCommand.Id] = Get-Performance $lastCommand @{
                                                   PrivateMemoryDiff = $currMemory.PrivateMemorySize64 - $lastMemory.PrivateMemorySize64
                                                   VirtualMemoryDiff = $currMemory.VirtualMemorySize64 - $lastMemory.VirtualMemorySize64
                                                   PrivateMemorySize64 = $currMemory.PrivateMemorySize64
                                                   VirtualMemorySize64 = $currMemory.VirtualMemorySize64
                                                 }
   if($PerformanceHistory.Count -gt $MaximumHistoryCount) {
      $null = $PerformanceHistory.Remove( ($lastCommand.Id - $MaximumHistoryCount) )
   }
   $lastMemory = $currMemory
   return &$PrePerformanceTrackingPrompt @args 
}

function Get-PerformanceHistory {
param( [int]$count=1, [int64[]]$id=@((Get-History -count 1| Select Id).Id), [switch]$Memory )

# if there's only one id, then the count counts, otherwise we just use the ids
# ... basically:    { 1..$count | % { $id += $id[-1]-1 }  }
if($id.Count -eq 1) { $id = ($id[0])..($id[0]-($count-1)) } 

$global:PerformanceHistory[$id]

}

function Format-TimeSpan($ts) {
   if($ts.Minutes) {
      if($ts.Hours) {
         if($ts.Days) {
            return "{0:##}d {1:00}:{2:00}:{3:00}.{4:00000}" -f $ts.Days, $ts.Hours, $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
         }
         return "{0:##}:{1:00}:{2:00}.{3:00000}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
      }
      return "{0:##}:{1:00}.{2:00000}" -f $ts.Minutes, $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
   }
   return "{0:#0}.{1:00000}s" -f $ts.Seconds, [int](100000 * ($ts.TotalSeconds - [Math]::Floor($ts.TotalSeconds)))
}

#requires -version 2.0
## Get-Performance.ps1
##############################################################################################################
## Returns time/performance information about history objects
## History:
## v2.5 - added "average" calculation if the first thing in your command line is a range: 1..x
## v2   - added measuring the scripts involved in the command, (uses Tokenizer)
##      - adds a ton of parsing to make the output pretty
##############################################################################################################
function Get-Performance {
param(
   [Microsoft.PowerShell.Commands.HistoryInfo[]]$History = $(Get-History -count 1),
   [hashtable]$Property = @{}
)
ForEach($cmd in $History) {
   $msr = $null
   # default formatting values
   $avg = 7; $len = 8; $count = 1

   $tok = $Parser::Tokenize( $cmd.CommandLine, [ref]$null )
   if( ($tok[0].Type -eq "Number") -and 
       ($tok[0].Content -le 1) -and 
       ($tok[2].Type -eq "Number") -and 
       ($tok[1].Content -eq "..") )
   {
      $count = ([int]$tok[2].Content) - ([int]$tok[0].Content) + 1
   }
   
   $com = @( $tok | where {$_.Type -eq "Command"} | 
                     foreach { 
                        $Local:ErrorActionPreference = "SilentlyContinue"
                        get-command $_.Content 
                        $Local:ErrorActionPreference = $Script:ErrorActionPreference
                     } | 
                     where { $_.CommandType -eq "ExternalScript" } |
                     foreach { $_.Path } )
                     
   # If we actually got a script, measure it out
   if($com.Count -gt 0){
      $msr = Get-Content -path $com | Measure-Object -Line -Word -Char
   } else {
      $msr = Measure-Object -in $cmd.CommandLine -Line -Word -Char
   }

   New-Object PSObject -Property (@{
         Id        = $cmd.Id
         StartTime = $cmd.StartExecutionTime
         EndTime   = $cmd.EndExecutionTime
         Duration  = Format-TimeSpan ($cmd.EndExecutionTime - $cmd.StartExecutionTime)
         Average   = Format-TimeSpan ([TimeSpan]::FromTicks( (($cmd.EndExecutionTime - $cmd.StartExecutionTime).Ticks / $count) ))
         Lines     = $msr.Lines
         Words     = $msr.Words
         Chars     = $msr.Characters
         Type      = $(if($com.Count -gt 0){"Script"}else{"Command"})
         Commmand  = $cmd.CommandLine
   } + $Property)
} # | 
}

Export-ModuleMember Get-PerformanceHistory

