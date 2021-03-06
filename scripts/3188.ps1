# To use
# Save script as LISTPARAMETERS.PS1
# 
# To get the parameters from a Powershell cmdlet just execute
# 
# ./LISTPARAMETERS.PS1 -helpdata (GET-HELP GET-CHILDITEM)
#
# To list in a clean column, all of the parameters for GET-CHILDITEM
#
# ./LISTPARAMETERS.PS1 -helpdata (GET-HELP SET-QADUSER)
#
# To list in a clean column, all of the parameters for SET-QADUSER
#
# I find it handy for Cmdlets that have so many available parameters, it's hard to tell where to start
#
param($HelpData)

($HelpData).Syntax | SELECT-OBJECT –ExpandProperty SyntaxItem | SELECT-OBJECT –ExpandProperty parameter | SELECT-OBJECT name


