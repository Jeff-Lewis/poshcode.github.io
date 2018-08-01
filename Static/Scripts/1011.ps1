# New-StoredProcFunction.ps1
# Steven Murawski
# http://blog.usepowershell.com
# 04/08/2009
# Replaced the parsing of the stored procedure text and use Information_Schema.Parameters to get the parameter information
# Thanks to Chad Miller for the idea.
 
# Example: ./New-StoredProcFunction.ps1 'Data Source=MySqlServer;Database=Northwind;User=AnythingButSa;Password=abc123' sp_createnewcustomer
# Example 'sp_createnewcustomer | ./New-StoredProcFunction.ps1 'Data Source=MySqlServer;Database=Northwind;User=AnythingButSa;Password=abc123'
 
param($ConnectionString, [String[]]$StoredProc= $null)
BEGIN
{
	if ($StoredProc.count -gt 0)
	{
		$StoredProc | ./New-StoredProcFunction $ConnectionString
	}
	function Invoke-SQLQuery()
	{
		param ($ConnectionString, $Query)
		$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
		$command = New-Object System.Data.SqlClient.SqlCommand $query,$connection
		$connection.Open()
		$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
		$dataset = New-Object System.Data.DataSet
		[void] $adapter.Fill($dataSet)
		$connection.Close()
		$dataSet.Tables | ForEach-Object {$_.Rows} 
	}
	
	function Get-FunctionParameter()
	{
		param($FunctionName, $ConnectionString)
		$query = @"
SELECT parameter_Name, data_type, character_maximum_length, parameter_mode
FROM INFORMATION_SCHEMA.Parameters
WHERE specific_NAME LIKE '$FunctionName'
"@
		$Rows = Invoke-SQLQuery $ConnectionString $Query 

		foreach ($Row in $Rows)
		{
			$Parameter = "" | Select-Object Name, DataType, Length, IsOutput
			$Parameter.Name = $row.parameter_Name
			$Parameter.DataType = $Row.data_type
			$Parameter.Length = $Row.character_maximum_length
			$Parameter.IsOutput = if ($Row.parameter_mode -eq 'INOUT'){$true} else {$false}
			$Parameter
		}
	}
}
PROCESS
{
	if ($_ -ne $null)
	{
		$FunctionName = $_
		$Parameters = Get-FunctionParameter $FunctionName $ConnectionString
		
		[String[]]$InputParamNames = $Parameters | where {-not $_.IsOutput} | ForEach-Object {$_.Name -replace '@' }
		[String[]]$OutputParameterNames = $Parameters | Where-Object {$_.IsOutput} | ForEach-Object {$_.Name -replace '@'}
		
		$ScriptText = ' '
		
		if ($InputParamNames.count -gt 0)
		{
			$OFS = ', $'
			$ScriptText += 'param (${0})' -f $InputParamNames
			$ScriptText += "`n" 
			$OFS = ', '
		}
		
		$BodyTemplate = @'
$connection = New-Object System.Data.SqlClient.SqlConnection('{0}')
$command = New-Object System.Data.SqlClient.SqlCommand('{1}', $connection)
$command.CommandType = [System.Data.CommandType]::StoredProcedure

'@
		$ScriptText += $BodyTemplate -f $ConnectionString, $FunctionName
		if ( ($Parameters -ne $null) -or ($Parameters.count -gt 1) )
		{
			
			if ($OutputParameterNames.count -gt 0)
			{
				$ReturnText = "" 
				$CommandOutput = "" | select $OutputParameterNames
			}
			#Add the parameters	
			foreach ($param in $Parameters)
			{
				if ($param.length -isnot [DBNull])
				{
					$ParamTemplate = '$command.Parameters.Add("{0}", "{1}", {2})  | out-null ' 
					$ScriptText += "`n" 
					$ScriptText += $ParamTemplate -f $param.name, $param.datatype, $param.length
				}
				else
				{
					$ParamTemplate = '$command.Parameters.Add("{0}", "{1}")  | out-null '
					$ScriptText += "`n" 
					$ScriptText += $ParamTemplate -f $param.name, $param.datatype
				}
				
				if ($param.IsOutput)
				{
					$ScriptText += "`n" 
					$ScriptText += '$command.Parameters["{0}"].Direction = [System.Data.ParameterDirection]::Output ' -f $param.Name
					$ReturnText += "`n"
					$ReturnText += '$CommandOutput.{1} = $command.Parameters["{0}"].Value' -f $param.name, ($param.name -replace '@')
				}
				else
				{
					$ScriptText += "`n" 
					$ScriptText += '$command.Parameters["{0}"].Value = ${1} ' -f $param.name, ($param.name -replace '@')
				}
			}				
		}
		
		$ScriptText += "`n"
		$ScriptText += @'
$connection.Open()  | out-null
$command.ExecuteNonQuery() | out-null

'@	
		if ($OutputParameterNames.count -gt 0)
		{
			$ScriptText += $ReturnText
		}
		
		$ScriptText += @'
		
$connection.Close() | out-null
return $CommandOutput 
'@
		
		#$ScriptText
		Set-Item -Path function:global:$FunctionName -Value $scripttext
	}
}
