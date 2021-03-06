#Script Path of the Script
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#This Module is needed to overcome to long paths
Import-Module "$($scriptPath)\AlphaFS.dll"

#List of all folders we want to clean up
$list=@(
"\\server1\folder1",
"\\server2\folder2\folder22"
)

#If true only show output
$only_output=$FALSE

#Warn user if only output is shown
if($only_output){
    Write-Host ""
    Write-Host "Only Output! Nothing is deleted really!" -ForegroundColor Magenta
    Write-Host ""
}

#The File Extension
$extension=".odin"

#The HTML File
$html_file="HOWDO_text.html"

#Logfile for script
$logfile="$($scriptPath)\crypto.log"

#Write date to logfile
"$(Get-date)"|Out-File $logfile

#initialize count
$count=0

#Loop through each folder in list
foreach($folder in $list){

    #Output foldername
    Write-Host "--- $($folder)" -ForegroundColor Yellow

    #Get all files in the folder that match the extension or the html file
    [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFileSystemEntries($folder, '*', [System.IO.SearchOption]::AllDirectories)|Where-Object{$_ -like "*$($extension)" -or $_ -like "*$($html_file)"}|ForEach-Object{
        
        #Output the found file    
        Write-Host "$($_)" -ForegroundColor Yellow
        
        #raise count
        $count+=1

        #Write file to log
        "$($_)"|Out-File $logfile -Append

        #Delete file
        if(!($only_output)){
            [Alphaleonis.Win32.Filesystem.File]::Delete("$($_)", [Alphaleonis.Win32.Filesystem.PathFormat]::FullPath)
        }
    }
}

#Output Count
Write-Host ""
Write-Host ""
Write-Host "$($count) Files found!" -ForegroundColor Yellow
Write-Host "The count is html and crypt files combined" -ForegroundColor Yellow
Write-Host ""
