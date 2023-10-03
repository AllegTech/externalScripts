<#
.SYNOPSIS
    Checks registry values to determine if insecure client protocols are enabled.

.NOTES
    CREATE DATE:    2023-10-02
    CREATE AUTHOR:  Nick Noonan
    REV NOTES:
        v1.0: 2023-10-02 / Nick Noonan
        * Created script
#>
Function Test-RegistryValue {

    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Name,

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    $ItemProperty = "DoesNotExist"
    try {
        $ItemProperty = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Name -ErrorAction Stop
        if ($ItemProperty -eq "DoesNotExist") {
            # key does not exist, needs to be created
            return 2
        }
        elseif (($ItemProperty -ne $Value)) {
            # key exists, but does not match desired value
            return 1
        }
        else {
            # key exists and matches desired value
            return 0
        }
    } 
    catch {
        return 2
    }
}

$Paths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client", 
    "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
)

$results = @()
foreach ($Path in $Paths) {
    # set default to disabled
    $Name = "DisabledByDefault"
    $Value = 1
    $results += Test-RegistryValue -Path $Path -Name $Name -Value $Value

    # explicitly set to disabled
    $Name = "Enabled"
    $Value = 0
    $results += Test-RegistryValue -Path $Path -Name $Name -Value $Value
}

if (($results.contains(1) -or ($results.contains(2)))) {
    return $false
} else {
    return $true
}
