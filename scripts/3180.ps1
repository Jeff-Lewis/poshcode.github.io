#0# init  
$error.clear() 
cls 
$ErrorActionPreference= "Stop"  # do zmiany na "SilentlyContinue" lub "Continue" po adaptacji
#/0# #1# sql conn parameters
$dataSource = "Serwer\SQL01"
$database = "nazwaBazyDanych"
#$authentication = "Integrated Security=SSPI" # preferowana metoda, ale nie zawsze si&#281; tak da... 
$authentication = "User Id=sqlLogin;Password=P@sswd1;"
$connectionString = "Provider=sqloledb; Data Source=$dataSource; Initial Catalog=$database; $authentication;"
$connection = New-Object System.Data.OleDb.OleDbConnection $connectionString
$connection.Open()
#/1# #2# exec query 
$qry = "SELECT ItemName,ServerName,QuotaValue FROM Packages WHERE (SI.ItemTypeID = 2)"
$commandPrev = New-Object System.Data.OleDb.OleDbCommand $qry,$connection
$adapterPrev = New-Object System.Data.OleDb.OleDbDataAdapter $commandPrev
$datasetPrev = New-Object System.Data.DataSet
[void] $adapterPrev.Fill($dataSetPrev)
$arr = $dataSetPrev.Tables[0].Rows
foreach ($row in $arr) {
$ItemName   = $row.ItemName 
$ServerName = $row.ServerName 
$QuotaValue = $row.QuotaValue.ToString()
$QuotaValueMB = $QuotaValue + "MB"
# a tu cel ca&#322;ej operacji - ustawienie quoty na folder na podstawie bazy danych (na wielu serwerach)
dirquota quota add  /Path:$ItemName /Limit:$QuotaValueMB  /Remote:$ServerName  /Overwrite /Type:Soft
dirquota quota list /Path:$ItemName /Remote:$ServerName
}
#/2# #3#close sql connection
$connection.Close()
#/3#

