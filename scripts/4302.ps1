function Query-SQLCETable{
    <#
    .SYNOPSIS
    Establishes a connection and runs a query with a SQL CE database.

    .DESCRIPTION
    Given a query statement and a data source the command will run a query and return the table as an array of objects.

    .EXAMPLE
    Query-SQLCETable -Query 'SELECT * FROM table' -DataSource 'C:\site\App_Data\site.sdf'

    .LINK
    http://erikej.blogspot.com/2011/07/using-powershell-to-manage-sql-server.html
    #>

    [cmdletbinding()]
    param(
        
        #The command you want to run against the table.
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,
        
        #The database you want to connect to.
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        [string]$DataSource,

        #The path to the SQLServerCe assembly.
        [string]$DLLPath='C:\Program Files\Microsoft SQL Server Compact Edition\v4.0\Desktop\System.Data.SqlServerCe.dll'
    )

    if(!(Test-Path -LiteralPath $DLLPath -PathType Leaf)){
        throw 'Invalid "System.Data.SqlServerCe.dll" assembly path.'
        return $false
    }

    try{
        Write-Verbose 'Loading Assembly'
        [Reflection.Assembly]::LoadFile($DLLPath) | Out-Null

        $connectionstring = "Data Source=$DataSource"
        $connection = New-Object -TypeName "System.Data.SqlServerCe.SqlCeConnection" -ArgumentList $connectionstring

        Write-Verbose 'Creating the command'
        $cmd = New-Object -TypeName "System.Data.SqlServerCe.SqlCeCommand" 
        $cmd.CommandType = [System.Data.CommandType]"Text" 
        $cmd.CommandText = $Query
        $cmd.Connection = $connection

        
        Write-Verbose 'Getting the data' 
        $datatable = New-Object -TypeName "System.Data.DataTable"

        $connection.Open() 
        $returndatatable = $cmd.ExecuteReader()

        $datatable.Load($returndatatable) 
        $connection.Close()

        return $datatable
    }
    catch{
        Write-Error "Unable to properly execute command because $($Error[0].Exception.Message)"
        return $false
    }
}
