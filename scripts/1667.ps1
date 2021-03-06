 # ============================================================================================== 
 # 
 #
 # NAME: PinnedApplications.psm1
 # 
 # AUTHOR: Jan Egil Ring, Crayon
 
 # DATE  : 26.02.2010 
 # 
 # COMMENT: Module with the ability to pin and unpin programs from the taskbar and the Start-menu in Windows 7 and Windows Server 2008 R2
 #
 # This module are based on the Add-PinnedApplication script created by Ragnar Harper and Kristian Svantorp:
 # http://blogs.technet.com/kristian/archive/2009/04/24/nytt-script-pin-to-taskbar.aspx
 # http://blog.crayon.no/blogs/ragnar/archive/2009/04/17/pin-applications-to-windows-7-taskbar.aspx
 #
 # For more information, see the following blog post:
 # http://blog.crayon.no/blogs/janegil/archive/2010/02/26/pin-and-unpin-applications-from-the-taskbar-and-start-menu-using-windows-powershell.aspx
 #
 # Locale supported: Norwegian, English
 # 
 # 
 # ============================================================================================== 
 
 function Set-PinnedApplication
  {
  <# 
.SYNOPSIS 
This function are used to pin and unpin programs from the taskbar and Start-menu in Windows 7 and Windows Server 2008 R2
.DESCRIPTION 
The function have to parameteres which are mandatory:
Action: PinToTaskbar, PinToStartMenu, UnPinFromTaskbar, UnPinFromStartMenu
FilePath: The path to the program to perform the action on
.EXAMPLE
Set-PinnedApplication -Action PinToTaskbar -FilePath "C:\WINDOWS\system32\notepad.exe"
.EXAMPLE
Set-PinnedApplication -Action UnPinFromTaskbar -FilePath "C:\WINDOWS\system32\notepad.exe"
.EXAMPLE
Set-PinnedApplication -Action PinToStartMenu -FilePath "C:\WINDOWS\system32\notepad.exe"
.EXAMPLE
Set-PinnedApplication -Action UnPinFromStartMenu -FilePath "C:\WINDOWS\system32\notepad.exe"
#> 
   [CmdletBinding()]
   param(
      [Parameter(Mandatory=$true)][string]$Action, [string]$FilePath
   )
   
  
 switch ($Action) {
 
 "PinToTaskbar" {
  $PinVerbTask = @{}
 $PinverbTask['En-US'] ="Pin to Taskbar" 
 $PinverbTask['Nb-No'] ="Fest til oppgavelinjen"

 
    ##get culture
   $culture = $Host.CurrentUICulture.Name
   
  #Check to see if path actually exists
       if(-not (test-path $FilePath)) { write-warning "`nPath does not exist.`n $FilePath `nExiting... `n";  return  }
          
       #this should only be done if a full path is given    
       $path= split-path $FilePath
       #Create shell envir
       $shell=new-object -com "Shell.Application" 
       $folder=$shell.Namespace($path)   
       $item = $folder.Parsename((split-path $FilePath -leaf))
      
       $verbs=$item.Verbs()    
	   
	   foreach($v in $verbs){if($v.Name.Replace("&","") -match $PinVerbTask[$culture]){$v.DoIt()}} 

 }
 "PinToStartMenu" {
  $PinVerbStart = @{}
  $PinverbStart['En-US'] ="Pin to Start Menu" 
  $PinverbStart['Nb-No'] ="Fest til Start-menyen" 
  
     ##get culture
   $culture = $Host.CurrentUICulture.Name
 
  #Check to see if path actually exists
       if(-not (test-path $FilePath)) { write-warning "`nPath does not exist.`n $FilePath `nExiting... `n";  return  }
          
       #this should only be done if a full path is given    
       $path= split-path $FilePath
       #Create shell envir
       $shell=new-object -com "Shell.Application" 
       $folder=$shell.Namespace($path)   
       $item = $folder.Parsename((split-path $FilePath -leaf))
      
       $verbs=$item.Verbs()    
	   
	   foreach($v in $verbs){if($v.Name.Replace("&","") -match $PinVerbStart[$culture]){$v.DoIt()}}
 
 }
 "UnPinFromTaskbar" {
   $UnPinVerbTask = @{}
 $UnPinverbTask['En-US'] ="Unpin from Taskbar" 
 $UnPinverbTask['Nb-No'] ="Løsne programmet fra oppgavelinjen"

   ##get culture
   $culture = $Host.CurrentUICulture.Name

#Check to see if path actually exists
              if(-not (test-path $FilePath)) { write-warning "`nPath does not exist.`n $FilePath `nExiting... `n";  return  }
          
       #this should only be done if a full path is given    
       $path= split-path $FilePath
       #Create shell envir
       $shell=new-object -com "Shell.Application" 
       $folder=$shell.Namespace($path)   
       $item = $folder.Parsename((split-path $FilePath -leaf))
      
       $verbs=$item.Verbs()    
 
 foreach($v in $verbs){if($v.Name.Replace("&","") -match $UnPinVerbTask[$culture]){$v.DoIt()}}
 }
 "UnPinFromStartMenu" {
   $UnPinVerbStart = @{}
  $UnPinverbStart['En-US'] ="Unpin from Start Menu" 
  $UnPinverbStart['Nb-No'] ="Løsne fra Start-menyen"
 
  
     ##get culture
   $culture = $Host.CurrentUICulture.Name

#Check to see if path actually exists
              if(-not (test-path $FilePath)) { write-warning "`nPath does not exist.`n $FilePath `nExiting... `n";  return  }
          
       #this should only be done if a full path is given    
       $path= split-path $FilePath
       #Create shell envir
       $shell=new-object -com "Shell.Application" 
       $folder=$shell.Namespace($path)   
       $item = $folder.Parsename((split-path $FilePath -leaf))
      
       $verbs=$item.Verbs()    
 foreach($v in $verbs){if($v.Name.Replace("&","") -match $UnPinVerbStart[$culture]){$v.DoIt()}}
 }
 default {Write-Warning "Invalid action specified. Valid actions are: PinToTaskbar, PinToStartMenu, UnPinFromTaskbar, UnPinFromStartMenu"}
 }
 }
