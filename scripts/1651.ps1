Function Import-ASUP 
{
    param(
        [string]
        $Path
    )
    Begin {
        Function ConvertTo-Bool($bool) {
            switch ($bool) {
                "yes"      {return $true}
                "true"     {return $true}
                "enabled"  {return $true}
                "no"       {return $False}
                "false"    {return $False}
                "disabled" {return $False}
            }
        }
    }
    Process {
        $asup = Get-Content $Path
        $Storage = New-Object PSObject -Property @{SysInfo=@{};HostAdapters=@{};Disks=@();Shelves=@();SES=@{}}
        $process = 0 
        $subprocess=0
        $AggrHold = @{}
        Foreach ($line in $asup) {
            switch -regex ($line) 
            {
                "=====" 
                {
                    $Process = 0
                }
                "===== SYSCONFIG-A =====" 
                {
                    $process = 1 
                    $subprocess = 0
                }
                "===== ENVIRONMENT ====="
                {
                    $process = 2 
                    $subprocess = 0
                }
                "===== SYSCONFIG-R =====" 
                {
                    $process = 3 
                    $subprocess = 0
                }
                "===== STORAGE ====="
                {
                    $process = 4 
                    $subprocess = 0
                }            
            }
            switch ($process) 
            {
                1
                {
                    switch -regex ($Line)
                    {
                        "\s+System\sID\:\s(?<SystemID>\S+)\s\((?<SystemName>\S+)\)\;\spartner\sID\:\s(?<PartnerID>\S+)\s\((?<PartnerName>\S+)\)"
                        {
                            $Storage.SysInfo.Add("SystemID",$Matches.SystemID)
                            $Storage.SysInfo.Add("SystemName",$Matches.SystemName)
                            $Storage.SysInfo.Add("PartnerID",$Matches.PartnerID)
                            $Storage.SysInfo.Add("PartnerName",$Matches.PartnerName)
                        }
                        "\s+System\sSerial\sNumber\:\s(?<SN>\S+)"
                        {
                            $Storage.SysInfo.Add("SerialNumber",$Matches.SN)
                        }
                        "\s+System\sRev\:\s(?<Rev>\S+)"
                        {
                            $Storage.SysInfo.Add("Rev",$Matches.Rev)
                        }
                        "\s+System\sStorage\sConfiguration\:\s(?<config>.+)"
                        {
                            $Storage.SysInfo.Add("StorageConfiguration",$Matches.config)
                        }
                        "System\sACP\sConnectivity\:\s(?<ACP>.+)"
                        {
                            $Storage.SysInfo.Add("ACP",$Matches.ACP)
                        }
                        "slot\s0\:\sSystem\sBoard\s(?<board>.+)"
                        {
                            $subProcess=1
                            $Slot = New-Object PSObject -Property @{
                                "Board"=$Matches.board
                                "ModelName"=""
                                "PartNumber"=""
                                "Revision"=""
                                "SerialNumber"=""
                                "BIOSversion"=""
                                "LoaderVersion"=""
                                "AgentFWversion"=""
                                "Processors"=""
                                "ProcessorID"=""
                                "MicrocodeVersion"=""
                                "MemorySize"=""
                                "CMOSRAMStatus"=""
                                "Controller"=""
                            }
                        }
                    }
                    switch ($subProcess) 
                    {
                        1
                        {
                            switch -regex ($Line)
                            {
                                "\s+Model\sName\:\s+(?<Model>.+)"
                                {
                                    $Slot.ModelName = $Matches.Model
                                }
                                "\s+Part\sNumber\:\s+(?<Part>.+)"
                                {
                                    $Slot.PartNumber = $Matches.Part
                                }
                                "\s+Revision\:\s+(?<REV>.+)"
                                {
                                    $Slot.Revision = $Matches.REV
                                }
                                "\s+Serial\sNumber\:\s+(?<SN>.+)"
                                {
                                    $Slot.SerialNumber = $Matches.SN
                                }
                                "\s+BIOS\sversion\:\s+(?<BIOS>.+)"
                                {
                                    $Slot.BIOSversion = $Matches.BIOS
                                }
                                "\s+Loader\sversion\:\s+(?<LV>.+)"
                                {
                                    $Slot.LoaderVersion = $Matches.LV
                                }
                                "\s+Agent\sFW\sversion\:\s+(?<FW>.+)"
                                {
                                    $Slot.AgentFWversion = $Matches.FW
                                }
                                "\s+Processors\:\s+(?<proc>.+)"
                                {
                                    $Slot.Processors = $Matches.proc
                                }
                                "\s+Processor\sID\:\s+(?<procID>.+)"
                                {
                                    $Slot.ProcessorID = $matches.procId
                                }
                                "\s+Microcode\sVersion\:\s+(?<microcode>.+)"
                                {
                                    $Slot.MicrocodeVersion = $Matches.microcode
                                }
                                "\s+Memory\sSize\:\s+(?<memory>.+)"
                                {
                                    $Slot.MemorySize = $Matches.memory
                                }
                                "\s+CMOS\sRAM\sStatus\:\s+(?<CMOS>.+)"
                                {
                                    $Slot.CMOSRAMStatus = $Matches.CMOS
                                }
                                "\s+Controller\:\s+(?<Controller>.+)"
                                {
                                    $Slot.Controller = $Matches.Controller
                                    $Storage.SysInfo.Add("SystemBoard",$slot)
                                    $subprocess = 0
                                }
                                
                            }
                        }
                    }
                }
                2
                {
                    switch -regex ($Line)
                    {
                        "^Channel\:\s+(?<Channel>\d\w)\sShelf\:\s+(?<Shelf>\d)\sShelf\sSerial\sNumber:\s+(?<ShelfSN>.+)"
                        {
                            $Shelf = New-Object PSObject -Property @{
                                "Channel"=$Matches.Channel
                                "Shelf"=$Matches.Shelf
                                "SerialNumber"=$Matches.ShelfSN
                                "ShelfVendor"=""
                                "ShelfModel"=""
                                "ShelfRevisionLevel"=""
                                "ModelName"=""
                                "ModuleASerialNumber"=""
                                "ModuleAFirmware"=""
                                "ModuleBSerialNumber"=""
                                "ModuleBFirmware"=""
                                "LocalAcessID"=""
                            }
                        }
                        "^Shelf\sproduct\sid\:\s(?<model>.+)"
                        {
                            $Shelf.ModelName = $Matches.model
                        }
                        "Module\sA\sSerial\sNumber\:\s(?<SN>\S+)\s+Firmware\srev\:\s(?<Rev>\S+)"
                        {
                            $Shelf.ModuleASerialNumber = $Matches.SN
                            $Shelf.ModuleAFirmware = $Matches.Rev
                        }
                        "Module\sB\sSerial\sNumber\:\s(?<SN>\S+)\s+Firmware\srev\:\s(?<Rev>\S+)"
                        {
                            $Shelf.ModuleBSerialNumber = $Matches.SN
                            $Shelf.ModuleBFirmware = $Matches.Rev
                            if (!$Storage.SES.Contains($Shelf.Channel)) 
                            {
                                $Storage.SES.Add($Shelf.Channel,@{})
                            }
                            ($Storage.SES[$Shelf.Channel]).add($shelf.Shelf, $shelf)
                        }
                        "\s+Channel\:\s+(?<channel>\d\w)"
                        {
                            $_channel = $matches.channel
                        }
                        "\s+shelf\:\s+(?<channel>\d)$"
                        {
                            $_Shelf = $matches.channel
                            $subprocess = 1
                        }
                    }
                    switch ($subProcess) 
                    {
                        1
                        {
                            switch -regex ($Line)
                            {
                                "local\saccess\:\s(?<Port>\d\w\.\d{2,3})$"
                                {
                                    $Storage.SES[$_channel][$_Shelf].LocalAcessID = $Matches.Port
                                }
                                "^\s+Module\stype\:\s(?<Module>\S+)\;"
                                {
                                    $Storage.SES[$_channel][$_Shelf].ModelName = $Matches.Module
                                }
                                "SES\sConfiguration"
                                {
                                    $subProcess = 2
                                }
                            }
                        }
                        2
                        {
                            switch -regex ($Line)
                            {
                                "\s+vendor\sidentification\=(?<Vendor>.+)"
                                {
                                    $Storage.SES[$_channel][$_Shelf].ShelfVendor=$Matches.Vendor
                                }
                                "\s+product\sidentification\=(?<ShelfModel>.+)"
                                {
                                    $Storage.SES[$_channel][$_Shelf].ShelfModel = $Matches.ShelfModel
                                }
                                "\s+product\srevision\slevel\=(?<ShelfRevisionLevel>.+)"
                                {
                                    $Storage.SES[$_channel][$_Shelf].ShelfRevisionLevel = $Matches.ShelfRevisionLevel
                                    $subprocess = 0
                                }
                            }
                        }
                    }
                }
                3 
                {
                    Switch -regex ($line) 
                    {
                        "^Aggregate\s(?<aggr>\S+)\s"
                        {
                            $subprocess =1
                            $aggr=$matches.aggr
                        }
                        "^Spare\sdisks$|^Partner\sdisks$"
                        {
                            $subprocess =1
                            $aggr=$null
                        }
                    }
                    switch -regex ($line)
                    {
                        "^\s{6}(?<R>\S+)\s+(?<D>\S+)(\s+\S+){5}\s+(?<T>\S+)\s+\S+\s+(?<UMB>\d+)\/(?<UB>\d+)\s+(?<PMB>\d+)\/(?<PB>\d+)"
                        {
                            $aggrHold.Add($Matches.D, @{
                                Aggregate=$aggr
                                RaidType=$Matches.R
                                DiskType=$Matches.T
                                UsedMB=$Matches.UMB
                                UsedBlocks=$Matches.UB
                                PhysicalMB=$Matches.PMB
                                PhysicalBlocks=$Matches.PB
                            })
                        }
                        "^(?<R>\S+)\s+(?<D>\S+)(\s+\S+){5}\s+(?<T>\S+)\s+\S+\s+(?<UMB>\d+)\/(?<UB>\d+)\s+(?<PMB>\d+)\/(?<PB>\d+)"
                        {
                            $aggrHold.Add($Matches.D, @{
                                Aggregate=""
                                RaidType=$Matches.R
                                DiskType=$Matches.T
                                UsedMB=$Matches.UMB
                                UsedBlocks=$Matches.UB
                                PhysicalMB=$Matches.PMB
                                PhysicalBlocks=$Matches.PB
                            })
                        }
                        
                    }
                }
                4 
                {
                    switch -regex ($line) 
                    {
                        "^Slot\:\s+(?<slot>\d\w)$" 
                        { 
                            $subprocess = 1
                            $Adapter = New-Object PSObject -Property @{
                                Name=""
                                Description=""
                                FirmwareRev=""
                                FCNodeName=""
                                FCPacketSize=""
                                LinkDataRate=""
                                SRAMParity=$false
                                ExternalGBIC=$false
                                State=""
                                InUse=$false
                                Redundant=$false
                            }
                        }
                        "^Shelf\sname\:\s+(?<Shelf>.+)" 
                        {
                            $subprocess = 2
                            $shelf = New-Object PSObject -Property @{
                                Name=""
                                Channel=""
                                Module=""
                                ShelfID=0
                                ShelfUID=""
                                ShelfSN=""
                                TermSwitch=""
                                ShelfState=""
                                ModuleState=""
                                SerialNumber=""
                                ShelfVendor=""
                                ShelfModel=""
                                ShelfRevisionLevel=""
                                ModelName=""
                                ModuleASerialNumber=""
                                ModuleAFirmware=""
                                ModuleBSerialNumber=""
                                ModuleBFirmware=""
                                LocalAcessID=""
                            }
                        }
                        "^Disk\:\s+(?<Shelf>.+)" 
                        {   
                            $subprocess = 3
                            $disk = New-Object PSObject -Property @{
                                "Name"=""
                                "shelf"=0
                                "Bay"=0
                                "RaidType"=""
                                "Aggregate"=""
                                "DiskType"=""
                                "SN"=""
                                "Vendor"=""
                                "Model"=""
                                "Firmware"=""
                                "RPM"=0
                                "WWN"=""
                                "UID"=""
                                "DownRev"=""
                                "PrimaryPort"=""
                                "Secondaryname"=""               
                                "SecondaryPort"=""
                                "PowerOnHours"=0
                                "UsedMB"=""
                                "UsedBlocks"=""
                                "PhysicalMB"=""
                                "PhysicalBlocks"=""
                                "BlocksRead"=[int64]0
                                "BlocksWritten"=[int64]0
                                "TimeInterval"=""
                                "GlistCount"=0
                                "ScrubLastDone"=""
                                "ScrubCount"=0
                                "LipCount"=0
                                "DynamicallyQualified"=$false
                                "PowerCycleCount"=0
                                "PowerCycleError"=0
                                "CurrentOwner"=""
                                "HomeOwner"=""
                                "ReservationOwner"=""
                            }
                        }
                        "SHARED\sSTORAGE\sHOSTNAME\s+SYSTEM\sID"
                        {
                            $subprocess = 4
                        }
                    }
                    switch ($subprocess) 
                    {
                        1 
                        {
                            
                            switch -regex ($line) 
                            {
                                "^Slot\:\s+(?<name>\d\w)$"                  
                                {
                                    $Adapter.name = $matches.name
                                    break
                                }
                                "^Description\:\s+(?<Description>.+)"
                                {
                                    $Adapter.Description = $matches.Description;
                                    break
                                }
                                "^Firmware\sRev\:\s+(?<FirmwareRev>.+)"
                                {
                                    $Adapter.FirmwareRev = $matches.FirmwareRev
                                    break
                                }
                                "^FC\sNode\sName\:\s+(?<FCNodeName>.+)"
                                {
                                    $Adapter.FCNodeName = $matches.FCNodeName
                                    break
                                }
                                "^FC\sPacket\sSize\:\s+(?<FCPacketSize>.+)"
                                {
                                    $Adapter.FCPacketSize = $matches.FCPacketSize
                                    break
                                }
                                "^Link\sData\sRate\:\s+(?<LinkDataRate>.+)"
                                {
                                    $Adapter.LinkDataRate = $matches.LinkDataRate
                                    break
                                }
                                "^SRAM\sParity\:\s+(?<SRAMParity>.+)"
                                {
                                    $Adapter.SRAMParity = ConvertTo-Bool $matches.SRAMParity
                                    break
                                }
                                "^External\sGBIC\:\s+(?<ExternalGBIC>.+)"
                                {
                                    $Adapter.ExternalGBIC = ConvertTo-Bool $matches.ExternalGBIC
                                    break
                                }
                                "^State\:\s+(?<State>.+)"
                                {
                                    $Adapter.State = $matches.State
                                    break
                                }
                                "^In\sUse\:\s+(?<InUse>.+)"
                                {
                                    $Adapter.InUse = ConvertTo-Bool $matches.InUse
                                    break
                                }
                                "^Redundant\:\s+(?<Redundant>.+)"
                                {
                                    $Adapter.Redundant = ConvertTo-Bool $matches.Redundant
                                    break
                                }
                                Default 
                                {
                                    if ($Adapter) 
                                    {
                                        $Storage.HostAdapters.Add($Adapter.Name,$Adapter)
                                    }
                                }
                            }
                        }
                        2
                        {
                            switch -regex ($line) 
                            {
                                "^Shelf\sname\:\s+(?<name>.+)"                  
                                {
                                    $Shelf.Name = $matches.name
                                    break
                                }
                                "^Channel\:\s+(?<Channel>.+)"
                                {
                                    $Shelf.Channel = $matches.Channel
                                    break
                                }
                                "^Module\:\s+(?<Module>.+)"
                                {
                                    $Shelf.Module = $matches.Module
                                    break
                                }
                                "Shelf\sid\:\s+(?<ShelfID>.+)"
                                {
                                    $Shelf.ShelfID = $matches.ShelfID
                                    break
                                }
                                "Shelf\sUID\:\s+(?<ShelfUID>.+)"
                                {
                                    $shelf.ShelfUID = $Matches.ShelfUID
                                    break
                                }
                                "Shelf\sS\/N\:\s+(?<ShelfSN>.+)"
                                {
                                    $shelf.ShelfSN = $Matches.ShelfSN
                                    break
                                }
                                "Term\sswitch\:\s+(?<TermSwitch>.+)"
                                {
                                    $Shelf.TermSwitch = $Matches.TermSwitch
                                    break
                                }
                                "Shelf\sstate\:\s+(?<ShelfState>.+)"
                                {
                                    $shelf.ShelfState = $Matches.ShelfState
                                    break
                                }
                                "Module\sstate\:\s+(?<ModuleState>.+)"
                                {
                                    $shelf.ModuleState = $matches.ModuleState
                                    $Storage.shelves += $shelf
                                    break
                                }
                            }  
                        }
                        3
                        {
                            switch -regex ($line) 
                            {
                                "^Disk\:\s+(?<Name>.+)"
                                {
                                    $Disk.name = $matches.name
                                    break
                                }
                                "^Shelf\:\s+(?<shelf>.+)"
                                {
                                    $Disk.shelf = $matches.shelf
                                    break
                                }
                                "^Bay\:\s+(?<Bay>.+)"
                                {
                                    $Disk.Bay = $matches.Bay
                                    break
                                }
                                "^Serial\:\s+(?<SN>.+)"
                                {
                                    $Disk.SN = $matches.SN
                                    break
                                }
                                "^Vendor\:\s+(?<Vendor>.+)"
                                {
                                    $Disk.Vendor = $matches.Vendor
                                    break
                                }
                                "^Model\:\s+(?<Model>.+)"
                                {
                                    $Disk.Model = $matches.Model
                                    break
                                }
                                "^Rev\:\s+(?<Firmware>.+)"
                                {
                                    $Disk.Firmware = $matches.Firmware
                                    break
                                }
                                "^RPM\:\s+(?<RPM>.+)"
                                {
                                    $Disk.RPM = $matches.RPM
                                    break
                                }
                                "^WWN\:\s+(?<WWN>.+)"
                                {
                                    $Disk.WWN = $matches.WWN
                                    break
                                }
                                "^UID\:\s+(?<UID>.+)"
                                {
                                    $Disk.UID = $matches.UID
                                    break
                                }
                                "^Downrev\:\s+(?<DownRev>.+)"
                                {
                                    $Disk.DownRev = $matches.DownRev
                                    break
                                }
                                "^Pri\sPort\:\s+(?<PrimaryPort>.+)"
                                {
                                    $Disk.PrimaryPort = $matches.PrimaryPort
                                    break
                                }
                                "^Sec\sName\:\s+(?<Secondaryname>.+)"
                                {
                                    $Disk.Secondaryname = $matches.Secondaryname
                                    break
                                }
                                "^Sec Port\:\s+(?<SecondaryPort>.+)"
                                {
                                    $Disk.SecondaryPort = $matches.SecondaryPort
                                    break
                                }
                                "^Power-on Hours\:\s+(?<PowerOnHours>.+)"
                                {
                                    $Disk.PowerOnHours = $matches.PowerOnHours
                                    break
                                }
                                "^Blocks read\:\s+(?<BlocksRead>.+)"
                                {
                                    $Disk.BlocksRead = $matches.BlocksRead
                                    break
                                }
                                "^Blocks written\:\s+(?<BlocksWritten>.+)"
                                {
                                    $Disk.BlocksWritten = $matches.BlocksWritten
                                    break
                                }
                                "^Time interval\:\s+(?<TimeInterval>.+)"
                                {
                                    $Disk.TimeInterval = $matches.TimeInterval
                                    break
                                }
                                "^Glist count\:\s+(?<GlistCount>.+)"
                                {
                                    $Disk.GlistCount = $matches.GlistCount
                                    break
                                }
                                "^Scrub last done\:\s+(?<ScrubLastDone>.+)"
                                {
                                    $Disk.ScrubLastDone = $matches.ScrubLastDone
                                    break
                                }
                                "^Scrub count\:\s+(?<ScrubCount>.+)"
                                {
                                    $Disk.ScrubCount = $matches.ScrubCount
                                    break
                                }
                                "^LIP count\:\s+(?<LipCount>.+)"
                                {
                                    $Disk.LipCount = $matches.LipCount
                                    break
                                }
                                "^Dynamically qualified\:\s+(?<DynamicallyQualified>.+)"
                                {
                                    $Disk.DynamicallyQualified = $matches.DynamicallyQualified
                                    break                        
                                }
                                "^Power\scycle\scount\:\s+(?<PowerCycleCount>.+)"
                                {
                                    $Disk.PowerCycleCount = $matches.PowerCycleCount
                                    break
                                }
                                "^Power\scycle\son\serror\:\s+(?<PowerCycleError>.+)"
                                {
                                    $Disk.PowerCycleError = $matches.PowerCycleError
                                    break
                                }
                                "^Current owner\:\s+(?<CurrentOwner>.+)"
                                {
                                    $Disk.CurrentOwner = $matches.CurrentOwner
                                    break
                                }
                                "^Home owner\:\s+(?<HomeOwner>.+)"
                                {
                                    $Disk.HomeOwner = $matches.HomeOwner
                                    break
                                }
                                "^Reservation owner\:\s+(?<ReservationOwner>.+)"
                                {
                                    $Disk.ReservationOwner = $matches.ReservationOwner
                                    break
                                }
                                Default
                                {
                                    if ($Disk) 
                                    {
                                        #merge this data with what we scrapped from sysconfig-r
                                        $Disk.RaidType = $aggrHold[$Disk.Name].RaidType
                                        $Disk.Aggregate = $aggrHold[$Disk.Name].Aggregate
                                        $Disk.DiskType = $aggrHold[$Disk.Name].DiskType
                                        $Disk.UsedMB = $aggrHold[$Disk.Name].UsedMB
                                        $Disk.UsedBlocks = $aggrHold[$Disk.Name].UsedBlocks
                                        $Disk.PhysicalMB = $aggrHold[$Disk.Name].PhysicalMB
                                        $Disk.PhysicalBlocks = $aggrHold[$Disk.Name].PhysicalBlocks
                                        
                                        $Storage.Disks +=$Disk
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Write-output $Storage
    }
}
