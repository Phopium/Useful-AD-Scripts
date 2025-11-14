
#Creates new CSV if non exists
if(-not(Test-Path "$PSScriptRoot\NewInventory.csv")){
    new-item "$PSScriptRoot\NewInventory.csv" -ItemType File -Force
}

#Getting info
$PCInfo              = Get-ComputerInfo
$ModelName, $ModelNo = $PCInfo.CsModel.Split(' ')
$WiFiMacDash         = Get-NetAdapter -Name "*Wi-Fi*"
$EthernetDash        = Get-NetAdapter -Name "Ethernet"
$WiFiMac             = $WiFiMacDash.MacAddress.Replace("-", ":")
$EthernetMac         = $EthernetDash.MacAddress.Replace("-", ":")
$AssetTagNum         = Read-Host "Enter physical asset tag #"


#Intune ID
$LogLine = Select-String -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Pattern 'SendWebRequest, client-request-id' -list
if ($LogLine -match "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}") {
    
}
$IntuneID = $Matches[0]

#AAD ID regex parsing nonsense
$AADID       = [ordered]@{}
dsregcmd /status | ForEach-Object {
    $Line = $_
    if ($line -match "^\s*(?<key>\S.*?\S)\s+:\s+(?<val>\S.*\S)\s*$") {
        $AADID[$($Matches.key -replace "\s+",'')] = $($Matches.val)
    }
}

#PSObject for CSV export
$PCExport = [PSCustomObject]@{
    'Asset Tag'            = "$($AssetTagNum)-$($PCInfo.BiosSeralNumber)"
    'Asset Name'           = $PCInfo.CsName
    'Serial Number'        = $PCInfo.BiosSeralNumber
    'Model Name'           = $ModelName
    'Model No.'            = $ModelNo
    Location               = "Yreka"
    Company                = "Pfeiffer"
    OS                     = "Windows 11"
    'WiFi MAC Address'     = $WiFiMAC
    'Ethernet MAC Address' = $EthernetMac
    RealmJoin              = "https://portal.realmjoin.com/devices/$($AADID.DeviceId)"
    Intune                 = "https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId/$($IntuneID)"
    Status                 = "Pending"
    Import                 = "Waiting"

}

#Exporting
try{
    $PCExport |
    export-csv "$PSScriptRoot\NewInventory.csv" -NoTypeInformation -Append -ErrorAction Stop
}
catch{
    $Error[0].exception.message
    pause
}