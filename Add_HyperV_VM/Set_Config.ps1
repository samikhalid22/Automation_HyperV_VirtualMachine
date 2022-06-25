# Author: Sami Ullah Khalid
# Date: 2022-06-01
# Version: 1.0

$ipAddress = $args[0]
$subnetMask = $args[1]
$defaultGateway = $args[2]
$dnsServer = $args[3]
$vmName = $args[4]
$vmPort = $args[5]
$vmType = $args[6]

try {
    " "
    Write-Host "#### Step 1: Disable windows update service ####" -ForegroundColor Yellow
    " "
    "-> Windows update service status"
    get-service -DisplayName "Windows Update"

    " "
    "-> Stopping service"
    stop-service -DisplayName "Windows Update"

    " "
    "-> Disabling service"
    get-service -DisplayName "Windows Update" | Set-Service -StartupType "Disabled"

    " "
    "-> Windows update service status"
    get-service -DisplayName "Windows Update"

    " "
    Write-Host "#### Step 2: Disable IPV6 ####" -ForegroundColor Yellow
    " "
    "-> IPV6 Status"
    Get-NetAdapterBinding | Where-Object ComponentID -EQ 'ms_tcpip6'

    " "
    "-> Disabled IPV6"
    $interfaceAlias = Get-NetAdapterBinding | Where-Object ComponentID -EQ 'ms_tcpip6'
    Disable-NetAdapterBinding -Name $interfaceAlias.Name -ComponentID 'ms_tcpip6'

    " "
    "-> IPV6 Status"
    Get-NetAdapterBinding | Where-Object ComponentID -EQ 'ms_tcpip6'

    " "
    Write-Host "#### Step 3: Set static IP ####" -ForegroundColor Yellow
    " "
    "-> Network IP Configuration Status"
    Get-NetIPConfiguration

    " "
    "-> Setting New Network IP Address"
    New-NetIPAddress -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $defaultGateway -InterfaceIndex (Get-NetAdapter).InterfaceIndex

    " "
    "-> Setting DNS Client-Server Address"
    Set-DnsClientServerAddress -ServerAddresses $dnsServer -InterfaceIndex (Get-NetAdapter).InterfaceIndex

    " "
    "-> Network IP Configuration Status"
    Get-NetIPConfiguration

    " "
    "-> Testing Network: Ping 8.8.8.8"
    ping 8.8.8.8

    " "
    Write-Host "#### Step 4: Change computer name (Restart Required) ####" -ForegroundColor Yellow
    Rename-Computer -NewName $vmName

    " "
    Write-Host "#### Step 5: Configuring Firewall (Restart Required) ####" -ForegroundColor Yellow
    netsh advfirewall firewall add rule name="Open$vmPort" dir=out action=allow protocol=TCP localport=$vmPort
    netsh advfirewall firewall add rule name="Open$vmPort" dir=in action=allow protocol=TCP localport=$vmPort
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value $vmPort

    if (!$vmType.Equals("win10")) {
        " "
        Write-Host "#### Step 6: Executing slmgr /rearm (Restart Required) ####" -ForegroundColor Yellow
        slmgr /rearm
    }

    Start-Sleep -Seconds 3

    if ($vmType.Equals("win10")) {
        " "
        Write-Host "#### Step 6: Restarting VM ####" -BackgroundColor Blue
    }
    else {
        <# Action when all if and elseif conditions are false #>
        " "
        Write-Host "#### Step 7: Restarting VM ####" -BackgroundColor Blue
    }
    Restart-Computer -Force
}
catch {
    <#Do this if a terminating exception happens#>
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
	exit 1
}
finally {
    <#Do this after the try block regardless of whether an exception occurred or not#>
}
exit 0