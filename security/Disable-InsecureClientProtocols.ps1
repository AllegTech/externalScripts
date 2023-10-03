<#
.SYNOPSIS
    Disables insecure client protocols via registry values.

.NOTES
    CREATE DATE:    2023-10-02
    CREATE AUTHOR:  Nick Noonan
    REV NOTES:
        v1.0: 2023-10-02 / Nick Noonan
        * Created script
#>
function Test-RegistryValue {

    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Name,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    write-host "Path: $path"
    write-host "Name: $name"
    write-host "Value: $value"
    $ItemProperty = "DoesNotExist"
    try {
        $ItemProperty = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Name -ErrorAction Stop
        if ($ItemProperty -eq "DoesNotExist") {
            # key does not exist, needs to be created
            write-host "Result: 2"
        }
        elseif (($ItemProperty -ne $Value)) {
            # key exists, but does not match desired value
            write-host "Result: 1"
            return 1
        }
        else {
            # key exists and matches desired value
            write-host "Result: 0"
            return 0
        }
    } 
    catch {
        write-host "Result: catch"
        return 2
    }
}

function Update-RegistryValue {

    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Name,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]$Exists
    )

    try {
        if ($Exists -eq 2) {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType "DWord" -ErrorAction Stop
            Write-Host "$Path\$Name has been created"
        } elseif ($Exists -eq 1) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop
            Write-Host "$Path\$Name has been updated"
        }
        else {
            Write-Host "$Path\$Name needed no changes"
        }
        return $true
    }

    catch {
        return $false
    }
}

$Paths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
)

foreach ($Path in $Paths) {
    # create path if needed
    $PathExists = Test-Path -Path $Path
    if ($PathExists -eq $False) {
        New-Item -Path $Path
    }
    # disable each client protocol in the list
    if ($Path -match ".*Client$") {
        # set default to disabled
        $Exists = $null
        $Name = "DisabledByDefault"
        $Value = 1
        $Test = Test-RegistryValue -Path $Path -Name $Name -Value $Value
        Update-RegistryValue -Exists $Test -Path $Path -Name $Name -Value $Value

        # explicitly set to disabled
        $Exists = $null
        $Name = "Enabled"
        $Value = 0
        $Test = Test-RegistryValue -Path $Path -Name $Name -Value $Value
        Update-RegistryValue -Exists $Test -Path $Path -Name $Name -Value $Value

    }
}
