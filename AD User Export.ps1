if(-not(Test-Path "$PSScriptRoot\ADUsers.csv")){
    new-item "$PSScriptRoot\ADUsers.csv" -ItemType File -Force
}

$Folders = "Your, Structure"
$AdFields = @('givenName','City','EmailAddress')
$Dc    = "YourDcDomain.com"

$AdUsers = foreach ($Folder in $Folders){
    $Ou = "OU=Your,OU=Setup,OU=$Folder,OU=Your,OU=Setup,DC=Your,DC=Structure,DC=com"
    Get-ADUser -server $Dc -Filter "Enabled -eq 'True'" -SearchBase $Ou -Properties $AdFields
}

try{
    $AdUsers |
    export-csv "$PSScriptRoot\$Sitelocations-ADUsers.csv" -NoTypeInformation -Append -ErrorAction Stop
}
catch{
    $Error[0].exception.message
    pause
}