function Trace-Message {
    [CmdletBinding(DefaultParameterSetName="Precalculated")]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Precalculated",Position=0)]
        [PSObject]$Message,

        [Parameter(Mandatory=$true,ParameterSetName="DeferredTemplated",Position=0)]
        [ScriptBlock]$DeferredTemplate,

        [switch]$AsWarning,

        [switch]$ResetTimer,

        [switch]$KillTimer,

        [Diagnostics.Stopwatch]$Stopwatch
    )
    begin {
        # if($DebugPreference -gt 0) { 
        #     $PSBoundString = $PSBoundParameters.GetEnumerator().foreach{"" + $_.Key + ":" + $_.Value} -join ', '
        #     Write-Debug "Enter Trace-Message: $PSBoundString"
        # }
        if($Stopwatch) {
            $Script:TraceTimer = $Stopwatch    
            $Script:TraceTimer.Start()
        }
        if(-not $Script:TraceTimer) {
            $Script:TraceTimer = New-Object System.Diagnostics.Stopwatch
            $Script:TraceTimer.Start()
        }

        if($ResetTimer)
        {
            $Script:TraceTimer.Restart()
        }

        # Note this requires a host with RawUi
        $w = $Host.UI.RawUi.BufferSize.Width
    }

    process {
        # if($DebugPreference -gt 0) { 
        #     $PSBoundString = $PSBoundParameters.GetEnumerator().foreach{"" + $_.Key + ":" + $_.Value} -join ', '
        #     Write-Debug "Process Trace-Message: $PSBoundString"
        # }
        if(!$AsWarning -and $VerbosePreference -eq "SilentlyContinue") { return }

        [string]$Message = if($DeferredTemplate) { 
                             ($DeferredTemplate.InvokeReturnAsIs(@()) | Out-String -Stream) -join "`n"
                           } else { "$Message" }
       
        $Message = $Message.Trim()
        
        $Tail = if($MyInvocation.ScriptName) {
                    $Name = Split-Path $MyInvocation.ScriptName -Leaf
                    $Tail = "${Name}:" + "$($MyInvocation.ScriptLineNumber)".PadRight(4)
                } else { "" }
        
        $Tail += $(  if($TraceTimer.Elapsed.TotalHours -ge 1.0) {
                        "{0:h\:mm\:ss\.ffff}" -f $TraceTimer.Elapsed
                    }
                    elseif($TraceTimer.Elapsed.TotaMinutes -ge 1.0) {
                        "{0:mm\m\ ss\.ffff\s}" -f $TraceTimer.Elapsed
                    }                    
                    else{
                        "{0:ss\.ffff\s}" -f $TraceTimer.Elapsed
                    }).PadLeft(12)

        
        # "WARNING:  ".Length = 10
        $Length = ($Message.Length + 10 + $Tail.Length)
        if($Length -gt $w -and $w -gt (25 + $Tail.Length)) {
            [string[]]$words = -split $message
            $short = 10 # "VERBOSE:  ".Length
            $count = 0  # Word count so far
            $lines = 0
            do {
                do {
                    $short += 1 + $words[$count++].Length
                } while (($words.Count -gt $count) -and ($short + $words[$count].Length) -lt $w)
                $Lines++
                if(($Message.Length + $Tail.Length) -gt ($w * $lines)) {
                    $short = 0
                }
            } while($short -eq 0)
            $PaddedLength = $Message.Length + ($w - $short) - $Tail.Length
        } else { 
            $PaddedLength = $w - 10 - $Tail.Length
        }

        $Message = "$Message ".PadRight($PaddedLength, '&#8331;') + $Tail

        if($AsWarning) {
            Write-Warning $Message
        } else {
            Write-Verbose $Message
        }
    }

    end {
        # if($DebugPreference -gt 0) { 
        #     $PSBoundString = $PSBoundParameters.GetEnumerator().foreach{"" + $_.Key + ":" + $_.Value} -join ', '
        #     Write-Debug "End Trace-Message: $PSBoundString"
        # }
        if($KillTimer) {
            $Script:TraceTimer.Stop()
            $Script:TraceTimer = $null
        }
    }
}
