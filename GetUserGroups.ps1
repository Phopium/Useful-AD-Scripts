$upn = "user.name@YourDomain.com"
$server = "YourServer.YourDomain.com"
$groups = Get-ADUser -Filter {UserPrincipalName -eq $UPN} -server $server | Get-ADPrincipalGroupMembership -server $server | Select-Object Name

# Adds ";" after each group for easy pasting back AD
$list = $groups | ForEach-Object { $_.Name + ";" }
Write-Output $list