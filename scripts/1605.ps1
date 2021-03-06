###########################################################################
#
# NAME: Get-Lotterynumbers.ps1
#
# AUTHOR: Jan Egil Ring
# EMAIL: jer@powershell.no
#
# COMMENT: Generates lottery numbers based on user input.
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 24.01.2010 - Initial release
#
###########################################################################

$maximumnumber = Read-Host "How many numbers are available in the lottery?"
$numbercount = Read-Host "How many numbers are drawn?"
$numbers = @()
do {
$number = Get-Random -Minimum 1 -Maximum $maximumnumber
if ($numbers -notcontains $number)
{
$numbers += $number
}
}
until ($numbers.count -eq $numbercount)
$numbers | Sort-Object
