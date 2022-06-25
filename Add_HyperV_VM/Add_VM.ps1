# Author: Sami Ullah Khalid
# Date: 2022-06-01
# Version: 1.0

# Named parameters for CLI argument parsing (22)
param(
    [String] $defaultVMName,
    [String] $vmName, 
    [string] $vmType, 
    [Int64] $vmMem, 
    [Int32] $cpuCount, 
    [String] $vhdFileName, 
    [String] $vmSwitch, 
    [String] $srcDirPath, 
    [String] $destDirPath, 
    [Int32] $threadCount,
    [String] $serverName, 
    [String] $vmDefaultUsername, 
    [String] $vmDefaultPassword, 
    [String] $ipAddress, 
    [String] $defaultGateway, 
    [String] $dnsServer, 
    [Int32] $subnetMask,  
    [String] $vmPort, 
    [String] $ownerName, 
    [String] $createdBy, 
    [String] $department, 
    [String] $supervisorName
    )

# Store start time
$startTime = Get-Date

# Default directory path of scripts
$defaultScriptsDirPath = "C:\Add_HyperV_VM"

# Default directory path of VM details file
$defaultVMDetailsFilePath = "$destDirPath$destDirName"

# Check if source directory and VHD file exists
if (!(Test-Path -Path "$srcDirPath\$vhdFileName")) {
    <# Action to perform if the condition is true #>
    " "
    Write-Host "---- Source Directory/VHD Does Not Exist: $srcDirPath\$vhdFileName ----" -ForegroundColor Red
    Write-Host "---- Terminating Execution ----" -ForegroundColor Red
    exit 1
}

# Check if destination directory exists
if (Test-Path -Path "$destDirPath$destDirName") {
    " "
    Write-Host "---- Destination Directory Exists: $destDirPath$destDirName ----" -ForegroundColor Red
    Write-Host "---- Terminating Execution ----" -ForegroundColor Red
    exit 1
}

# Check if virtual switch exists
$item = (Get-VMSwitch -ComputerName $serverName | Where-Object -Property Name -EQ -Value $vmSwitch).count
if (!($item -eq '1'))
{
    " "
    Write-Host "---- Virtual Switch Does Not Exist: $vmSwitch ----" -ForegroundColor Red
    Write-Host "---- Terminating Execution ----" -ForegroundColor Red
    exit 1
}

# Check thread count is with in operational range
if (!($threadCount -In 1..128))
{
    " "
    Write-Host "---- Number of Threads Must BE 1 - 128 ----" -ForegroundColor Red
    Write-Host "---- Terminating Execution ----" -ForegroundColor Red
    exit 1
}

