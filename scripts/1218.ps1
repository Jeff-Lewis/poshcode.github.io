function Start-BootsTimer {
#.Syntax
#  Creates a stay-on-top countdown timer
#.Description
#  A WPF borderless count-down timer, with audio/voice alarms and visual countdown + colored progress indication
#.Parameter EndMessage
#  The message to be spoken by a voice when the time is up...
#.Parameter StartMessage
#  A message to be spoken at start up (just to let you know, audibly, what's up).

#.Parameter Minutes
#  Some minutes to add to the timer
#.Parameter Seconds
#  Some seconds to add to the timer
#.Parameter Hours
#  Some hours to add to the timer

#.Parameter SoundFile
#  A .wav file to play as the alarm
#.Parameter FontSize
#  The size of the timer text
#.Parameter SingleAlarm
#  Only sound the alarm once

#.Example
#  Start-BootsTimer  180 "The three minute egg is ready!"
#
#  Starts a three minute timer with the specified voice alert at the end
#
#.Example
#  Start-BootsTimer  -End "The three minute egg is ready!" -Minute 3
#
#  Starts a three minute timer with the specified voice alert at the end
#
#.Example
#  Start-BootsTimer  "Your turn is over!" -Minutes 10 -Single -FontSize 18
#
#  Starts a 10 minute timer that only plays the alert once at the end, and has a small font, which would fit over the task bar or a window title bar...
[CmdletBinding(DefaultParameterSetName="Times")]
PARAM( 
   [Parameter(Position=2,ParameterSetName="Times",Mandatory=$false)]
   [Parameter(Position=1,ParameterSetName="Reasons", Mandatory=$true)]
   [string]$EndMessage
,  
   [Parameter(Position=2,ParameterSetName="Reasons", Mandatory=$false)]
   [string]$StartMessage
,  
   [Parameter(Position=3,ParameterSetName="Reasons", Mandatory=$false)]
   [int]$minutes   = 0
,
   [Parameter(Position=4,ParameterSetName="Reasons", Mandatory=$false)]
   [Parameter(Position=1,ParameterSetName="Times", Mandatory=$true)]
   [int]$seconds   = 0
,
   [Parameter()]
   [int]$hours     = 0
,
   [Parameter()]
   $SoundFile = "$env:SystemRoot\Media\notify.wav"
,
   [Parameter()]
   $FontSize = 125
, 
   [Parameter()]
   [Switch]$SingleAlarm
)

# Default to 10 seconds ... without adding 5 seconds when people specify minutes
if(($seconds + $Minutes + $hours) -eq 0) { $seconds = 10 }

$start = [DateTime]::Now

## We have to store all this stuff, because the powerboots window lasts longer than the script
$TimerStuff = @{}
$TimerStuff["seconds"] = [Math]::Abs($seconds) + [Math]::Abs([int]($minutes*60)) + [Math]::Abs([int]($hours*60*60))
$TimerStuff["TimerEnd"] = $start.AddSeconds( $TimerStuff["seconds"] )
$TimerStuff["SingleAlarm"] = $SingleAlarm

## Take care of as much overhead as we can before we need it...
if(Test-Path $soundFile) {
   $TimerStuff["Sound"] = new-Object System.Media.SoundPlayer
   $TimerStuff["Sound"].SoundLocation=$SoundFile
}
if($EndMessage -or $StartMessage) {
   $TimerStuff["Voice"] = new-object -com SAPI.SpVoice
}

## Create and store a scriptblock to figure out the remaining time and format it
$TimerStuff["NowFunction"] = { 
   $diff = $BootsTimer.Tag["TimerEnd"] - [DateTime]::Now;
   $diff.TotalSeconds
   if($diff.Ticks -ge 0) {
      ([DateTime]$diff.Ticks).ToString(" HH:mm.ss")
   } else {
      ([DateTime][Math]::Abs($diff.Ticks)).ToString("-HH:mm.ss")
   }
}

## Create and store a scriptblock to sound the alarm
$TimerStuff["AlarmFunction"] = {
   if($BootsTimer.Tag["Sound"]) {
      $BootsTimer.Tag["Sound"].Play()
   } else {
      [System.Media.SystemSounds]::Exclamation.Play()
   }
   if($BootsTimer.Tag["EndMessage"]) {
      $null = $BootsTimer.Tag["Voice"].Speak( $BootsTimer.Tag["EndMessage"], 1 )
   }
}

## Store the "EndMessage" message
if($EndMessage) {
   $TimerStuff["EndMessage"] = $EndMessage
}
## If they provided a second status message, read it out loud
if($StartMessage) {
   $null = $TimerStuff["Voice"].Speak( $StartMessage, 1 )
}

$TimerStuff["FontSize"] = $FontSize

## Make the window ...
$Global:BootsTimer = boots -WindowStyle None -AllowsTransparency -Topmost { 
   TextBlock "" -FontSize $BootsParameters.FontSize -FontFamily Impact -margin 20   `
            -BitmapEffect $(OuterGlowBitmapEffect -GlowColor White -GlowSize 15)    `
            -Foreground $(LinearGradientBrush -Start "1,1" -End "0,1" {
                           GradientStop -Color Black -Offset 0.0
                           GradientStop -Color Black -Offset 0.95
                           GradientStop -Color Red -Offset 1.0
                           GradientStop -Color Red -Offset 1.0
                        }) # -TextDecorations ([System.Windows.TextDecorations]::Underline)

} -On_MouseDown { 
   if($_.ChangedButton -eq "Left") { $this.DragMove()  }
} -On_Close {
   $this.Tag["Timer"].Stop()
   Remove-BootsWindow $this
} -Async -Passthru -Background Transparent -ShowInTaskbar:$False -Tag $TimerStuff 

## Now we need to call that scriptblock on a timer. That's easy, but it
## must be done on the window's thread, so we use Invoke-BootsWindow.
## Notice the first argument is the window we want to run the script in
Invoke-BootsWindow $Global:BootsTimer {
   ## We'll create a timer
   $Global:BootsTimer.Tag["Timer"] = new-object System.Windows.Threading.DispatcherTimer
   $BootsTimer.Tag["Timer"].Interval = [TimeSpan]"0:0:0.05"
   ## And will invoke the $updateBlock
   $BootsTimer.Tag["Timer"].Add_Tick( { 
      trap { 
         write-host "Error: $_" -fore Red 
         write-host $($_.Exception.StackTrace | Out-String) -fore Red 
      }
      $remain, $BootsTimer.Content.Text = & $BootsTimer.Tag["NowFunction"] 
      $remain = $remain / $BootsTimer.Tag["seconds"]
      ## Move the gradient a little bit each time.
      $BootsTimer.Content.Foreground.GradientStops[2].Offset = [Math]::Max(0.0, $remain)
      $BootsTimer.Content.Foreground.GradientStops[1].Offset = [Math]::Max(0.0, $remain - 0.05)
      ## When we get to the end ... make a few changes
      if($remain -le 0) {
         ## The first time we hit the end, we want to add a mouse click handler...
         if($this.Interval.Seconds -eq 0) {
            ## Which will now only fire every few seconds
            ## So it's easier to close the window ;)
            $this.Interval = [TimeSpan]"0:0:2"
            ## If you click on the finished window, it just goes away
            $BootsTimer.Add_MouseDown( { $BootsTimer.Close() } ) 
            ## But if they chose -SingleAlarm, they don't neeto bother
            if($BootsTimer.Tag["SingleAlarm"]) { $BootsTimer.Close() }
         }
         & $BootsTimer.Tag["AlarmFunction"]
      }
   } )
   ## Now start the timer running
   $BootsTimer.Tag["Timer"].Start()
}

}
