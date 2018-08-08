<#
.SYNOPSIS
Backup-ToUSB.ps1 (Version 2.2, 9 Jan 2012)
.DESCRIPTION 
This script will backup recently changed *.ps1,*.psm1,*.psd1 files from any
selected folder (default is $pwd) to any number of inserted USB devices, on
which an archive folder 'PSarchive' will be created if it does not already 
exist. 
As a USB hard disk is a Type 3 device (similar to the system disk), use the
-Unit D switch (drive letter 'D' for example) to distinguish such a unit and
add it to the list of selected devices. 
.EXAMPLE
Invoke-Expression ".\Backup-ToUsb.ps1 -Unit D $args"
Add this line in 'function Backup' in $profile and it will add the USB Hard 
Disk 'D' as the standard backup device. 
.EXAMPLE
.\Backup-ToUSB.ps1 -type ps1 -v
Select *.ps1 files to be archived. 'Verbose' will display the name of each 
file processed. Using the '-Debug' switch shows the time difference that has
tagged any file for archive. 
.NOTES
The author may be contacted via www.SeaStarDevelopment.Bravehost.com  
#>

 
param ([String]$types = 'ps1',
       [String]$folder = $pwd,
       [String]$unit  = $null,
       [Switch]$debug,
       [Switch]$verbose)
if ($verbose) {
   $verbosePreference = 'Continue'
}
if ($debug) {
   $debugPreference = 'Continue'
}
$drive = '-<BLANK>-'
if ($types -notmatch '^ps1|psd1|psm1|ps\*$') {              #Adjust to suit.
   Write-Warning "Invalid filetype ($types): ps1, psm1, psd1 only."
   exit 1
} 
if (!(Test-path $folder -pathType Container )) { 
   [System.Media.SystemSounds]::Hand.Play() 
   Write-Warning "$folder is not a directory - resubmit." 
   exit 3 
} 
$filter = 'DriveType = 2'               
if ($unit -match '^[d-z]$') {      #Allow any single letter drive unit here. 
   $filter = "DriveType = 2 OR (DriveType = 3 AND DeviceID = '" + "$unit" + ":')"
}
function copyFile ([string]$value) {
   Copy-Item -Path $value -Destination $newFolder -Force
   Write-Verbose "--> Archiving file: $value" 
   $SCRIPT:files++  
}
Get-WMIObject Win32_LogicalDisk -filter $filter | 
   Select-Object VolumeName, DriveType, FreeSpace, DeviceID | 
      Where-Object {$_.VolumeName -ne $null} |
foreach {
    $vol   = $_.VolumeName
    $drive = $_.DeviceID + '\'
    $type  = $_.DriveType
    [int]$free  = $_.FreeSpace / 1MB 
    Write-Verbose "Scanning USB devices - Drive = [$drive] Name = $vol, Free = $free Mb"
    if (!(Test-Path $drive)) { 
       Write-Warning "Error on drive $drive - restart." 
       [System.Media.SystemSounds]::Hand.Play() 
       exit 4    
    } 
    [int]$SCRIPT:files = 0                #Reset counter for each new drive. 
    $newFolder = $drive + "PSarchive"               #Check if folder exists. 
    if (!(Test-Path $newFolder)) { 
       New-Item -path ($drive) -name PSarchive -type directory | Out-Null 
    } 
    (Get-ChildItem $folder -filter "*.$types") |  
    foreach {
        $checkFile = Join-Path ($drive + 'PSArchive') $_
        if (Test-path $checkFile) {
           $lwtHdd = $_.LastWriteTime                #HDD time last written.
           $lwtUsb = (Get-Item $checkFile).LastWriteTime
           if ($lwtHdd -gt $lwtUsb) {
              Write-Debug "(HDD) $lwtHdd   (USB) $LwtUsb  $_"
              copyFile $_
           }
        }
        else {                              #New file, so archive it anyway.
           Write-Debug "(HDD) $($_.LastWriteTime)   (USB Archiving new file)   $_"
           copyFile $_
        }                           
    } 
    $print =  "Backup to USB drive [{0}] (Volume = {2}) completed; {1} files copied." -f $drive, $SCRIPT:files, $vol 
    Write-Host "--> $print"
}
if ($drive -eq '-<BLANK>-') { 
    [System.Media.SystemSounds]::Asterisk.Play() 
    Write-Warning "No USB drive detected - Insert a device and resubmit."   
} 

