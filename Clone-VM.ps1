# selecting VM and export
$exportVM = Get-VM | Out-GridView -Title "Select VM" -OutputMode Single |
 select VMname

try{
 $exportVM = $exportVM.VMName.ToString()
 Export-VM -VMName $exportVM -Path $env:USERPROFILE -ErrorAction Stop
    }
catch{
 Write-Output "No VM selected or export directory does not exist."
 Exit 1
 }

# path to .vcmx of exported VM
$vmcx = Get-ChildItem (Join-Path $env:USERPROFILE "$exportVM\Virtual Machines\*.vmcx") |
select FullName

Add-Type -AssemblyName System.Windows.Forms
$FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderDialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
$FolderDialog.Description = "Target directory for cloned VM"
$Result = $FolderDialog.ShowDialog()

if($FolderDialog.SelectedPath -eq ""){
 Write-Output "No path selected."
 exit -1
 }

$DestDir = $FolderDialog.SelectedPath

# import VM and renaming
do{
 $NewName = Read-Host "Name of cloned VM? "
 try{
  New-Item -ItemType Directory -Path $DestDir -Name $NewName -ErrorAction Stop
    }
 catch{
  Write-Output "Directory already exist."
  exit 1
  }

 $impVM = Import-VM -Copy -Path $vmcx.FullName `
  -VhdDestinationPath (Join-Path $DestDir "$newName\Virtual Hard Disks") `
  -VirtualMachinePath (Join-Path $DestDir "$newName\Virtual Machines") `
  -SnapshotFilePath (Join-Path $DestDir "$newName\Snapshots") `
  -GenerateNewId

 Rename-VM -VM $impVM -NewName $NewName
}
while((Read-Host -Prompt "Create another clone? (y/n)") -eq "y")

# Exportierte VM löschen
if((Read-Host -Prompt "Remove exported VM? (y/n)") -eq "y"){
    Remove-Item -Recurse -Force -Path $env:USERPROFILE\$($exportVM)
    }