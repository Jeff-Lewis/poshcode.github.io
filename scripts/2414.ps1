function Receive-Stream {
#.Synopsis
#  Read a stream to the end and close it
#.Description
#  Will read from a byte stream and output a string or a file
#.Param reader
#  The stream to read from
#.Param fileName
#  A file to write to. If this parameter is provided, the function will output to file
#.Param encoding
#  The text encoding, if you want to override the default.
param( [System.IO.Stream]$reader, $fileName, $encoding = [System.Text.Encoding]::GetEncoding( $null ) )
   
	if($fileName) {
		try {
			$writer = new-object System.IO.FileStream $fileName, ([System.IO.FileMode]::Create)
		} catch {
			Write-Error "Failed to create output stream. The error was: '$_'"
			return $false
		}
	} else {
		[string]$output = ""
	}
	   
	[byte[]]$buffer = new-object byte[] 4096
	[int]$total = [int]$count = 0

	try {
		$count = $reader.Read($buffer, 0, $buffer.Length)

		while ($count -gt 0) {
			if($fileName) {
				$writer.Write($buffer, 0, $count)
			} else {
				$output += $encoding.GetString($buffer, 0, $count)
			}
			$count = $reader.Read($buffer, 0, $buffer.Length)
		} 
	} catch {
		Write-Error "Failed to write stream. The error was: '$_'"
		return $false
	}

	$reader.Close()
	$writer.Close()
	if(!$fileName) 
		{ return $output }
	else
		{ return $true }
}
