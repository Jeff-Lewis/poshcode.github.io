#region @3
## Function to do a regex replace of all matches with an expression per match that has local variables
##created automatically for the named groups so that you can use those varibles in your expression
function replace-regexgroup ([regex]$regex, [string]$text ,[scriptblock] $replaceexpression)
{
$regex.Replace($text,{
    $thematch = $args[0]
    $groupnames = $regex.GetGroupNames()
    for ($count = 0; $count -lt ( $thematch.groups.count) ; $count++)
        {        
         set-variable -name $($groupnames[$count]) -visibility private -value $($thematch.groups[$count] ) 
        }    
    if ($replaceexpression -ne $Null) { &$replaceexpression}
    } )
}
$example = @"
<P><a href="wiki://284_636">links to test page 2</a></P>
<P><a href="wiki://109_49">
"@
replace-regexgroup 'wiki://(?<wholething>(?<folder>\d+)_(?<page>\d+))' $example { "$folder/$page/index.html" }
#endregion 
