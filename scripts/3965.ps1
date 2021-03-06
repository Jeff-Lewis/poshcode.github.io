param($fileName)

Add-Type -Path "C:\Oracle\Oracle.ManagedDataAccess.dll"

#Change these values
$userID = "yourOracleUserID"
$password ="yourOraclePassword"
$dataSource ="yourOracleDB"

#Assumes Table name is same as file name without extension
#and ctl file will output to same directory with ctl extension
get-item $fileName | %{$baseName = $_.BaseName; $directory = $_.Directory}
$table = $baseName.ToUpper()
$ctlFile = "{0}\{1}.ctl" -f $directory,$baseName


#######################
function Get-CtlFile {
    param($fileName,$table, $cols)

$ctlFile = @"
load data 
infile '$fileName' "str '<EOFD><EORD>'"
into table $table 
fields terminated by '<EOFD>' 
trailing nullcols 
( 
$cols
) 
"@
    Write-Output $ctlFile
} #Get-CtlFile

#######################
function Get-Query {
    param($table)

$query = @"
SELECT
CASE WHEN DATA_TYPE = 'DATE' THEN COLUMN_NAME || ' DATE "MM/DD/YYYY HH24:MI:SS"'
WHEN DATA_TYPE = 'CLOB' THEN COLUMN_NAME || ' CHAR(8000)'
ELSE COLUMN_NAME
END AS COLUMN_NAME
FROM user_tab_columns
WHERE TABLE_NAME = '$table'
ORDER BY column_id
"@
    Write-Output $query
} #Get-Query

#######################
$con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection("User Id=$userID;Password=$password;Data Source=$dataSource")
$con.open()
$query = Get-Query $table
$cmd=new-object Oracle.ManagedDataAccess.Client.OracleCommand($query,$con)
#$cols = $cmd.ExecuteScalar()
$ds=New-Object system.Data.DataSet
$da=New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($cmd)
[void]$da.fill($ds)
$cols = $ds.Tables | %{$_.COLUMN_NAME}
$cols = $cols -join ","
$con.Close()

if ($cols) {
    Get-CtlFile $fileName $table $cols | out-file -filepath $ctlFile -encoding ASCII
}

#1. Call Script for all .dat files  in directory
    #get-item C:\users\u00\Desktop\APEX\out\db\*.dat | %{.\Out-SqlldrCtlFile.ps1 $_.FullName}
#2. Gen up sqlldr commands to execute
    #get-item *.ctl | % { "sqlldr userID/password control=$($_.FullName)"} | ogv
