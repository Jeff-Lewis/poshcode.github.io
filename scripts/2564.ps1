#======================================================================================
#         File Name : Array-Randomizer.ps1
#   Original Author : Kenneth C. Mazie (kcmjr at kcmjr.com)
#                   : 
#       Description : Originally written to regenerate the init.txt file for server
#                   :  based Halo 1 PC multiplayer games.  Each run randomizes the 
#                   :  list of maps and then randomizes the list of game types so that
#                   :  a new totally random configuration is used each time the game 
#                   :  is restarted.  You may edit the arrays to add maps or game 
#                   :  types as desired.  These changes only take affect when the game
#                   :  is (re)started.  The script takes into consideration a 32 or 64
#                   :  bit OS and will adjust folders accordingly.
#                   :
#             Notes : Although the script was intended to shuffle Halo maps it may be
#                   :  easily edited and used to randomize any array or group of
#                   :  arrays.
#                   :
#          Warnings : The init.txt file is completely rewritten when this script is
#                   :  run so save a backup first or edit the script to include your
#                   :  custom settings.
#                   : 
#             Legal : Public Domain. Modify and redistribute freely. No rights reserved.
#                   : SCRIPT PROVIDED "AS IS" WITHOUT WARRANTIES OR GUARANTEES OF 
#                   : ANY KIND. USE AT YOUR OWN RISK. NO TECHNICAL SUPPORT PROVIDED.
#                   :
#    Last Update by : Kenneth C. Mazie 
#   Version History : v1.0 - 07-12-10 - Original 
#    Change History : v1.1 - 03-10-11 - Changed name and altered description 
#                   :  
#=======================================================================================

Clear-Host 

#--[ Function to shuffle an array ]-------------------------------
function Shuffle
{
 param([Array] $a)
 $rnd=(new-object System.Random)
 for($i=0;$i -lt $a.Length;$i+=1){
  $newpos=$i + $rnd.Next($a.Length - $i); 
  $tmp=$a[$i]; 
  $a[$i]=$a[$newpos]; 
  $a[$newpos]=$tmp 
 } 
 return $a
}

#--[ Check for, and delete any existing init file ]-----------------
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64"){$path = "C:\Program Files (x86)\Microsoft Games\Halo\init.txt"}
else
{$path = "C:\Program Files\Microsoft Games\Halo\init.txt"}
if(!(Test-Path -Path $path))
  {new-item -Path $path â€“itemtype file}
else
  {remove-Item -Path $path}
  
#--[ Please place any file header items here ]-----------------------  
$arrHeader =        
"sv_name halo",
"sv_public false",
"sv_maxplayers 16",
"sv_mapcycle_timeout 6",
"sv_password halo"
#--[ Place game types here ]--------------------------------
$arrGameType = 
"classic_slayer",
"classic_phantoms",
"classic_elimination",
"classic_juggernaut",
"classic_snipers",
"classic_rockets",
"classic_invasion"
#--[ Place your list of maps here ]--------------------------
$arrMapList = 
"sv_mapcycle_add dangercanyon",
"sv_mapcycle_add gephyrophobia",
"sv_mapcycle_add deathisland",
"sv_mapcycle_add bloodgulch",
"sv_mapcycle_add beavercreek",
"sv_mapcycle_add boardingaction",
"sv_mapcycle_add carousel",
"sv_mapcycle_add chillout",
"sv_mapcycle_add damnation",
"sv_mapcycle_add hangemhigh",
"sv_mapcycle_add icefields",
"sv_mapcycle_add longest",
"sv_mapcycle_add infinity",
"sv_mapcycle_add prisoner",
"sv_mapcycle_add putput",
"sv_mapcycle_add ratrace",
"sv_mapcycle_add sidewinder",
"sv_mapcycle_add timberland",
"sv_mapcycle_add wizard" 

#--[ Randomize the main array ]-------------------------------
shuffle $arrMapList

#--[ Generate the new init file ]-----------------------------
add-content -path $Path -value $arrHeader
foreach ($Map in $arrMapList ) { Add-content -path $Path -value ($Map  + " " + $arrGameType[(get-random -min 0 -max ($arrGameType.length))])}
Add-content -path $Path -value "sv_mapcycle_begin"

#--[ Launch the game ]----------------------------------------
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64"){(new-object -com shell.application).ShellExecute("C:\Program Files (x86)\Microsoft Games\Halo\haloded108.exe")}
else
{(new-object -com shell.application).ShellExecute("C:\Program Files\Microsoft Games\Halo\haloded108.exe")}

