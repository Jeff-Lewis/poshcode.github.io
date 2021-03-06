# this is a testcase for http://code.google.com/p/poshcodegen/ 
# a project for generating PowerShell function wrappers around stored procedure call, and more. 

# Here we show how to return a resultsets (aka ref cursors) from an Orcale stored procedures using ADO.NET with PowerShell
# by the way it tell the verion of the orcale Products you are running

# Bernd Kriszio http://pauerschell.blogspot.com/

# Set your connection string (somthing like the following line) outside this function
# $con_ora     =  "Data Source=your-tns;User Id=scott;Password=tiger;Integrated Security=no"

[System.Reflection.Assembly]::LoadWithPartialName("Oracle.DataAccess")
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient")

function noparm_recordset ()
{

#Set up .NET code for calling stored proc
$connection = New-Object System.Data.OracleClient.OracleConnection($con_ora)
$command = New-Object System.Data.OracleClient.OracleCommand('noparm_recordset', $connection)
$command.CommandType = [System.Data.CommandType]::StoredProcedure

#Set up Stored Proc parameters

#$command.Parameters.Add("ReturnValue", [Data.SqlDBType]::int)  | out-null 
#$command.Parameters["ReturnValue"].Direction = [System.Data.ParameterDirection]::ReturnValue 

#$command.Parameters.Add("RC_1", [System.Data.OracleClient.OracleType]::Cursor)  | out-null 
$command.Parameters.Add("RC_1", [Data.OracleClient.OracleType]::Cursor)  | out-null 
$command.Parameters["RC_1"].Direction = [System.Data.ParameterDirection]::Output 

#Run
$connection.Open()  | out-null
$adapter = New-Object System.Data.OracleClient.OracleDataAdapter $command
$dataset = New-Object System.Data.DataSet
[void] $adapter.Fill($dataSet)
#$command.ExecuteNonQuery()
$connection.Close() | out-null

$CommandOutput = New-Object PSObject
$CommandOutput | Add-Member -Name Tables -Value $dataSet.Tables -MemberType NoteProperty

#Set output parameters

#$CommandOutput | Add-Member -Name ReturnValue -Value $command.Parameters["ReturnValue"].Value -MemberType NoteProperty


#Close the connection and return the output object	
return $CommandOutput 

}

(noparm_recordset).tables[0]

<#
-- code of the testprocedure 
create or replace procedure noparm_recordset (
    rc_1 in out SYS_REFCURSOR
) as
begin
    Open rc_1 for
	SELECT * FROM product_component_version ;
end;
/

-- Test call using SQL*Plus
var r refcursor
exec noparm_recordset(:r)
print r

#>