# Generate new password
function Get-RandomPassword {
    param ([Parameter(Mandatory)] [int] $length, [int] $amountOfNonAlphanumeric = 1)
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

# New password for VM Default User
$newPassword = Get-RandomPassword 24

try {
    # Create a new directory
    " "
    Write-Host "---- Creating directory: $vmName ----" -BackgroundColor Blue
    New-Item -Path "$destDirPath" -Name $vmName -ItemType "directory"

    # Code blocks for different VM types (ax, d365, win10)
    switch ($vmType) {
        "ax" {
            # Get .vmcx file name from exported VM data
            " "
            Write-Host "---- Fetching VM import data file ----" -BackgroundColor Blue
            $vmConfigFile = Get-ChildItem -Path "$srcDirPath\Virtual Machines\*" -Include *.vmcx
            $vmConfigFileName = $vmConfigFile.Name

            # Import VM to destination directory
            " "
            Write-Host "---- Importing VM ----" -BackgroundColor Blue
            Import-VM -ComputerName $serverName -Path "$srcDirPath\Virtual Machines\$vmConfigFileName" -VhdDestinationPath "$destDirPath$destDirName\Virtual Hard Disks" -VirtualMachinePath "$destDirPath$destDirName" -SnapshotFilePath "$destDirPath$destDirName" -SmartPagingFilePath "$destDirPath$destDirName" -GenerateNewId -Copy
            
            # Add VM network adapter and switch
            " "
            Write-Host "---- Connecting network adapter and switch ----" -BackgroundColor Blue
            Get-VMNetworkAdapter -VMName $defaultVMName | Connect-VMNetworkAdapter -SwitchName $vmSwitch

            # Rename VM
            Rename-VM -ComputerName $serverName -Name $defaultVMName -NewName $vmName

            # Starts virtual machine
            " "
            Write-Host "---- Starting VM: $vmName ----" -BackgroundColor Blue
            Start-VM -Name $vmName

            # Wait for VM to start
            " "
            Write-Host "---- Waiting for VM to Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 110

            # Copy config file to VM
            " "
            Write-Host "---- Transferring config file in to VM ----" -BackgroundColor Blue
            $vmNameObj = (Get-VM -Name $vmName).Name
            Copy-VMFile -ComputerName $serverName -Name $vmNameObj -SourcePath "$defaultScriptsDirPath\Set_Config_AX.ps1" -DestinationPath "C:\" -FileSource Host -CreateFullPath -Force

            " "
            Write-Host "---- VM Created ----" -ForegroundColor Green
            Write-Host "-> Check execution log for any issues" -ForegroundColor Yellow
        
            # Opens a connection window to the VM
            " "
            Write-Host "---- Opening VM Connect window ----" -BackgroundColor Blue
            VMConnect.exe $serverName $vmName

            # Store end time
            $endTime = Get-Date
            
            # Get total execution time of script
            $scriptExeTime = New-TimeSpan -Start $startTime -End $endTime
            
            # Output Details of Created VM to file
            " "
            Write-Host "---- Adding VM Details to File: VM_DETAILS.txt ----" -BackgroundColor Blue
            if (!(Test-Path -Path "$defaultVMDetailsFilePath\VM_DETAILS.txt")) {
                New-Item "$defaultVMDetailsFilePath\VM_DETAILS.txt"
            }

            $vmDetailsText = @"
OWNER_NAME: $ownerName
DEPARTMENT: $department
SUPERVISOR: $supervisorName

VM_NAME: $vmName
USERNAME: $vmDefaultUsername
PASSWORD: $newPassword
IP: $ipAddress
DEFAULT_GATEWAY: $defaultGateway
PORT: $vmPort
Script_Start_Time: $startTime
Script_End_Time: $endTime
Script_Exe_Time: $scriptExeTime

CREATED_BY: $createdBy
----------
cd C:\
.\Set_Config_AX.ps1 -ipAddress "$ipAddress" -defaultGateway "$defaultGateway" -vmPassword "$newPassword" -dnsServer "$dnsServer" -subnetMask $subnetMask -vmDefaultUsername "$vmDefaultUsername"
"@

            Add-Content "$defaultVMDetailsFilePath\VM_DETAILS.txt" "$vmDetailsText"

            # Adding notes for created VM in HyperV manager
            Write-Host "---- Adding VM Details to HyperV Notes ----" -BackgroundColor Blue
            Set-VM -ComputerName $serverName -Name $vmName -Notes "$vmDetailsText"

            # Display password
            " "
            Write-Host "---- New Password: $newPassword ----" -ForegroundColor Green

            # Show execution time
            " "
            Write-Host "---- Script Execution Time (HH:MM:SS.S) ----" -BackgroundColor Blue
            $scriptExeTime
        }
        "d365" {
            # PowerShell credential object
            $password = ConvertTo-SecureString "$vmDefaultPassword" -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ("$serverName\$vmDefaultUsername", $password)

            # Copy source directory content to destination directory
            " "
            Write-Host "---- Copying file(s): $vhdFileName ----" -BackgroundColor Blue
            robocopy "$srcDirPath" "$destDirPath$destDirName" "$vhdFileName" /MT:$threadCount /bytes /j

            # Creates a new virtual machine
            " "
            Write-Host "---- Creating New VM: $vmName ----" -BackgroundColor Blue
            New-VM -Name $vmName -MemoryStartupBytes $vmMem -BootDevice VHD -VHDPath "$destDirPath$destDirName\$vhdFileName" -Path $destDirPath$destDirName -Generation 1 -Switch $vmSwitch
            " "
            Write-Host "---- Created New VM: $vmName ----" -BackgroundColor Blue

            # Configures virtual processors of a virtual machine
            " "
            Write-Host "---- Setting number of processors of VM: $cpuCount ----" -BackgroundColor Blue
            Set-VMProcessor $vmName -Count $cpuCount

            # Starts virtual machine
            " "
            Write-Host "---- Starting VM: $vmName ----" -BackgroundColor Blue
            Start-VM -Name $vmName

            # Wait for VM to start
            " "
            Write-Host "---- Waiting for VM to Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 40

            # Creates a checkpoint after creation of VM
            " "
            Write-Host "---- Creating Checkpoint ----" -BackgroundColor Blue
            Checkpoint-VM -Name $vmName -ComputerName $serverName -SnapshotName AfterCreationCheckPoint
            Start-Sleep -Seconds 5

            # Creates a session object to the VM
            " "
            Write-Host "---- Creating session object for VM: Set_Config.ps1 ----" -BackgroundColor Blue
            $vmSession = New-PSSession -VMName $vmName -credential $cred

            # Executing commands in VM
            " "
            Write-Host "#### Executing script block in VM: PS Execution Policy ####" -BackgroundColor Blue
            Invoke-Command -Session $vmSession -Scriptblock {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
            }

            # Executes script in VM
            " "
            Write-Host "---- Executing configuration script in VM: Set_Config.ps1 ----" -BackgroundColor Blue
            Invoke-Command -FilePath "$defaultScriptsDirPath\Set_Config.ps1" -ArgumentList $ipAddress, $subnetMask, $defaultGateway, $dnsServer, $vmName, $vmPort, $vmType -Session $vmSession
            " "
            Write-Host "---- Execution of configuration script in VM Completed ----" -BackgroundColor Blue

            # Wait for VM to start
            " "
            Write-Host "---- Waiting for VM to Re-Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 40

            # Creates a session object to the VM
            " "
            Write-Host "---- Creating session object for VM: Set_Config_D365.ps1 ----" -BackgroundColor Blue
            $s = New-PSSession -VMName $vmName -credential $cred

            # Executes script in VM
            " "
            Write-Host "---- Executing configuration script in VM: Set_Config_D365.ps1 ----" -BackgroundColor Blue
            Invoke-Command -FilePath "$defaultScriptsDirPath\Set_Config_D365.ps1" -ArgumentList $vmName, $vmDefaultUsername, $newPassword -Session $s
            " "
            Write-Host "---- Execution of configuration script in VM Completed: P2 ----" -BackgroundColor Blue

            " "
            Write-Host "---- Waiting for VM to Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 40

            # Creates a checkpoint after configuration of VM
            Write-Host "---- Creating Checkpoint ----" -BackgroundColor Blue
            Checkpoint-VM -Name $vmName -ComputerName $serverName -SnapshotName AfterConfigurationCheckPoint
        
            " "
            Write-Host "---- VM Created ----" -ForegroundColor Green
            Write-Host "-> Check execution log for any issues" -ForegroundColor Yellow
        
            # Opens a connection window to the VM
            " "
            Write-Host "---- Opening VM Connect window ----" -BackgroundColor Blue
            VMConnect.exe $serverName $vmName

            # Store end time
            $endTime = Get-Date
            
            # Get total execution time of script
            $scriptExeTime = New-TimeSpan -Start $startTime -End $endTime
            
            # Output Details of Created VM to file
            " "
            Write-Host "---- Adding VM Details to File: VM_DETAILS.txt ----" -BackgroundColor Blue
            if (!(Test-Path -Path "$defaultVMDetailsFilePath\VM_DETAILS.txt")) {
                New-Item "$defaultVMDetailsFilePath\VM_DETAILS.txt"
            }

            $vmDetailsText = @"
OWNER_NAME: $ownerName
DEPARTMENT: $department
SUPERVISOR: $supervisorName

VM_NAME: $vmName
USERNAME: $vmDefaultUsername
PASSWORD: $newPassword
IP: $ipAddress
DEFAULT_GATEWAY: $defaultGateway
PORT: $vmPort
Script_Start_Time: $startTime
Script_End_Time: $endTime
Script_Exe_Time: $scriptExeTime

CREATED_BY: $createdBy
----------
"@

            Add-Content "$defaultVMDetailsFilePath\VM_DETAILS.txt" $vmDetailsText

            # Adding notes for created VM in HyperV manager
            Write-Host "---- Adding VM Details to HyperV Notes ----" -BackgroundColor Blue
            Set-VM -ComputerName $serverName -Name $vmName -Notes $vmDetailsText

            # Display password
            " "
            Write-Host "---- New Password: $newPassword ----" -ForegroundColor Green

            # Show execution time
            " "
            Write-Host "---- Script Execution Time (HH:MM:SS.S) ----" -BackgroundColor Blue
            $scriptExeTime
        }
        
        "win10" {
            # PowerShell credential object
            $password = ConvertTo-SecureString "$vmDefaultPassword" -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ("$serverName\$vmDefaultUsername", $password)

            # Copy source directory content to destination directory
            " "
            Write-Host "---- Copying file(s): $vhdFileName ----" -BackgroundColor Blue
            robocopy "$srcDirPath" "$destDirPath$destDirName" "$vhdFileName" /MT:$threadCount /bytes /j

            # Creates a new virtual machine
            " "
            Write-Host "---- Creating New VM: $vmName ----" -BackgroundColor Blue
            New-VM -Name $vmName -MemoryStartupBytes $vmMem -BootDevice VHD -VHDPath "$destDirPath$destDirName\$vhdFileName" -Path $destDirPath$destDirName -Generation 1 -Switch $vmSwitch
            " "
            Write-Host "---- Created New VM: $vmName ----" -BackgroundColor Blue

            # Configures virtual processors of a virtual machine
            " "
            Write-Host "---- Setting number of processors of VM: $cpuCount ----" -BackgroundColor Blue
            Set-VMProcessor $vmName -Count $cpuCount

            # Starts virtual machine
            " "
            Write-Host "---- Starting VM: $vmName ----" -BackgroundColor Blue
            Start-VM -Name $vmName

            # Wait for VM to start
            " "
            Write-Host "---- Waiting for VM to Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 40

            # Creates a checkpoint after creation of VM
            " "
            Write-Host "---- Creating Checkpoint ----" -BackgroundColor Blue
            Checkpoint-VM -Name $vmName -ComputerName $serverName -SnapshotName AfterCreationCheckPoint
            Start-Sleep -Seconds 5

            # Creates a session object to the VM
            " "
            Write-Host "---- Creating session object for VM: Set_Config.ps1 ----" -BackgroundColor Blue
            $vmSession = New-PSSession -VMName $vmName -credential $cred

            # Executing commands in VM
            " "
            Write-Host "#### Executing script block in VM: PS Execution Policy ####" -BackgroundColor Blue
            Invoke-Command -Session $vmSession -Scriptblock {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
            }

            # Executes script in VM
            " "
            Write-Host "---- Executing configuration script in VM: Set_Config.ps1 ----" -BackgroundColor Blue
            Invoke-Command -FilePath "$defaultScriptsDirPath\Set_Config.ps1" -ArgumentList $ipAddress, $subnetMask, $defaultGateway, $dnsServer, $vmName, $vmPort, $vmType -Session $vmSession
            " "
            Write-Host "---- Execution of configuration script in VM Completed ----" -BackgroundColor Blue

            # Wait for VM to start
            " "
            Write-Host "---- Waiting for VM to Re-Start ----" -BackgroundColor Blue
            Start-Sleep -Seconds 40

            # Creates a session object to the VM
            " "
            Write-Host "---- Creating session object for VM: Update User Password ----" -BackgroundColor Blue
            $s = New-PSSession -VMName $vmName -credential $cred

            # Executing commands in VM
            " "
            Write-Host "#### Step 8: Update User Password ####" -BackgroundColor Blue
            Invoke-Command -Session $s -Scriptblock {
                $newPasswordSecureStr = ConvertTo-SecureString $newPassword -AsPlainText -Force
                Set-LocalUser -Name "$vmDefaultUsername" -Password $newPasswordSecureStr
            }

            # Closes the session
            " "
            Write-Host "---- Removing session: Update User Password ----" -BackgroundColor Blue
            Remove-PSSession $s

            # Creates a checkpoint after configuration of VM
            Write-Host "---- Creating Checkpoint ----" -BackgroundColor Blue
            Checkpoint-VM -Name $vmName -ComputerName $serverName -SnapshotName AfterConfigurationCheckPoint
        
            " "
            Write-Host "---- VM Created ----" -ForegroundColor Green
            Write-Host "-> Check execution log for any issues" -ForegroundColor Yellow
        
            # Opens a connection window to the VM
            " "
            Write-Host "---- Opening VM Connect window ----" -BackgroundColor Blue
            VMConnect.exe $serverName $vmName

            # Store end time
            $endTime = Get-Date
            
            # Get total execution time of script
            $scriptExeTime = New-TimeSpan -Start $startTime -End $endTime
            
            # Output Details of Created VM to file
            " "
            Write-Host "---- Adding VM Details to File: VM_DETAILS.txt ----" -BackgroundColor Blue
            if (!(Test-Path -Path "$defaultVMDetailsFilePath\VM_DETAILS.txt")) {
                New-Item "$defaultVMDetailsFilePath\VM_DETAILS.txt"
            }

            $vmDetailsText = @"
OWNER_NAME: $ownerName
DEPARTMENT: $department
SUPERVISOR: $supervisorName

VM_NAME: $vmName
USERNAME: $vmDefaultUsername
PASSWORD: $newPassword
IP: $ipAddress
DEFAULT_GATEWAY: $defaultGateway
PORT: $vmPort
Script_Start_Time: $startTime
Script_End_Time: $endTime
Script_Exe_Time: $scriptExeTime

CREATED_BY: $createdBy
----------
"@

            Add-Content "$defaultVMDetailsFilePath\VM_DETAILS.txt" $vmDetailsText

            # Adding notes for created VM in HyperV manager
            Write-Host "---- Adding VM Details to HyperV Notes ----" -BackgroundColor Blue
            Set-VM -ComputerName $serverName -Name $vmName -Notes $vmDetailsText

            # Display password
            " "
            Write-Host "---- New Password: $newPassword ----" -ForegroundColor Green

            # Show execution time
            " "
            Write-Host "---- Script Execution Time (HH:MM:SS.S) ----" -BackgroundColor Blue
            $scriptExeTime
        }
        Default {
            # Default execution

        }
    }   
}
catch {
    <#Do this if a terminating exception happens#>

    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    # Store end time
    $endTime = Get-Date
    
    # Get total execution time of script
    $scriptExeTime = New-TimeSpan -Start $startTime -End $endTime

    # Show execution time
    " "
    Write-Host "---- Script Execution Time (HH:MM:SS.S) ----" -BackgroundColor Blue
    $scriptExeTime
	exit 1
}
finally {
    <#Do this after the try block regardless of whether an exception occurred or not#>
}
exit 0