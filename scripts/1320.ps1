Function Get-Snapinfo {
    <#
    .Synopsis
        Get the snapshot info out of a Virtual Machine Managed Entity.  Most useful for
        reporting!
    .PARAMETER VM
        VirtualMachine object to scan to extract snapshots from
    .PARAMETER VirtualMachineSnapshotTree
        used to recursively crawl a VM for snapshots... just use -VM
    .PARAMETER Filter
        Specify the name of the snapshots you want to retrieve, will perform a regex match.
    .Example
        Get-View -ViewType virtualmachine | Get-Snapinfo
    .Example
        Get-View -ViewType virtualmachine | Get-Snapinfo -Filter "^SMVI"
    .notes
        #Requires -verson 2 
        Author: Glenn Sizemore
        get-admin.com/blog/?p=879
    #>
    [cmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="VM")]
    Param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true, ParameterSetName="VM")]
        [VMware.Vim.VirtualMachine[]]
        $VM,
        
        [parameter(Mandatory=$true,ValueFromPipeline=$true, ParameterSetName="Snaptree")]
        [VMware.Vim.VirtualMachineSnapshotTree[]]
        $VirtualMachineSnapshotTree,
        
        [parameter(ParameterSetName="VM")] 
        [parameter(ParameterSetName="Snaptree")]
        [string]
        $Filter
    )
    Process {
        switch ($PScmdlet.ParameterSetName) 
        {
            "Snaptree"
            {
                Foreach ($Snapshot in $VirtualMachineSnapshotTree) {
                    Foreach ($ChildSnap in $Snapshot.ChildSnapshotList) {
                        if ($ChildSnap) {
                            Get-Snapinfo -VirtualMachineSnapshotTree $ChildSnap -Filter $Filter
                        }
                    }
                    If ($Snapshot.Name -match $Filter ) {
                        write-output $Snapshot | Select Name, CreateTime, Vm, Snapshot
                    }
                }
            }
            "VM"
            {
                Foreach ($v in $VM) {
                    Get-Snapinfo -VirtualMachineSnapshotTree $v.Snapshot.RootSnapshotList -Filter $Filter
                }
            }
        }
    }
}
