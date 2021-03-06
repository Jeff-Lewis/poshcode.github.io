I think OUT-FORM is a very usefull function. I've added code to sort columns by clicking on headers.

You nedd just add the columnTag parameters specifing if colunm value is text or numeric:

out-form -data (get-process) -columnNames ("Name", "ID" ) -columnProperties ("Name", "ID") -columnTag ("Text", "Numeric")

Hope can help

function Out-Form {
<#
    .Synopsis
        Output the results of a command in a Windows Form
    .Description
        Output the results of a command in a Windows Form with possibility to add buttons with actions 
    .Example
    
        out-form -title "Services" -data (get-service) -columnNames ("Name", "Status") -columnProperties ("DisplayName", "Status") -actions @{"Start" = {$_.start()}; "Stop" = {$_.stop()};}
    #>
  param ($title = "", $data = $null, $columnNames = $null, $columnTag,
         $columnProperties = $null, $actions = $null)
  # a little data defaulting/validation
  if ($columnNames -eq $null) {
    $columnNames = $columnProperties
  }
  if ($columnProperties -eq $null -or
      $columnNames.Count -lt 1 -or
      $columnNames.Count -ne $columnNames.Count) {
     
    throw "Data validation failed"
  }
  $numCols = $columnNames.Count

  # figure out form width
  $width = $numCols * 200
  $actionWidth = $actions.Count * 100 + 40
  if ($actionWidth -gt $width) {
    $width = $actionWidth
  }

  # set up form
  $form = new-object System.Windows.Forms.Form
  $form.text = $title
  $form.size = new-object System.Drawing.Size($width, 400)
  $panel = new-object System.Windows.Forms.Panel
  $panel.Dock = "Fill"
  $form.Controls.Add($panel)

  $lv = new-object windows.forms.ListView
  $panel.Controls.Add($lv)

  # add the buttons
  $btnPanel = new-object System.Windows.Forms.Panel
  $btnPanel.Height = 40
  $btnPanel.Dock = "Bottom"
  $panel.Controls.Add($btnPanel)

  $btns = new-object System.Collections.ArrayList
  if ($actions -ne $null) {
    $btnOffset = 20
    foreach ($action in $actions.GetEnumerator()) {
      $btn = new-object windows.forms.Button
      $btn.DialogResult = [System.Windows.Forms.DialogResult]"OK"
      $btn.Text = $action.name
      $btn.Left = $btnOffset
      $btn.Width = 80
      $btn.Top = 10
      $exprString = '{$lv.SelectedItems | foreach-object { $_.Tag } | foreach-object {' + $action.value + '}}'
      $scriptBlock = invoke-expression $exprString
      $btn.add_Click($scriptBlock)
      $btnPanel.Controls.Add($btn)
      $btnOffset += 100
      $btns += $btn
    }
  }

  # create the columns
  $lv.View = [System.Windows.Forms.View]"Details"
  $lv.Size = new-object System.Drawing.Size($width, 350)
  $lv.FullRowSelect = $true
  $lv.GridLines = $true
  $lv.Dock = "Fill"
  foreach ($col in $columnNames) {
    $lv.Columns.Add($col, 200) > $null
  }
  
  # populate the view
  foreach ($d in $data) {
    $item =
      new-object System.Windows.Forms.ListViewItem(
        (invoke-expression ('$d.' + $columnProperties[0])).tostring())

    for ($i = 1; $i -lt $columnProperties.Count; $i++) {
      $item.SubItems.Add(
        (invoke-expression ('$d.' + $columnProperties[$i])).tostring()) > $null
    }
    $item.Tag = $d
    $lv.Items.Add($item) > $null
  }

# Added by Bar971.it  
  for ($i = 0; $i -lt $columnTag.Count; $i++) {
    
    $lv.Columns[$i].Tag = $columnTag[$i] 
    
  }
  
  $comparerClassString = @"

  using System;
  using System.Windows.Forms;
  using System.Drawing;
  using System.Collections;

  public class ListViewItemComparer : System.Collections.IComparer 
  { 
    public int col = 0;
    
    public System.Windows.Forms.SortOrder Order; // = SortOrder.Ascending;
  
    public ListViewItemComparer()
    {
        col = 0;        
    }
    
    public ListViewItemComparer(int column, bool asc)
    {
        col = column; 
        if (asc) 
        {Order = SortOrder.Ascending;}
        else
        {Order = SortOrder.Descending;}        
    }
    
    public int Compare(object x, object y) // IComparer Member     
    {   
        if (!(x is ListViewItem)) return (0);
        if (!(y is ListViewItem)) return (0);
            
        ListViewItem l1 = (ListViewItem)x;
        ListViewItem l2 = (ListViewItem)y;
            
        if (l1.ListView.Columns[col].Tag == null)
            {
                l1.ListView.Columns[col].Tag = "Text";
            }
        
        if (l1.ListView.Columns[col].Tag.ToString() == "Numeric") 
            {
                float fl1 = float.Parse(l1.SubItems[col].Text);
                float fl2 = float.Parse(l2.SubItems[col].Text);
                    
                if (Order == SortOrder.Ascending)
                    {
                        return fl1.CompareTo(fl2);
                    }
                else
                    {
                        return fl2.CompareTo(fl1);
                    }
             }
         else
             {
                string str1 = l1.SubItems[col].Text;
                string str2 = l2.SubItems[col].Text;
                    
                if (Order == SortOrder.Ascending)
                    {
                        return str1.CompareTo(str2);
                    }
                else
                    {
                        return str2.CompareTo(str1);
                    }
              }     
    }
} 
"@
Add-Type -TypeDefinition $comparerClassString `
  -ReferencedAssemblies (`
    'System.Windows.Forms', 'System.Drawing')
      
$bool = $true
$columnClick = 
{  
  $lv.ListViewItemSorter = New-Object ListViewItemComparer($_.Column, $bool)
  
  $bool = !$bool  
}
$lv.Add_ColumnClick($columnClick)
# End Add by Bar971.it

  # display it
  $form.Add_Shown( { $form.Activate() } )
  if ($btns.Count -gt 0) {
    $form.AcceptButton = $btns[0]
  }
  $form.showdialog()
}


