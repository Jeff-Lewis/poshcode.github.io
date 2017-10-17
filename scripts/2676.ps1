﻿if (!( gmo ShowUI)) {ipmo showui}

if(!(Get-Command DataGrid -ErrorAction SilentlyContinue)) {
    Add-UIFunction -Type System.Windows.Controls.DataGrid
}

if(!(Get-Command DataGridTextColumn -ErrorAction SilentlyContinue)) {
    Add-UIFunction -Type  System.Windows.Controls.DataGridTextColumn
}

if(!(Get-Command DataGridHyperlinkColumn -ErrorAction SilentlyContinue)) {
    Add-UIFunction -Type  System.Windows.Controls.DataGridHyperlinkColumn
}

# Attention this uses WPF 4.0 cf. http://stackoverflow.com/questions/2094694/launch-powershell-under-net-4/5069146#5069146
# Firefox Bookmarks http://stackoverflow.com/questions/464516/firefox-bookmarks-sqlite-structure
# System.Data.SQLite Download  http://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki
# Currently DONT INSTALL IT IN GAC http://system.data.sqlite.org/index.html/tktview?name=54e52d4c6f

if (! $sqlitedll)
{
    $sqlitedll = [System.Reflection.Assembly]::LoadFrom("C:\Program Files\System.Data.SQLite\bin\System.Data.SQLite.dll") 
}

# copy your firefox bookmarks and tell youe system where to find the copy
$ConnectionString = "Data Source=C:\Var\sqlite_ff4\places.sqlite"

$conn = new-object System.Data.SQLite.SQLiteConnection 
$conn.ConnectionString = $ConnectionString 
$conn.Open() 

# $sql = "SELECT * from moz_bookmarks t1 where parent = 4 and t1.title = 'sqlite' or t1.title = 'sql'"

function Invoke-sqlite
{
    param( [string]$sql,
           [System.Data.SQLite.SQLiteConnection]$connection
           )
    $cmd = new-object System.Data.SQLite.SQLiteCommand($sql,$connection)
    $ds = New-Object system.Data.DataSet
    $da = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    $da.fill($ds) | Out-Null
    return $ds.tables[0]
}

function Invoke-sqlite2
{
    param( [string]$sql,
           [System.Data.SQLite.SQLiteConnection]$connection
           )
    $cmd = new-object System.Data.SQLite.SQLiteCommand($sql,$connection)
    $ds = New-Object system.Data.DataSet
    $da = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    $da.fill($ds) | Out-Null
    $ds.tables[0]
}

# $o1   =  Invoke-sqlite $sql $conn
# $o2   =  Invoke-sqlite2 $sql $conn


function Show-Bockmarks ($conn) {
    Show  -Parameters $conn -width 1600 -top 100 -left 10 -height 300 -maxheight 900 {
        Param(
            $conn
        )
        
        $useDataGrid = $true

        $global:UIInputWindow = $this
        GridPanel -ColumnDefinitions @(
                ColumnDefinition -Width 900*
            ) -RowDefinitions @(
                RowDefinition -Height 30
                RowDefinition -Height 600*
            )     {
                StackPanel -Orientation horizontal  -Grid-Column 0 -Grid-Row 0 -Children {
                     Label    '1. Keyword'
                     TextBox  -Name tag1 -width 200
                     Label    '2. Keyword'
                     TextBox  -Name tag2 -width 200
                     Label    '3. Keyword'
                     TextBox  -Name tag3 -width 200
                     Button -Name Search "search" -On_Click {
                    $text1 = Select-UIElement $global:UIInputWindow Tag1
                    $tag1 = $text1.Text
                    $text2 = Select-UIElement $global:UIInputWindow Tag2
                    $tag2 = $text2.Text
                    $text3 = Select-UIElement $global:UIInputWindow Tag3
                    $tag3 = $text3.Text
                    if ( $tag2 -ne '') {
$clause2 = @"            
    join moz_bookmarks l2 on b.fk = l2.fk and b.id <> l2.id
    join moz_bookmarks t2 on l2.parent = t2.id and  t2.parent = 4 and upper(t2.title) = upper('$tag2')
"@                        
            } else { $clause2 = '' }        

            if ( $tag3 -ne '') {
$clause3 = @"            
    join moz_bookmarks l3 on b.fk = l3.fk and b.id <> l3.id
    join moz_bookmarks t3 on l3.parent = t3.id and  t3.parent = 4 and upper(t3.title) = upper('$tag3')
"@                        
            } else { $clause3 = '' }        

$ff_sql = @"
SELECT b.title, datetime (b.dateAdded / 1000000, 'unixepoch', 'localtime') dateAdded , p.url
    from moz_bookmarks b
    join moz_bookmarks l1 on b.fk = l1.fk and b.id <> l1.id
    join moz_bookmarks t1 on l1.parent = t1.id and  t1.parent = 4 and upper(t1.title) = upper('$tag1')
    join moz_places p  on b.fk = p.id $clause2 $clause3
where b.title is not null and b.type = 1
order by b.dateAdded
"@
                    Write-Host $ff_sql
            $global:UIInputWindow.Title = "$($conn.database) Database Browser"
            $dg = Select-UIElement $global:UIInputWindow  TableView
            $dg.ItemsSource = @(Invoke-sqlite -sql $ff_sql -connection $conn)
#            $TableView.DataContext = @(Invoke-sqlite -sql $ff_sql -connection $conn)
             } 
             Button -Name Cancel "Close" -On_Click {$global:UIInputWindow.Close()} 
        }

        If ($useDataGrid)
        {
               DataGrid -Grid-Column 0 -Grid-Row 1 `
                -Name TableView `
                -columns {
                    DataGridTextColumn -width 500* -Header "title"     -Binding { Binding -Path "title" }
                    DataGridTextColumn -width 100* -Header "dateAdded" -Binding { Binding -Path "dateAdded" }
                    DataGridHyperlinkColumn -width 500* -Header "url"  -Binding { Binding -Path "url" }  `
                        -ContentBinding  { Binding -Path "url" }  
#                         -On_HyperlinkClick {
#                             Write-Host  $this    
#                         }       
                }   -On_SelectionChanged {
                     start $this.selecteditem.url
                }  
        } else {
                ListView -Grid-Column 0 -Grid-Row 1 -Name TableView -View {
                   GridView -AllowsColumnReorder -Columns {
                       GridViewColumn -Header "title"     -DisplayMemberBinding { Binding -Path "title" }
                       GridViewColumn -Header "dateAdded" -DisplayMemberBinding { Binding -Path "dateAdded" }
                       GridViewColumn -Header "url"       -DisplayMemberBinding { Binding -Path "url" } 
                   }
                }   -On_SelectionChanged {
                     start $this.selecteditem.url
                }

        }
    }
    }
}

Show-Bockmarks $conn
$conn.close()

