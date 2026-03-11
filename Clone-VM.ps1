# selecting VM and export
$exportVM = Get-VM | Out-GridView -Title "Select VM" -OutputMode Single | select VMName

try {
 $exportVM = $exportVM.VMName.ToString()
 Export-VM -VMName $exportVM -Path C:\ProgramData\Microsoft\Windows\Hyper-V\export -ErrorAction Stop
}
catch {
 Write-Output "No VM selected or export directory exists already."
 exit 1
}

# path to .vmcx of exported VM
$vmcx = Get-ChildItem (Join-Path "C:\ProgramData\Microsoft\Windows\Hyper-V\export" "$exportVM\Virtual Machines\*.vmcx") |
 select FullName

$DestDir = "C:\ProgramData\Microsoft\Windows\Hyper-V"

# import VM and renaming
do {
 $NewName = Read-Host "Name of cloned VM? "
 $TargetPath = Join-Path $DestDir $NewName

 try {
  New-Item -ItemType Directory -Path $TargetPath -ErrorAction Stop | Out-Null
 }
 catch {
  Write-Output "Directory '$NewName' already exists."
  $answer = Read-Host "Remove existing directory? (y/n)"

  if ($answer -match '^(y|yes)$') {
   try {
    Remove-Item -Path $TargetPath -Recurse -Force -ErrorAction Stop
    Write-Output "Directory removed. Creating new one..."
    New-Item -ItemType Directory -Path $TargetPath -ErrorAction Stop | Out-Null
   }
   catch {
    Write-Output "Failed to remove directory. Aborting."
    exit 1
   }
  }
  else {
   Write-Output "Aborted by user."
   exit 1
  }
 }

 $impVM = Import-VM -Copy -Path $vmcx.FullName `
  -VhdDestinationPath (Join-Path $DestDir "$NewName\Virtual Hard Disks") `
  -VirtualMachinePath (Join-Path $DestDir "$NewName\Virtual Machines") `
  -SnapshotFilePath (Join-Path $DestDir "$NewName\Snapshots") `
  -GenerateNewId

 Rename-VM -VM $impVM -NewName $NewName

} while ((Read-Host -Prompt "Create another clone? (y/n)") -eq "y")

# remove exported VM
if ((Read-Host -Prompt "Remove exported VM? (y/n)") -eq "y") {
 Remove-Item -Recurse -Force -Path "C:\ProgramData\Microsoft\Windows\Hyper-V\export\$exportVM"
}
