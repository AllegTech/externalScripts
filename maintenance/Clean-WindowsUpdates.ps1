Function Start-CleanUp ([string]$FileType, [Array]$Data) {
    $removals = @()
    # Reading list of files from C:\Windows\Installer folder.
    $InstallerFiles = Get-ChildItem "C:\Windows\Installer" "*.$FileType" -File
    foreach ($InstallerFile in $InstallerFiles) {
        # If Windows Installer doesn't have data about exiting file in C:\Windows\Installer folder,
        # we can assume it is not needed and we delete the file.
        If (!($Data | Where-Object { $_ -eq $InstallerFile.FullName })) {
            #write-host "REMOVE: $($InstallerFile.FullName)"
            $removals += $InstallerFile.FullName
            write-host "Removing $($InstallerFile.FullName)"
            Remove-Item -Path $InstallerFile.FullName -force
        }
    }
    return $removals
}

# Initializing arrays
[array]$PatchesLocation = @()
[array]$InstallersLocation = @()

# Finding info about installed programs.
$Installer = New-Object -ComObject "WindowsInstaller.Installer"
$Products = $Installer.Products() 

# Going through products and finding patches related to every product
foreach ($ProductCode in $Products) {
    # Adding path of the .msi files into the array, which we will process later
    $InstallersLocation += $Installer.ProductInfo($ProductCode, "LocalPackage")

    # Find patches which are installed for certain product code
    $Patches = $Installer.Patches($ProductCode)
    foreach ($PatchCode in $Patches) {
        #Adding path of the .msp files into the array, which we will process later
        $PatchesLocation += $Installer.PatchInfo($PatchCode, "LocalPackage") 
    }
}
# Use the function to compare found data with the files in the C:\windows\installer directory

If ( $PatchesLocation.Count -ne 0) {
    $PatchRemoval = Start-CleanUp -FileType "msp" -Data $PatchesLocation 
}
If ( $InstallersLocation.Count -ne 0) {
    $InstallerRemoval = Start-CleanUp -FileType "msi" -Data $InstallersLocation
}

$results = [PSCustomObject]@{
    PatchRemoval     = $PatchRemoval
    InstallerRemoval = $InstallerRemoval
}

return $results