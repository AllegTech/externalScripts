# $url = https://raw.githubusercontent.com/AllegTech/externalScripts/main/ExampleScript.ps1
# ExampleCommand iex (Invoke-WebRequest $url).content
get-service | ft

# here is how you would handle a script
if ([Net.SecurityProtocolType]::Tls) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls
}
if ([Net.SecurityProtocolType]::Tls11) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls11
}
if ([Net.SecurityProtocolType]::Tls12) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
if ([Net.SecurityProtocolType]::Tls13) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
}
$moduleUrl = "https://raw.githubusercontent.com/AllegTech/externalScripts/main/security/InsecureClientProtocols.psm1"
(new-object Net.WebClient).DownloadString($moduleUrl) | Invoke-Expression
Test-InsecureClientProtocols