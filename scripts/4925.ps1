#############################################################################################
#
# NAME: lastdbusage.ps1
# AUTHOR: Rob Sewell
# DATE:19/10/2013
#
# COMMENTS: Fill Excel WorkBook with details for last access times for each database
#
# NOTES : Does NOT work with SQL 2000 boxes
 
# Set SQL Query
$query = "WITH agg AS
(
  SELECT
       max(last_user_seek) last_user_seek,
       max(last_user_scan) last_user_scan,
       max(last_user_lookup) last_user_lookup,
       max(last_user_update) last_user_update,
       sd.name dbname
   FROM
       sys.dm_db_index_usage_stats, master..sysdatabases sd
   WHERE
      sd.name not in('master','tempdb','model','msdb')
   AND
     database_id = sd.dbid  group by sd.name
)
SELECT
   dbname,
   last_read = MAX(last_read),
   last_write = MAX(last_write)
FROM
(
   SELECT dbname, last_user_seek, NULL FROM agg
   UNION ALL
  SELECT dbname, last_user_scan, NULL FROM agg
   UNION ALL
   SELECT dbname, last_user_lookup, NULL FROM agg
   UNION ALL
   SELECT dbname, NULL, last_user_update FROM agg
) AS x (dbname, last_read, last_write)
GROUP BY
   dbname
ORDER BY 1;
"
#Open Excel
$xl = new-object -comobject excel.application
$wb = $xl.Workbooks.Add()
 
  
    # Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
 
# Get List of sql servers to check
$sqlservers = Get-Content 'D:\SkyDrive\Documents\Scripts\Powershell Scripts\sqlservers.txt'

# Loop through each sql server from sqlservers.txt
foreach($sqlserver in $sqlservers)
{
# Get the time SQL was restarted
$svr = New-Object 'Microsoft.SQLServer.Management.Smo.Server' $SQLServer
$db = $svr.Databases['TempDB']
$CreateDate = $db.CreateDate

#Run Query against SQL Server
$Results = Invoke-Sqlcmd -ServerInstance $sqlServer -Query $query -Database master
# Add a new sheet
$ws = $wb.Worksheets.Add()
$name = "$sqlserver"
# Name the Sheet
$ws.name = $Name
$cells=$ws.Cells
$xl.Visible = $true
#define some variables to control navigation
$row = 2
$col = 2
    $cells.item($row,$col)=$SQLServer + ' Was Rebooted at ' + $CreateDate
    $cells.item($row,$col).font.size=16
    $Cells.item($row,$col).Columnwidth = 10
$row=3
$col=2
# Set some titles
    $cells.item($row,$col)="Server"
    $cells.item($row,$col).font.size=16
    $Cells.item($row,$col).Columnwidth = 10
    $col++
    $cells.item($row,$col)="Database"
    $cells.item($row,$col).font.size=16
    $Cells.item($row,$col).Columnwidth = 40
    $col++
    $cells.item($row,$col)="Last Read"
    $cells.item($row,$col).font.size=16
    $Cells.item($row,$col).Columnwidth = 20
    $col++
    $cells.item($row,$col)="Last Write"
    $cells.item($row,$col).font.size=16   
    $Cells.item($row,$col).Columnwidth = 20
    $col++
 
 
foreach($result in $results)
{
# Check if value is NULL
$DBNull = [System.DBNull]::Value
$LastRead = $Result.last_read
$LastWrite = $Result.last_write
 
$row++
$col=2
$cells.item($Row,$col)=$sqlserver
$col++
$cells.item($Row,$col)=$Result.dbname
$col++
if($LastRead -eq $DBNull)
{
$LastRead = "Not Since Last Reboot"
$colour = "46"
$cells.item($Row,$col).Interior.ColorIndex = $colour
$cells.item($Row,$col)= $LastRead
}
else
{
$cells.item($Row,$col)= $LastRead
}
$col++
if($LastWrite -eq $DBNull)
{
$LastWrite = "Not Since Last Reboot"
$colour = "46"
$cells.item($Row,$col).Interior.ColorIndex = $colour
$cells.item($Row,$col)= $LastWrite
}
else
{
$cells.item($Row,$col)= $LastWrite
}
}
 
}
 
 
$xl.DisplayAlerts = $false

$wb.Saveas("D:\DatabaseLastAccessTimeFeb2014.xlsx")
$xl.quit()
Stop-Process -Name *excel*
 
