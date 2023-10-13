<#
.SYNOPSIS
    module created by ConvertTo-Module
    ran against folder [C:\github\externalScripts\security]

.NOTES
    CREATE DATE:    2023-10-03
    CREATE AUTHOR:  nnoonan
    REV NOTES:
        v1.0: 2023-10-03 / nnoonan
        * Created module
        * Added Test-RegistryValue
        * Added Update-RegistryValue
        * Added Disable-InsecureClientProtocols
        * Added Test-InsecureClientProtocols
#>
function Test-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Name,

        [parameter(Mandatory = $true)]
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

function Update-RegistryValue {

    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Name,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]$Exists
    )

    try {
        if ($Exists -eq 2) {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType "DWord" -ErrorAction Stop
            Write-Host "$Path\$Name has been created"
        }
        elseif ($Exists -eq 1) {
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

function Disable-InsecureClientProtocols {
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

    $results = @()
    foreach ($Path in $Paths) {
        # create path if needed
        $PathExists = Test-Path -Path $Path
        if ($PathExists -eq $False) {
            New-Item -Path $Path
        }
        # disable each client protocol in the list
        if ($Path -match ".*Client$") {
            # set default to disabled
            $Test = $null
            $Name = "DisabledByDefault"
            $Value = 1
            $Test = Test-RegistryValue -Path $Path -Name $Name -Value $Value
            $results += Update-RegistryValue -Exists $Test -Path $Path -Name $Name -Value $Value

            # explicitly set to disabled
            $Test = $null
            $Name = "Enabled"
            $Value = 0
            $Test = Test-RegistryValue -Path $Path -Name $Name -Value $Value
            $results += Update-RegistryValue -Exists $Test -Path $Path -Name $Name -Value $Value
        }
    }
    if ($results.contains($false)) {
        return $false
    }
    else {
        return $true
    }
}
#Export-ModuleMember -Function Disable-InsecureClientProtocols

function Test-InsecureClientProtocols {
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
    }
    else {
        return $true
    }
}
#Export-ModuleMember -Function Test-InsecureClientProtocols

