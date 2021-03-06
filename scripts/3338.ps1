<#
.SYNOPSIS
  Author:...Vidrine
  Date:.....2012/04/08
.DESCRIPTION
  Function uses the Microsoft SQL cmdlets 'Invoke-SQLcmd' to connect to a SQL database and run a SELECT statement.
  Results of the query are returned. Store returned results in a variable to be able to interact with them as an object.
.PARAM server
  Hostname/IP of the server hosting the SQL database.
.PARAM database
  Name of the SQL database to connect to.
.PARAM table
  Name of the table within the specified SQL database.
.PARAM selectWhat
  [String] Select string. This will specify the SELECT value to use in the SQL statement. Default value is '*'.
.PARAM where
  [String] Where string. This will specify the WHERE clause to use in the SQL statement. ie. "id='64'"
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*'
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*' -where "id='64'"
#>
function SQL-Select {
param(
	[string]$server,
	[string]$database,
	[string]$table,
	[string]$selectWhat = '*',
	[string]$where
	
)

## SELECT statement with a WHERE clause
if ($where){
$sqlQuery = @"
SELECT $selectWhat 
FROM $table 
WHERE $where
"@
}

## General SELECT statement
else {
$sqlQuery = @"
SELECT $selectWhat 
FROM $table
"@
}

try
{
$results = Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery

return $results
}
catch{}
}
