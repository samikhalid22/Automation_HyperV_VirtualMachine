<#
    .SYNOPSIS
        Configure virtual machine settings, such as: AD user password and network settingsa
         
    .DESCRIPTION
        Following configurations are set using this script.
        1. Set static IPV4. (IP address, default gateway, DNS Server)
        2. Update user password (Restart Required)
        3. Restarts VM
         
    .PARAMETER ipAddress
        The IP adress for the virtual machine
         
    .PARAMETER defaultGateway
        The default gateway for the virtual machine

    .PARAMETER vmPassword
        The new password assigned to the virtual machine
    
    .PARAMETER dnsServer
        The static dns server
    
    .PARAMETER subnetMask
        The number of subnet mask number
    
    .PARAMETER vmDefaultUsername
        The default username of the VM
         
    .EXAMPLE
        PS C:\> .\Set_Config_AX.ps1 -ipAddress "192.168.1.3" -defaultGateway "192.168.1.1" -vmPassword "pass@word1" -dnsServer "8.8.8.8" -subnetMask 24 -vmDefaultUsername "AX_Dev"

        This will configure VM with the provided settings 
        1. IP address "192.168.1.3" 
        2. Default Gateway "192.168.1.1" 
        3. Subnet mask = 24
        4. DNS Server = "8.8.8.8"
        5. VM password = "pass@word1"
         
    .NOTES
        Author: Sami Ullah Khalid (@samikhalid22)
        Date: 2022-06-01
        Version: 1.0
#>

# Named parameters for CLI argument parsing
param($ipAddress, $defaultGateway, $vmPassword, $dnsServer, $subnetMask, $vmDefaultUsername)

try {
    " "
    Write-Host "#### Step 1: Set static IP ####" -ForegroundColor Yellow
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
    Write-Host "#### Step 2: Update User Password (Restart Required) ####" -BackgroundColor Blue
    Set-ADAccountPassword -Identity $vmDefaultUsername -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $vmPassword -Force)

    " "
    Write-Host "#### Step 3: Restarting VM ####" -BackgroundColor Blue
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