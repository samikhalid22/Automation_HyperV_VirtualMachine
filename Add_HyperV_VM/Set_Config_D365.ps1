# Author: Sami Ullah Khalid
# Date: 2022-06-01
# Version: 1.0

$vmName = $args[0]
$vmDefaultUsername = $args[1]
$newPassword = $args[2]

try {
    " "
    Write-Host "#### Step 8: Configure SSMS ####" -ForegroundColor Yellow
    $sqlServerDefaultHostName = hostname
    $DS = Invoke-Sqlcmd -ServerInstance $sqlServerDefaultHostName -Query "select @@SERVERNAME;" -As DataSet
    $oldName = $DS.Tables[0].Column1
    New-Item C:\tempQuery.sql
    Set-Content C:\tempQuery.sql "sp_dropserver [$oldName];"
    Add-Content C:\tempQuery.sql "GO"
    Add-Content C:\tempQuery.sql "sp_addserver [$vmName], local;"
    Add-Content C:\tempQuery.sql "GO"
    Invoke-Sqlcmd -ServerInstance $sqlServerDefaultHostName -InputFile "C:\tempQuery.sql" | out-null
    Remove-Item -Path C:\tempQuery.sql

    " "
    "-> Current SSMS Server Name: SELECT SERVERPROPERTY('ServerName');"
    Invoke-Sqlcmd -ServerInstance $vmName -Query "SELECT SERVERPROPERTY('ServerName');"

    " "
    "-> Current SSMS Server Name: select @@SERVERNAME;"
    Invoke-Sqlcmd -ServerInstance $vmName -Query "select @@SERVERNAME;"

    " "
    "-> Adding Login"
    Add-SqlLogin -ServerInstance $vmName -LoginName "$vmName\$vmDefaultUsername" -LoginType "WindowsUser" -Enable -GrantConnectSql

    " "
    "-> Assigning Server Role"
    Invoke-Sqlcmd -ServerInstance $vmName -Query "ALTER SERVER ROLE sysadmin ADD MEMBER [$vmName\$vmDefaultUsername];"

    " "
    Write-Host "#### Step 9: Update User Password ####" -BackgroundColor Blue
    $newPasswordSecureStr = ConvertTo-SecureString $newPassword -AsPlainText -Force
    Set-LocalUser -Name "$vmDefaultUsername" -Password $newPasswordSecureStr

    " "
    Write-Host "#### Step 10: Restarting VM ####" -BackgroundColor Blue
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