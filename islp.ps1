<# Islp.ps1
Script modified from Islp-setup.cmd for Windows 7
Version 0.1
DTTD / Team Client
#>
# $scriptpath= Split-Path -parent $MyInvocation.MyCommand.Definition
# Start-Transcript -Path $scriptpath
$host.ui.RawUI.foregroundcolor="darkblue"
$host.ui.RawUI.backgroundcolor="white"

# Check if current user is admin, propose alternate credentials or continue using existing credentials
Function Test-IsAdmin   
{  
    [cmdletbinding()]  
    Param()  
      
    Write-Verbose "Checking to see if current user is Administrator"  
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
    {  
        Write-Warning "You are NOT currently running under an Administrator account! `nAdministrator rights are required for full functionality."  
        Write-Verbose "Presenting option for user to pick whether to continue as current user or use alternate credentials"  
        #Determine Values for Choice  
        $choice = [System.Management.Automation.Host.ChoiceDescription[]] @("Use &Alternate Credentials","&Continue with current Credentials")  
  
        #Determine Default Selection  
        [int]$default = 0  
  
        #Present choice option to user  
        $userchoice = $host.ui.PromptforChoice("Warning","Please select to use Alternate Credentials or current credentials to continue:",$choice,$default)  
  
        Write-Debug "Selection: $userchoice"  
  
        #Determine action to take  
        Switch ($Userchoice)  
        {  
            0  
            {  
                #Prompt for alternate credentials  
                Write-Verbose "Prompting for Alternate Credentials"  
                $Credential = Get-Credential  
                Write-Output $Credential      
            }  
            1  
            {  
                #Continue using current credentials  
                Write-Verbose "Using current credentials"  
                Write-Output "CurrentUser"  
            }  
        }          
          
    }  
    Else   
    {  
        Write-Host "Administrator check: OK"  -foregroundcolor green
    }  
}
Test-IsAdmin

# Check if C-drive is NTFS
if ((Get-WMIObject win32_logicaldisk -filter "DeviceID = 'C:'").filesystem -ne "ntfs") 
{write-warning "This is not an NTFS filesystem";$a=Read-host "Do you want to continue? (Y/N)";
if ($a -eq "N") {write-host "Please use 'CONVERT C: /FS:NTFS' to convert to NTFS"; Start-Sleep 3; exit}}


Split-Path -parent $MyInvocation.MyCommand.Definition

#Check Windows version
$v=Get-WmiObject win32_operatingsystem
if ($v.caption + $v.version +" "+ $v.csdversion -ne "Microsoft Windows 7 Professional 6.1.7601 Service Pack 1") {
Write-Host "This pc is running $($v.caption)$($v.version) $($v.csdversion). `nThis version is not yet supported.";
$c= Read-Host "Continue anyway? (Y/N)"
}
if ($c -eq "n") {exit} 
# else {continue}

