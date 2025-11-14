Write-Host "Getting list of active adapters..." -ForegroundColor Yellow
$allAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

$server = Read-Host -Prompt "Enter destination domain or ServerName"

Write-Host "Testing remote connection..." -ForegroundColor Yellow
$serverConn = Test-NetConnection $server

Write-Host "Determining default adapter..." -ForegroundColor Yellow
$defaultAdapter = $allAdapters | Where-Object {$_.Name -eq $serverConn.InterfaceAlias}

# Get DHCP server info using WMI
Write-Host "Getting physical adapter info..." -ForegroundColor Yellow
$allWMI = Get-WmiObject -Class Win32_NetworkAdapterConfiguration
$wmi = $allWMI | Where-Object {$_.InterfaceIndex -eq $defaultAdapter.InterfaceIndex -and $_.DHCPEnabled}

# Get IP configuration for that adapter
Write-Host "Getting IP configuration..." -ForegroundColor Yellow
$allIPConfig = Get-NetIPConfiguration 
$ipConfig = $allIPConfig | Where-Object { $_.InterfaceIndex -eq $defaultAdapter.InterfaceIndex }



# === Build main output ===

$headerInfo = [PSCustomObject]@{
    Hostname         = $env:COMPUTERNAME
    DestinationName  = $server
    ResolvedServerIP = $serverConn.RemoteAddress
    Timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

if ($defaultAdapter.Virtual -eq $true) {
    $vpnAdapter = $defaultAdapter
    $physAdapters = $allAdapters | Where-Object { $_.Virtual -eq $false -and $_.Status -eq "Up"}
    
    # Check if there are multiple active physical adapters
    if ($physAdapters.Count -gt 1) {
        $i = 0 # Loop counter
        $adaptersInfo = $physAdapters | Select-Object -Property Name, InterfaceDescription, MacAddress, Status
        Write-Host "Multiple physical network adapters active:`n" -ForegroundColor Yellow
        foreach ($physAdapter in $adaptersInfo) {
            $i++
            Write-Host "[#$i]" -ForegroundColor Yellow
            Write-Output $physAdapter | Format-List
        }
        # Ask user to choose correct phys adapter
        $adapterIndex = [int](Read-Host -Prompt "Enter the correct adapter's #")
        $physAdapter = $physAdapters[$adapterIndex]
    }
    else {
        $physAdapter = $physAdapters
    }

    $physIPConfig = $allIPConfig | Where-Object { $_.InterfaceIndex -eq $physAdapter.InterfaceIndex }
    $physWMI = $allWMI | Where-Object {$_.InterfaceIndex -eq $physAdapter.InterfaceIndex -and $_.DHCPEnabled}

    # Set VPN and phys info
    $vpnInfo = [PSCustomObject]@{
        InterfaceAlias  = $defaultAdapter.InterfaceAlias
        InterfaceDesc   = $defaultAdapter.InterfaceDescription
        MACAddress      = $defaultAdapter.MACAddress
        Status          = $defaultAdapter.Status
        IPv4Address     = $ipConfig.IPv4Address.IPAddress
        DefaultGateway  = $ipConfig.IPv4DefaultGateway.NextHop
        DNSServers      = ($ipConfig.DnsServer.ServerAddresses -join ", ")
    }
    $physInfo = [PSCustomObject]@{
        InterfaceAlias  = $physAdapter.InterfaceAlias
        InterfaceDesc   = $physAdapter.InterfaceDescription
        MACAddress      = $physAdapter.MACAddress
        Status          = $physAdapter.Status
        IPv4Address     = $physIPConfig.IPv4Address.IPAddress
        DHCPEnabled     = $physWMI.DHCPEnabled
        DHCPServer      = $physWMI.DHCPServer
        DefaultGateway  = $physIPConfig.IPv4DefaultGateway.NextHop
        DNSServers      = ($physIPConfig.DnsServer.ServerAddresses -join ", ")
    }

    # Write VPN + phys info
    Write-Host `n`n
    Write-Host ($headerInfo | Format-List | Out-String).Trim()
    Write-Host `n`n"--- VPN Adapter Information ---"`n
    Write-Host ($vpnInfo | Format-List | Out-String).Trim()
    Write-Host `n`n"--- Physical Adapter Information ---"`n
    Write-Host ($physInfo | Format-List | Out-String).Trim()
}
else {
    # Set phys info
    $mainInfo = [PSCustomObject]@{
        InterfaceAlias    = $defaultAdapter.InterfaceAlias
        InterfaceDesc     = $defaultAdapter.InterfaceDescription
        MACAddress        = $defaultAdapter.MACAddress
        Status            = $defaultAdapter.Status
        IPv4Address       = $ipConfig.IPv4Address.IPAddress
        DHCPEnabled       = $wmi.DHCPEnabled
        DHCPServer        = $wmi.DHCPServer
        DefaultGateway    = $ipConfig.IPv4DefaultGateway.NextHop
        DNSServers        = ($ipConfig.DnsServer.ServerAddresses -join ", ")
    }

    # Write phys info
    Write-Host `n`n
    Write-Host ($headerInfo | Format-List | Out-String).Trim()
    Write-Host `n`n"--- Adapter Information ---"`n
    Write-Host ($mainInfo | Format-List | Out-String).Trim()
}

Write-Host `n
# Ping the server
Test-Connection -ComputerName $server
Write-Host `n
$exit = Read-Host -Prompt "Hit 'Enter' to exit..."
if ($exit) {
    exit
}