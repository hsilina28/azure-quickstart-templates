﻿param
(
    [int] $SQLDataFilesCount = 4,    
    [String] $SQLDataLUNS = "0,1,2",
    [String] $SQLLogLUNS = "3",
    [long] $DataFileSizeMB = 1024,
    [long] $LogSizeMB = 1024,
    [string] $SQLDrive = "S:",
    [string] $LogDrive = "L:"
)

$ErrorActionPreference = "Stop";

function Log
{
	param
	(
		[string] $message
	)
	$message = (Get-Date).ToString() + ": " + $message;
	Write-Host $message;
	if (-not (Test-Path ("c:" + [char]92 + "sapcd")))
	{
		$nul = mkdir ("c:" + [char]92 + "sapcd");
	}
	$message | Out-File -Append -FilePath ("c:" + [char]92 + "sapcd" + [char]92 + "log.txt");
}

function Create-Pool
{
    param
    (
        $arraystring,
        $name,
        $path
    )

    Log ("Creating volume for " + $arraystring);
    $luns = $arraystring.Split(",");
    if ($luns.Length -gt 1)
    {
        $count = 0;
        $disks = @();
        foreach ($lun in $luns)
        {
			Log ("Preparing LUN " + $lun);
            $disk = Get-WmiObject Win32_DiskDrive | where InterfaceType -eq SCSI | where SCSILogicalUnit -eq $lun | % { Get-Disk -Number $_.Index } | select -First 1;
            $disk | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue;
            $disks += Get-PhysicalDisk -UniqueId $disk.UniqueId;
            $count++;
        }
        $subsystem = Get-StorageSubSystem;
        Log "Creating Pool";
        New-StoragePool -FriendlyName $name -StorageSubsystemFriendlyName $subsystem.FriendlyName -PhysicalDisks $disks -ResiliencySettingNameDefault Simple -ProvisioningTypeDefault Fixed;
        Log "Creating volume";
        New-Volume -StoragePoolFriendlyName $name -FriendlyName $name -PhysicalDiskRedundancy 0 -FileSystem NTFS -Size ($count * 1020GB) -AccessPath $path;
    }
    else
    {		
        $lun = $luns[0];
		Log ("Creating volume for disk " + $lun);
        $disk = Get-WmiObject Win32_DiskDrive | where InterfaceType -eq SCSI | where SCSILogicalUnit -eq $lun | % { Get-Disk -Number $_.Index } | select -First 1;
        $partition = $disk | Initialize-Disk -PartitionStyle MBR -ErrorAction SilentlyContinue -PassThru | New-Partition -DriveLetter $path.Substring(0,1) -UseMaximumSize;
		sleep 10;
		$partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $name -Confirm:$false;
    }
}

Create-Pool -arraystring $SQLDataLUNS -name "dbdata" -path $SQLDrive;
Create-Pool -arraystring $SQLLogLUNS -name "dblog" -path $LogDrive;