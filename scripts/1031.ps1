#.Synopsis
#  Calculate sums on top of Measure-Object
#.Description
#  Pipe in objects with numerical properties, and get an extra output item
#  with the sum of all the specified properties
#.Parameter Property
#  The names of the properties to total
#.Example
#  wc *.ps1 | total words, lines
#
#  Calculates line, word, and character counts for powershell script files in the current directory, 
#  and THEN adds a total row with totals for words and lines (but not Chars)
#.Example
#  wc *.rb | total
#
#  Calculates line, word, and character counts for rubyscript files in the current directory, 
#  and THEN adds a total row with totals for ALL NUMERIC PROPERTIES ;-)

function measure-total {
PARAM([string[]]$property)
END {
   $input # output the input
   ## "Magically" figure out the numeric properties
   if(!$property) {
      $input.reset()
      $property = $input | gm -type Properties | 
         where { trap{continue} ( new-object "$(@($_.Definition -split " ")[0])" ) -as [double] -ne $null } |
         foreach { $_.Name }
      $input.reset()
   }
   $input.reset()
   # then calculate the sum of the numeric properties
   $sum = $input | measure $property -sum -erroraction 0
   # and make a new object to hold the sums
   $output = new-object PSObject
   $sum | % { Add-Member -input $output -Type NoteProperty -Name $_.Property -Value $_.Sum }
   
   $output # output the output
}}
new-alias total measure-total

