Script

set-psdebug -trace 2
$sftp = "c:\bin\pscp.exe"
$sftpusername = "username"
$sftppassword = "password"
$sftphost = "sftp.host.com"
$sftpdestination = "`"`/Test Test`/`""
[Array]$sftpArgs = "-sftp", "-v", "-l", "$sftpusername", "-pw", "$sftppassword", "c:\calinstall.log", "$sftphost`:$sftpdestination";
"args: $sftpArgs"
"host: $sftphost"
"destination: $sftpdestination"
"$sftp $sftpArgs"
& $sftp $sftpArgs
set-psdebug -trace 0



Output:
>.\poshpscp.ps1
DEBUG:    2+ $sftp = <<<<  "c:\bin\pscp.exe"
DEBUG:     ! SET $sftp = 'c:\bin\pscp.exe'.
DEBUG:    3+ $sftpusername = <<<<  "username"
DEBUG:     ! SET $sftpusername = 'username'.
DEBUG:    4+ $sftppassword = <<<<  "password"
DEBUG:     ! SET $sftppassword = 'password'.
DEBUG:    5+ $sftphost = <<<<  "sftp.host.com"
DEBUG:     ! SET $sftphost = 'sftp.host.com'.
DEBUG:    6+ $sftpdestination = <<<<  "`"`/Test Test`/`""
DEBUG:     ! SET $sftpdestination = '"/Test Test/"'.
DEBUG:    7+ [Array]$sftpArgs = <<<<  "-sftp", "-v", "-l", "$sftpusername", "-pw", "$sftppassword",
 "c:\calinstall.log", "$sftphost`:$sftpdestination";
DEBUG:     ! SET $sftpArgs = '-sftp -v -l username -pw password c:\calinstall.log ...'.
DEBUG:    8+ "args: $sftpArgs" <<<<
@@args: -sftp -v -l username -pw password c:\calinstall.log sftp.host.com:"/Test Test/"
DEBUG:    9+ "host: $sftphost" <<<<
host: sftp.host.com
DEBUG:   10+ "destination: $sftpdestination" <<<<
destination: "/Test Test/"
DEBUG:   11+ "$sftp $sftpArgs" <<<<
@@c:\bin\pscp.exe -sftp -v -l username -pw password c:\calinstall.log sftp.host.com:"/Test Test/"
DEBUG:   12+  <<<< & $sftp $sftpArgs
@@More than one remote source not supported
DEBUG:   13+  <<<< set-psdebug -trace 0


Running same command manually...
>set-psdebug -trace 2
DEBUG:    2+         $foundSuggestion = <<<<  $false
DEBUG:     ! SET $foundSuggestion = 'False'.
DEBUG:    4+         if <<<< ($lastError -and
DEBUG:   15+         $foundSuggestion <<<<
@@>pscp -v -sftp -l username -pw password c:\calinstall.log sftp.host.com:"/Test Test/"
DEBUG:    1+  <<<< pscp -v -sftp -l username -pw password c:\calinstall.log sftp.host.com:"/Test
Test/"
Looking up host "sftp.host.com"
Connecting to 216.57.210.200 port 22
[[ctrl+c]]
DEBUG:    2+         $foundSuggestion = <<<<  $false
DEBUG:     ! SET $foundSuggestion = 'False'.
DEBUG:    4+         if <<<< ($lastError -and
DEBUG:   15+         $foundSuggestion <<<<
>
