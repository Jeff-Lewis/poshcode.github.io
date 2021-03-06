# functions to print overwriting multi-line messages.  Test script will accept a file/filespec/dir and iterate through all files in all subdirs printing a test message + file name to demostrate.
# e.g. PS>.\writefilename.ps1 c:\
# call WriteFileName [string]
# after done writing series of overwriting messages, call WriteFileNameEnd

function WriteFileName ( [string]$writestr )                        # this function prints multiline messages on top of each other, good for iterating through filenames without filling
{                                                                   # the console with a huge wall of text.  Call this function to print each of the filename messages, then call WriteFileNameEnd when done
                                                                    # before printing anything else, so that you are not printing into a long file name with extra characters from it visible.
    if ($Host.Name -match 'ise') 
    { write-host $writestr; return }
                                                                            
    if ($global:lastlen -eq $null) {$global:lastlen=0}              
    $ctop=[console]::cursortop
	[console]::cursorleft=0

	$oldwritestrlen=$writestr.length
	
	$spaces = ""
	if ($global:lastlen -gt $writestr.length)
	{
		$spaces = " " * ($global:lastlen-$writestr.length)
	}

	$writelines = [math]::divrem($writestr.length, [console]::bufferwidth, [ref]$null)

    $cwe = ($writelines-([console]::bufferheight-$ctop))+1                                   # calculate where text has scroll back to.
    if ($cwe -gt 0) {$ctop-=($cwe)}

	write-host "$writestr" -nonewline    
	$global:oldctop=[console]::cursortop
	if ([console]::cursorleft -ne 0) {$global:oldctop+=1}
	write-host "$spaces" -nonewline

	$global:lastlen = $oldwritestrlen

	[console]::cursortop=$ctop
	[console]::cursorleft=0
}
function WriteFileNameEnd ( )                                                                   # call this function when you are done overwriting messages on top of each other
{                                                                                               # and before printing something else
    if ($Host.Name -match 'ise') 
    { return }
    if ($global:oldctop -ne $null) 
    {
        [console]::cursortop=$global:oldctop
        [console]::cursorleft=0  
    }
    $global:oldctop=$null
    $global:lastlen=$null
}

    dir $args -recurse -ea 0 -force | %{$string="Test String. "*(get-random(100));$string+="Checking $($_.fullname) ..."; WriteFileName $string;sleep -seconds 1}
    
    #WriteFileName "Final Test String."
    WriteFileNameEnd
    write-host "Done! exiting."
