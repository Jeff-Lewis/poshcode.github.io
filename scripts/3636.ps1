A syntax error on your $Status array definition - you forgot the braces around the elements;

[string[]]$status=("Cooking","Burning")

cheers, yeatsie


## Start-Timer.ps1
## A kitchen timer script with visible countdown and customizable audio alert and messages
####################################################################################################
param( $seconds=0,  $reason="The Timer",  $SoundFile="$env:SystemRoot\Media\notify.wav",
@@      $minutes=0,  $hours=0,  $timeout=0,  [switch]$novoice, [string[]]$status="Cooking","Burning"
)

$start = [DateTime]::Now
write-progress -activity $reason -status "Running"

$seconds = [Math]::Abs($seconds) + [Math]::Abs($minutes*60) + [Math]::Abs($hours*60*60)
$end = $start.AddSeconds( $seconds )

## Take care of as much overhead as we can BEFORE we start counting
## So the sounds can play as cloase to the end as possible
$Voice = new-object -com SAPI.SpVoice
$Sound = new-Object System.Media.SoundPlayer

if(Test-Path $soundFile) {
   $Sound.SoundLocation=$SoundFile
} else {
   $soundFile = $Null
}

## The actual timing loop ... 
do {
   $remain  = ($end - [DateTime]::Now).TotalSeconds
   $percent = [Math]::Min(100, ((($seconds - $remain)/$seconds) * 100))
   $sec     = [Math]::Max(000, $remain)

   write-progress -activity $reason -status $status[0] -percent $percent -seconds $sec
   start-sleep -milli 100
} while( $remain -gt 0 )

## And a loop for beeping
$Host.UI.RawUI.FlushInputBuffer()
do {
   if($SoundFile) {
      $Sound.PlaySync()
   } else {
      [System.Media.SystemSounds]::Exclamation.Play()
   }
   if(!$novoice -and !$Host.UI.RawUI.KeyAvailable){
     $null = $Voice.Speak( "$reason is $($status[1])!!", 0 )
   }

   write-progress -activity $reason -status $status[1] -percent ([Math]::Min(100,((($seconds - $remain)/$seconds) * 100))) -seconds ([Math]::Max(0,$remain))
   $remain = ($end - [DateTime]::Now).TotalSeconds
} while( !$Host.UI.RawUI.KeyAvailable -and ($timeout -eq 0 -or $remain -gt -$timeout))

if($SoundFile) {
   $Sound.Stop() 
}
