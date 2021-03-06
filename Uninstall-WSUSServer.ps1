<#  
.SYNOPSIS  
    Uninstalls the WSUS Server components from a specified server. Requires psexec.exe to run properly.

.DESCRIPTION
    Uninstalls the WSUS Server components from a specified server. Requires psexec.exe to run properly. 
    Optionally can remove the WSUS database, logs and content.
     
.PARAMETER Computername
    Name of system to remove WSUS from.

.PARAMETER DeleteDatabase
    Deletes the WSUS database

.PARAMETER DeleteContent
    Deletes the WSUS content

.PARAMETER DeleteLogs
    Deletes the WSUS logs

.NOTES  
    Name: Uninstall-WSUSServer.ps1
    Author: Boe Prox
    DateCreated: 01DEC2011 
           
.LINK  
    https://learn-powershell.net
    
.EXAMPLE
Uninstall-WSUSServer.ps1 -Computername Server1

Description
-----------
Uninstalls the WSUS Server from Server1 and does NOT delete the database,logs and content

.EXAMPLE
Uninstall-WSUSServer.ps1 -Computername Server1 -DeleteDatabase -DeleteLogs -DeleteContent

Description
-----------
Uninstalls the WSUS Server from Server1 and DOES delete the database,logs and content

#> 
[cmdletbinding(
    SupportsShouldProcess = $True
)]
Param (
    [parameter(ValueFromPipeLine = $True)]
    [string]$Computername = $Env:Computername,
    [parameter()]
    [switch]$DeleteDatabase,
    [parameter()]
    [switch]$DeleteContent,
    [parameter()]
    [switch]$DeleteLogs
)
Begin {
    If (-NOT (Test-Path psexec.exe)) {
        Write-Warning ("Psexec.exe is not in the current directory! Please copy psexec to this location: `
        {0} or change location to where psexec.exe is currently at.`nPsexec can be downloaded from the following site:`
        http://download.sysinternals.com/Files/SysinternalsSuite.zip" -f $pwd)
        Break
    }
    
    #Source Files for X86 and X64
    Write-Verbose "Setting source files"
    $x86 = Join-Path $pwd "WSUS30-KB972455-x86.exe"
    $x64 = Join-Path $pwd "WSUS30-KB972455-x64.exe"
        
    #Menu items for later use if required
    Write-Verbose "Building scriptblock for later use"
    $sb = {$title = "WSUS File Required"
    $message = "The executable you specified needs to be downloaded from the internet. Do you wish to allow this?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Download the file."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Do not download the file. I will download it myself."    
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    Write-Verbose "Launching menu for file download"
    $Host.ui.PromptForChoice($title, $message, $options, 0)}             
    
    Write-Verbose "Adding URIs for installation files"
    #URI of specified files if needed to download        
    $WSUS_X86 = "http://download.microsoft.com/download/B/0/6/B06A69C3-CF97-42CF-86BF-3C59D762E0B2/WSUS30-KB972455-x86.exe"
    $WSUS_X64 = "http://download.microsoft.com/download/B/0/6/B06A69C3-CF97-42CF-86BF-3C59D762E0B2/WSUS30-KB972455-x64.exe"
    
    #Define Quiet switch first and uninstall switch
    $arg = "/q /u "
    
    #Process parameters
    If ($PSBoundParameters['DeleteDatabase']) {
        $arg += "DELETE_DATABASE=1 "
    }
    If ($PSBoundParameters['DeleteContent']){
        $arg += "DELETE_CONTENT=1 "
    }
    If ($PSBoundParameters['DeleteLogs']) {
        $arg += "DELETE_LOGS=1 "
    }

}
Process {
    Try {
        $OSArchitecture = Get-WmiObject Win32_OperatingSystem -ComputerName $Computername | Select -Expand OSArchitecture -EA Stop
    } Catch {
        Write-Warning ("{0}: Unable to perform lookup of operating system!`n{1}" -f $Computername,$_.Exception.Message)
    }  
    If ($OSArchitecture -eq "64-bit") {
        Write-Verbose ("{0} using 64-bit" -f $Computername)
        If (-NOT (Test-Path $x64)) {
            Write-Verbose ("{0} not found, download from internet" -f $x64)
            $result = &$sb
            switch ($result) {
                0 {
                    If ($pscmdlet.ShouldProcess($WSUS_X64,"Download File")) {
                        Write-Verbose "Configuring webclient to download file"
                        $wc = New-Object Net.WebClient
                        $wc.UseDefaultCredentials = $True              
                        Write-Host -ForegroundColor Green -BackgroundColor Black `
                        ("Downloading from {0} to {1} prior to installation. This may take a few minutes" -f $WSUS_X64,$x64)
                        Try {
                            $wc.DownloadFile($WSUS_X64,$x64)                                                                                    
                        } Catch {
                            Write-Warning ("Unable to download file!`nReason: {0}" -f $_.Exception.Message)
                            Break
                        } 
                    }                   
                }
                1 {
                    #Cancel action
                    Break
                }                
            }
        } 
        #Copy file to root drive
        If (-NOT (Test-Path ("\\$Computername\c$\{0}" -f (Split-Path $x64 -Leaf)))) {
            Write-Verbose ("Copying {0} to {1}" -f $x64,$Computername)
            If ($pscmdlet.ShouldProcess($Computername,"Copy File")) {                                
                Try {
                    Copy-Item -Path $x64 -Destination "\\$Computername\c$" -EA Stop
                } Catch {
                    Write-Warning ("Unable to copy {0} to {1}`nReason: {2}" -f $x64,$Computername,$_.Exception.Message)
                }
            }
        } Else {Write-Verbose ("{0} already exists on {1}" -f $x64,$Computername)}
        #Perform the installation
        Write-Verbose ("Begin installation on {0} using specified options" -f $Computername)
        If ($pscmdlet.ShouldProcess($Computername,"Uninstall WSUS")) {
            .\psexec.exe -accepteula -i -s \\$Computername cmd /c ("C:\{0} $arg" -f (Split-Path $x64 -Leaf))                                
        }
    } Else {
        Write-Verbose ("{0} using 32-bit" -f $Computername)
        If (-NOT (Test-Path $x86)) {
            Write-Verbose ("{0} not found, download from internet" -f $x86)
            $result = &$sb
            switch ($result) {
                0 {
                    If ($pscmdlet.ShouldProcess($WSUS_X86,"Download File")) {
                        Write-Verbose "Configuring webclient to download file"
                        $wc = New-Object Net.WebClient
                        $wc.UseDefaultCredentials = $True              
                        Write-Host -ForegroundColor Green -BackgroundColor Black `
                        ("Downloading from {0} to {1} prior to installation. This may take a few minutes" -f $WSUS_X86,$x86)
                        Try {
                            $wc.DownloadFile($WSUS_X86,$x86)                                                                                          
                        } Catch {
                            Write-Warning ("Unable to download file!`nReason: {0}" -f $_.Exception.Message)
                            Break
                        }
                    }                    
                }
                1 {
                    #Cancel action
                    Break
                }                                
            }
        }
        #Copy file to root drive
        If (-NOT (Test-Path ("\\$Computername\c$\{0}" -f (Split-Path $x86 -Leaf)))) {
            Write-Verbose ("Copying {0} to {1}" -f $x86,$Computername)
            If ($pscmdlet.ShouldProcess($Computername,"Copy File")) {
                Try {
                    Copy-Item -Path $x86 -Destination "\\$Computername\c$" -EA Stop
                } Catch {
                    Write-Warning ("Unable to copy {0} to {1}`nReason: {2}" -f $x86,$Computername,$_.Exception.Message)
                }
            }
        } Else {Write-Verbose ("{0} already exists on {1}" -f $x86,$Computername)}
        #Perform the installation
        Write-Verbose ("Begin installation on {0} using specified options" -f $Computername)
        If ($pscmdlet.ShouldProcess($Computername,"Uninstall WSUS")) {
            .\psexec.exe -accepteula -i -s \\$Computername cmd /c ("C:\{0} $arg" -f (Split-Path $x86 -Leaf))
        }
    }   
}