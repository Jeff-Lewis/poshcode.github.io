#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
#
# Script Name: Remove-Games.ps1
#       Title: Remove Games
#     Version: 1.0
#      Author: John W. Cannon <johnwcannon at_gmail_dot_com>
#        Date: September 20, 2011
#
# Description: This tool removes the built-in games
#              from Windows XP (tested on SP3)
#
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\


#Obtain processes and kill any running games
$a = Get-Process #Get a list of running processes

#Kill Freecell
If ($a | Where-Object {$_.ProcessName -eq "freecell"}){
	Stop-Process -name freecell -Force
	}
#Kill Zone.com client
If ($a | Where-Object {$_.ProcessName -eq "zClientm"}){
	Stop-Process -name zClientm -Force
	}
#Kill Hearts
If ($a | Where-Object {$_.ProcessName -eq "mshearts"}){	
	Stop-Process -name mshearts -Force
	}
#Kill Internet Backgammon
If ($a | Where-Object {$_.ProcessName -eq "bckgzm"}){
	Stop-Process -name bckgzm -Force
	}
#Kill Internet Checkers
If ($a | Where-Object {$_.ProcessName -eq "chkrzm"}){
	Stop-Process -name chkrzm -Force
	}
#Kill Internet Hearts
If ($a | Where-Object {$_.ProcessName -eq "hrtzzm"}){
	Stop-Process -name hrtzzm -Force
	}
#Kill Internet Reversi
If ($a | Where-Object {$_.ProcessName -eq "rvsezm"}){
	Stop-Process -name rvsezm -Force
	}
#Kill Internet Spades
If ($a | Where-Object {$_.ProcessName -eq "shvlzm"}){
	Stop-Process -name shvlzm -Force
	}
#Kill Minesweeper
If ($a | Where-Object {$_.ProcessName -eq "winmine"}){
	Stop-Process -name winmine -Force
	}
#Kill Pinball
If ($a | Where-Object {$_.ProcessName -eq "pinball"}){
	Stop-Process -name pinball -Force
	}
#Kill Solitaire
If ($a | Where-Object {$_.ProcessName -eq "sol"}){
	Stop-Process -name sol -Force
	}
#Kill Spider Solitaire
If ($a | Where-Object {$_.ProcessName -eq "spider"}){
	Stop-Process -name spider -Force
	}
	
#Create the file needed for the sysocmgr.exe program
$file = New-Item -ItemType file "c:\Windows\inf\ocm.txt" -Force
Add-Content	$file "[Components]"
Add-Content	$file "freecell=off"
Add-Content	$file "hearts=off"
Add-Content	$file "minesweeper=off"
Add-Content	$file "msnexplr=off"
Add-Content	$file "pinball=off"
Add-Content	$file "solitaire=off"
Add-Content	$file "spider=off"
Add-Content	$file "zonegames=off"

#Run the sysocmgr.exe utility with the file we just created
#More information on sysocmgr.exe here: http://support.microsoft.com/kb/222444
Invoke-Expression "sysocmgr.exe /i:c:\windows\inf\sysoc.inf /u:c:\windows\inf\ocm.txt /q"

#Remove the Games folder from the All Users profile because it isn't deleted by sysocmgr
Remove-Item 'c:\Documents and Settings\All Users\Start Menu\Programs\Games' -Force -WarningAction SilentlyContinue -Recurse

