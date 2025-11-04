# selecting VM and export
$exportVM = Get-VM | Out-GridView -Title "Select VM" -OutputMode Single |
 select VMname

try{
 $exportVM = $exportVM.VMName.ToString()
 Export-VM -VMName $exportVM -Path C:\ProgramData\Microsoft\Windows\Hyper-V\export -ErrorAction Stop
    }
catch{
 Write-Output "No VM selected or export directory exists already."
 Exit 1
 }

# path to .vcmx of exported VM
$vmcx = Get-ChildItem (Join-Path C:\ProgramData\Microsoft\Windows\Hyper-V\export\ "$exportVM\Virtual Machines\*.vmcx") |
select FullName


$DestDir = "C:\ProgramData\Microsoft\Windows\Hyper-V"

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
    Remove-Item -Recurse -Force -Path C:\ProgramData\Microsoft\Windows\Hyper-V\export\$($exportVM)
    }