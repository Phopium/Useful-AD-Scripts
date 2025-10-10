$numberRange = 1..10
$genericName = "kiosk.machine"
$domainName = "your-domain.com"
$adGroupName = "cool_kids_club"

$userList = foreach ($number in $numberRange) {
    $genericName + $number + $domainName
}

Add-ADGroupMember -Identity $adGroupName -Members $userList -WhatIf # "-WhatIf" to test