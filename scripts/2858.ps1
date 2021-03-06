# calculate SHA512 of file.

function Get-SHA512([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]'))
{
  	$stream = $null;
  	$cryptoServiceProvider = [System.Security.Cryptography.SHA512CryptoServiceProvider];
  	$hashAlgorithm = new-object $cryptoServiceProvider
  	$stream = $file.OpenRead();
  	$hashByteArray = $hashAlgorithm.ComputeHash($stream);
  	$stream.Close();

  	## We have to be sure that we close the file stream if any exceptions are thrown.

  	trap
  	{
   		if ($stream -ne $null)
    		{
			$stream.Close();
		}
  		break;
	}	

 	foreach ($byte in $hashByteArray) { if ($byte -lt 16) {$result += “0{0:X}” -f $byte } else { $result += “{0:X}” -f $byte }}
	return [string]$result;
}

function noequal ( $first, $second)
{
    if (!($second) -or $second -eq "") {return $true}
    $first=join-path $first "\"
    foreach($s in $second)
    {
        if ($first.tolower().startswith($s.tolower())) {return $false}
    }
    return $true
}

function WriteFileName ( [string]$writestr )                        # this function prints multiline messages on top of each other, good for iterating through filenames without filling
{                                                                   # the console with a huge wall of text.  Call this function to print each of the filename messages, then call WriteFileNameEnd when done
                                                                    # before printing anything else, so that you are not printing into a long file name with extra characters from it visible.
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
    if ($global:oldctop -ne $null) 
    {
        [console]::cursortop=$global:oldctop
        [console]::cursorleft=0  
    }
    $global:oldctop=$null
    $global:lastlen=$null
}

#   chkhash.ps1 [file(s)/dir #1] [file(s)/dir #2] ... [file(s)/dir #3] [-u] [-h [path of .xml database]]
#   -u updates the XML file database and exits
#   otherwise, all files are checked against the XML file database.
#   -h specifies location of xml hash database


$hashespath=".\hashes.xml"
del variable:\args3 -ea 0
del variable:\args2 -ea 0
del variable:\xfiles -ea 0
del variable:\files -ea 0
del variable:\exclude -ea 0
$args3=@()
$args2=@($args)
$nu = 0
$errs = 0
$fc = 0
$fm = 0
$upd = $false
$create = $false

"ChkHash.ps1 - ChkHash.ps1 can create a .XML database of files and their SHA-512 hashes and check files against the database, "
"in order to detect corrupt or hacked files."
""
".\chkhash.ps1 -h for usage."
""

for($i=0;$i -lt $args2.count; $i++)
{
    if ($args2[$i] -like "-h*")                                             # -help specified?
    {
        "Usage:    .\chkhash.ps1 [-h] [-u] [-c] [-x <file path of hashes .xml database>] [file(s)/dir #1] [file(s)/dir #2] ... [file(s)/dir #n] [-e <Dirs>]"
        "Options:  -h - Help display."
        "          -c - Create hash database. If .xml hash database does not exist, -c will be assumed."
        "          -u - Update changed files and add new files to existing database."
        "          -x - specifies .xml database file path to use. Default is .\hashes.xml"
        "          -e - exclude dirs. Put this after the files/dirs you want to check with SHA512 and needs to be fullpath (e.g. c:\users\bob not ..\bob)."
        ""
        "Examples: PS>.\chkhash.ps1 c:\ d:\ -c -x c:\users\bob\hashes\hashes.xml"
        "             [hash all files on c:\ and d:\ and subdirs, create and store hashes in c:\users\bob\hashes\hashes.xml]"
        "          PS>.\chkhash.ps1 c:\users\alice\pictures\sunset.jpg -u -x c:\users\alice\hashes\pictureshashes.xml]"
        "             [hash c:\users\alice\pictures\sunset.jpg and add or update the hash to c:\users\alice\hashes\picturehashes.xml"
        "          PS>.\chkhash.ps1 c:\users\eve\documents d:\media\movies -x c:\users\eve\hashes\private.xml"
        "             [hash all files in c:\users\eve\documents and d:\media\movies, check against hashes stored in c:\users\eve\hashes\private.xml"
        "              or create it and store hashes there if not present]"
        "          PS>.\chkhash.ps1 c:\users\eve -x c:\users\eve\hashes\private.xml -e c:\users\eve\hashes"
        "             [hash all files in c:\users\eve and subdirs, check hashes against c:\users\eve\hashes\private.xml or store if not present, exclude "
        "              c:\users\eve\hashes directory and subdirs]"
        "          PS>.\chkhash.p1s c:\users\ted\documents\f* d:\data -x d:\hashes.xml -e d:\data\test d:\data\favorites -u"
        "             [hash all files starting with 'f' in c:\users\ted\documents, and all files in d:\data, add or update hashes to"
        "              existing d:\hashes.xml, exclude d:\data\test and d:\data\favorites and subdirs]"
        "          PS>.\chkhash -x c:\users\alice\hashes\hashes.xml"
        "             [Load hashes.xml and check hashes of all files contained within.]"
        ""
        "Note:     files in subdirectories of any specified directory are automatically processed."
        "          if you specify only an -x option, or no option and .\hash.xml exists, only files in the database will be checked."
        exit
    }
    if ($args2[$i] -like "-u*") {$upd=$true;continue}                       # Update and Add new files to database?
    if ($args2[$i] -like "-c*") {$create=$true;continue}                    # Create database specified?
    if ($args2[$i] -like "-x*") 
    {
        $i++                                                                # Get hashes xml database path    
        if ($i -ge $args2.count) 
        {
            write-host "-X specified but no file path of .xml database specified. Exiting."
            exit
        }
        $hashespath=$args2[$i]
        continue
    }
    if ($args2[$i] -like "-e*")                                             # Exclude files, dirs
    {
        while (($i+1) -lt $args2.count)
        {
            $i++
            if ($args2[$i] -like "-*") {break}            
            $exclude+=@(join-path $args2[$i] "\")                           # collect array of excluded directories.            
        }
        continue
    }        
    $args3+=@($args2[$i])                                                   # Add files/dirs
}

if ($args3.count -ne 0) 
{
    # Get list of files and SHA512 hash them.
    "Enumerating files from specified locations..."

    $files=@(dir $args3 -recurse -ea 0 | ?{$_.mode -notmatch "d"} | ?{noequal $_.directoryname $exclude})              # Get list of files, minus directories and minus files in excluded paths

    if ($files.count -eq 0) {"No files found. Exiting."; exit}

    if ($create -eq $true -or !(test-path $hashespath))                        # Create database?
    {       
        # Create SHA512 hashes of files and write to new database
    
        $files = $files | %{WriteFileName "SHA-512 Hashing: `"$($_.fullname)`" ...";add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru}
        WriteFileNameEnd
        $files |export-clixml $hashespath    
        "Created $hashespath"
        "$($files.count) file hash(es) saved. Exiting."
        exit
    }
    write-host "Loading file hashes from $hashespath..." -nonewline
    $xfiles=@(import-clixml $hashespath|?{noequal $_.directoryname $exclude})  # Load database    
    if ($xfiles.count -eq 0) {"No files specified and no files in Database. Exiting.";Exit}
}
else
{
    if (!(test-path $hashespath)) {"No database found or specified, exiting."; exit}
    write-host "Loading file hashes from $hashespath..." -nonewline
    $xfiles=@(import-clixml $hashespath|?{noequal $_.directoryname $exclude}) # Load database and check it
    if ($xfiles.count -eq 0) {"No files specified and no files in Database. Exiting.";Exit}
    $files=$xfiles
}

"Loaded $($xfiles.count) file hash(es)."
    
$hash=@{}
for($x=0;$x -lt $xfiles.count; $x++)                                    # Build dictionary (hash) of filenames and indexes into file array
{
    if ($hash.contains($xfiles[$x].fullname)) {continue}
    $hash.Add($xfiles[$x].fullname,$x)   
}
     
foreach($f in $files)
{
    if ((get-item -ea 0 -literalpath $f.fullname) -eq $null) {continue}              # skip if file no longer exists.
    
    $n=($hash.($f.fullname))
    if ($n -eq $null)
    {    
        $nu++                                           # increment needs/needed updating count
        if ($upd -eq $false) {WriteFileName "Needs to be added: `"$($f.fullname)`"";WriteFileNameEnd;continue}                 # if not updating, then  continue
    
        WriteFileName "SHA-512 Hashing `"$($f.fullname)`" ..."
        
        # Create SHA512 hash of file
        
        $f=$f |%{add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru -force}
        
        $xfiles+=@($f)                                  # then add file + hash to list
        continue
    }
    
    WriteFileName "SHA-512 Hashing and checking: `"$($f.fullname)`" ..."
    
    $f=$f |%{add-member -inputobject $_ -name SHA512 -membertype noteproperty -value $(get-SHA512 $_.fullname) -passthru -force}
    
    $fc++                                               # File checked increment.                                                                  
    if ($xfiles[$n].SHA512 -eq $f.SHA512)               # Check SHA512 for mixmatch.
    {$fm++;continue}                                    # if matched, increment file matches and continue loop
        
    $errs++                                             # increment mixmatches
    if ($upd -eq $true) { $xfiles[$n]=$f; WriteFileName "Updated `"$($f.fullname)`""; WriteFileNameEnd;continue}                                                   
    WriteFileName "Bad SHA-512 found: `"$($f.fullname)`""; WriteFileNameEnd
}

WriteFileNameEnd                                        # restore cursor position after last write string

if ($upd -eq $true)                                     # if database updated
{
    $xfiles|export-clixml $hashespath                   # write xml database
    "Updated $hashespath"
    "$nu file hash(es) added to database."
    "$errs file hash(es) updated in database."
    exit
}

"$errs SHA-512 mixmatch(es) found."
"$fm file(s) SHA512 matched." 
"$fc file(s) checked total."
if ($nu -ne 0) {"$nu file(s) need to be added [run with -u option to Add file hashes to database]."}    
