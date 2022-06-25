# Automation_HyperV_VirtualMachine

**Author: Sami Ullah Khalid**

**Date: 2022-06-01**

**Version: 1.0**

---
## Creation of new VM through VHD or HyperV Import and configuring VM through PowerShell

This automation script has been tested on 

| Hypervisor (OS) | PowerShell Version |
| ------------- |:-------------:|
| Windows 10 Enterprise | 5.1.x |
| Windows Server 2016   | 5.1.x |

| Virtual Machine (OS) | PowerShell Version |
| ------------- |:-------------:|
| Windows 11                     | 5.1.x |
| Windows 10                     | 5.1.x |
| Windows Server 2016 Datacenter | 5.1.x |
| Windows Server 2012 R2         | 4.0.x |

---

## General Information

***For Dynamics AX virtual machine a base VM has been configured and exported. Which in turn is used to import i.e. create new virtual machine.***

This script automates the following process:

### For Microsoft Dynamics AX VM

1. Create new directory for Virtual Machine.
2. Import VM
3. Set network adapter virtual switch.
4. Rename VM (Hyper-V)
5. Start VM
6. Transfer config script with in VM.
7. Open Hyper-V connect window of created VM.
8. Output VM Detials and generate commands to be executed within VM, to the file: VM_DETAILS.txt (Located within VM destination directory)
9. Add details and generate commands to be executed within VM, to HyperV manager notes.
10. Configure network settings within VM.
    > After running the config file within VM.

### For Windows 10 Jump Box and Microsoft Dynamics 365 VM 

1. Create new directory for Virtual Machine.
2. Copy VHD file(s) from source directory to destination directory.
   > - Uses multithreading to transfer large files from one local disk to another.
   > - Uses 16 threads. Can increase or decrese for better perfromance.
3. Create Hyper-V Virtual Machine.
4. Configure Hyper-V settings for Virtual Machine:
   - 4.1 Number of virtual processors.
5. Starts Virtual Machine.
6. Create a checkpoint: Before applying configurations within VM.
7. Create session object to perform configurations within Virtual Machine.
   > - Does not apply to Windows Server 2012. (i.e. MSD AX VM)
   > - FYI: https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-windows-virtual-machines-with-powershell-direct
8. Following configurations are performed with session object:
   - 8.1 Set PowerShell Execution Policy.
   - 8.2 Stop windows update service.
   - 8.3 Disable windows update service.
   - 8.4 Disable IPV6.
   - 8.5 Set static IPV4 address.
   - 8.6 Change Virtual Machine computer name (Restart Required).
   - 8.7 Configure VM Firewall (Restart Required).
   - 8.8 Renew windows server license (Restart Required).
   - 8.9 Restart VM to apply configurations.
9. Create second session object to perform configurations within Virtual Machine.  
10. Following configurations are performed:
    > Only for Dynamics 365 Virtual Machine:
    - 8.1 Configure SQL server instance.
    - 8.2 Configure SSMS: Adds Login.
    - 8.3 Configure SSMS: Assigns Server Role.
    - 8.4 Renew windows server license.
        > - Configure SSRS. Help resource: https://github.com/mrsquish/AutomationScripts/blob/main/ConfigureSSRS.ps1
        > - ***No Longer Required for This Script.***
11. Update User password.
12. Restart VM to apply configurations.
13. Create a checkpoint: After applying configurations within VM.
14. Open Hyper-V connect window of created VM.
15. Output VM Detials to file: VM_DETAILS.txt (Located within VM destination directory)
16. Add details of created VM to HyperV manager notes.

---
## Pre-requisite to Execute Windows PowerShell Script for VM Creation:

1. Virtualization must be enabled in your computer’s BIOS or Firmware.
```sh
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
```
2. 64-bit edition of Windows 10 Pro or Windows Enterprise. (Hyper-V isn’t available in Windows 10 Home edition.)
3. Windows PowerShell Execution Policy must be set to RemoteSigned.
   To check all execution policies, run the following command in Windows PowerShell.
```sh
Get-ExecutionPolicy -List
```
   If LocalMachine is not set to RemoteSigned. To set it, run following command.
```sh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
```
   To revert the execution policy
