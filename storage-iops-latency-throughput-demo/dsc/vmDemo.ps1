Configuration vmDemo
{

Param(
	[string]$NodeName = 'localhost'
)

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Import-DscResource -Module cChoco
Import-DscResource -Module xStorage,xPSDesiredStateConfiguration

Node $NodeName 
	{
		LocalConfigurationManager
			{
				DebugMode = 'ForceModuleImport'

			}
		cChocoInstaller installChoco
			{
				InstallDir = "c:\choco"
			}
		cChocoPackageInstaller installIometer
			{
				Name        = "iometer"
				DependsOn   = "[cChocoInstaller]installChoco"
				AutoUpgrade = $True
			}
		xWaitforDisk Disk2
			{
				DiskNumber = 2
				RetryIntervalSec = 60
				RetryCount = 60
			} 
		xWaitforDisk Disk3
			{
				DiskNumber = 3
				RetryIntervalSec = 60
				RetryCount = 60
			} 
		xWaitforDisk Disk4
			{
				DiskNumber = 4
				RetryIntervalSec = 60
				RetryCount = 60
			} 
		xWaitforDisk Disk5
			{
				DiskNumber = 5
				RetryIntervalSec = 60
				RetryCount = 60
			} 
		xDisk MVolume
			{
				DiskNumber = 2
				DriveLetter = 'M'
				FSLabel = 'NoCache'
				FSFormat = 'NTFS'
			}
		xDisk NVolume
			{
				DiskNumber = 3
				DriveLetter = 'N'
				FSLabel = 'ReadCache'
				FSFormat = 'NTFS'
			}
		xDisk OVolume
			{
				DiskNumber = 4
				DriveLetter = 'O'
				FSLabel = 'RWCache'
				FSFormat = 'NTFS'
			}
		xDisk PVolume
			{
				DiskNumber = 5
				DriveLetter = 'P'
				FSLabel = 'SSD'
				FSFormat = 'NTFS'
			}
		File DirectoryCreate
			{
				Ensure = "Present"
				Type = "Directory"
				DestinationPath = "C:\iometerTests"    
			}
		xRemoteFile DownloadTests
			{
				DestinationPath = "C:\iometerTests\iometerTests.zip"
				Uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/storage-iops-latency-throughput-demo/dsc/vmDemo.zip"
				DependsOn = "[File]DirectoryCreate"
			}
		xArchive ExpandArchive
			{
				Path = "C:\iometerTests\iometerTests.zip"
				Destination = "C:\iometerTests"
				DependsOn = "[xRemoteFile]DownloadTests"
			}
	}

}
vmDemo