```sh
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine -Force
```
------------------------------------------------------------
## Instructions to create new VM through VHD or HyperV Import in PowerShell

1. Scripts folder "Add_HyperV_VM" is to be placed at C:\
2. Go to search and type "powershell".
3. Right-click on "Windows PowerShell" and select Run as administartor.
4. Open "Add_HyperV_VM" folder and copy path where "Add_VM.ps1" file exists.
5. In PowerShell, paste the path.

Example:
```sh
cd C:\Add_HyperV_VM
```
6. First edit and then copy/paste the following command in powershell.
    > **Values to be provided by user:**
    > - 6.1 Default VM Name **(Only for AX)**
    > - 6.2 VM Name.
    > - 6.3 VM Type **(e.g. win10, ax, d365)**.
    > - 6.4 RAM to be allocated to VM. **(Not for AX)**
    > - 6.5 Number of CPU to be assigned to VM. **(Not for AX)**
    > - 6.6 VHD File Name. **(Not for AX)**
    > - 6.7 Switch Name.
    > - 6.8 Source directory path of VHD file.
    > - 6.9 Destination path where VM is to be created.
    > - 6.10 Number of threads for copy. **(Not for AX)**
    > - 6.11 Server Name. 
    > - 6.12 VM default username.
    > - 6.13 VM default password. **(Not for AX)**
    > - 6.14 IPV4 address.
    > - 6.15 Default Gateway.
    > - 6.16 DNS Server.
    > - 6.17 Subnet mask number.
    > - 6.18 Port number. **(Not for AX VM)**
    > - 6.19 Name of VM user.
    > - 6.20 Name of creator of VM.
    > - 6.21 Department name of VM user.
    > - 6.22 Supervisor name of VM user.

    Then press Enter.
   
**For Windows 10 Jumpbox VM**
```sh
.\Add_VM.ps1 -vmName "WIN10VM" -vmType "win10" -vmMem 8GB -cpuCount 8 -vhdFileName "WIN10HRH3171.vhdx" -vmSwitch "nSwitch" -srcDirPath "Path" -destDirPath "Path" -threadCount 16 -serverName "localhost" -vmDefaultUsername "win10adm" -vmDefaultPassword "pass@word1" -ipAddress "192.168.0.10" -defaultGateway "192.168.0.1" -dnsServer "8.8.8.8" -subnetMask 24 -vmPort "123456" -ownerName "Name" -createdBy "Creator" -department "Department" -supervisorName "Supervisor"
```
**For Microsoft Dynamics 365 VM**
```sh
.\Add_VM.ps1 -vmName "D365VM" -vmType = "d365" -vmMem 24GB -cpuCount 12 -vhdFileName "FinandOps10.0.17.vhd" -vmSwitch "nSwitch" -srcDirPath "Path" -destDirPath "Path" -threadCount 16 -serverName "localhost" -vmDefaultUsername "Administrator" -vmDefaultPassword "pass@word1" -ipAddress "192.168.0.10" -defaultGateway "192.168.0.1" -dnsServer "8.8.8.8" -subnetMask 24 -vmPort "123456" -ownerName "Name" -createdBy "Creator" -department "Department" -supervisorName "Supervisor"
```
**For Microsoft Dynamics AX VM**
```sh
.\Add_VM.ps1 -defaultVMName "MSD_AX_VM" -vmName "NewAxVM" -vmType = "ax" -vmSwitch "nSwitch" -srcDirPath "Path" -destDirPath "Path" -serverName "localhost" -vmDefaultUsername "AX_Dev" -ipAddress "192.168.0.10" -defaultGateway "192.168.0.1" -dnsServer "8.8.8.8" -subnetMask 24 -ownerName "Name" -createdBy "Creator" -department "Department" -supervisorName "Supervisor"
```

   7. For AX VM (Only)
      - 7.1 Go to where VM folder is created i.e. destination directory and open "VM_DETAILS.txt"
        > - OR 
        > - HyperV notes of created VM.
      - 7.2 Copy the commands below the line.
      - 7.3 In VM open Windows PowerShell as admin.
      - 7.4 Paste the commands and press Enter.

***END!***
