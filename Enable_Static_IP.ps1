function func_MAC_address()
{
$input | ForEach-Object {
	$macAddressRecord = New-Object System.Management.Automation.PSObject
	$macAddressRecord.PSObject.TypeNames[0] = 'NetworkAdapterMacAddress'
	$macAddressRecord `
		| Add-Member -MemberType NoteProperty -Name Name -Value $_.Name -PassThru `
		| Add-Member -MemberType NoteProperty -Name MacAddress -Value $_.GetPhysicalAddress() -PassThru
}
}
$N=[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | where { $_.Name -like 'Local Area Connection'} | func_MAC_address | Select-Object -property 'MacAddress'
$Mac=$N.MacAddress
$Mac
#  $Input = The current content of the pipeline.
#  $_ =     The current pipeline object; used in script blocks, filters, functions and loops

# Load .NET VB interaction class for GUI inputbox
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#Get Ip address
$IPconfigset = Get-WmiObject Win32_NetworkAdapterConfiguration  
# Iterate and get IP address 
$count = 0
foreach ($IPConfig in $IPConfigSet) { 
   if ($Ipconfig.IPaddress) { 
      foreach ($addr in $Ipconfig.Ipaddress) { 
      "IP Address   : {0}" -f  $addr; 
      $count++
      } 
   } 
} 
 #      
# $computer = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername")
# $ipaddress = Read-Host “Enter the IP Address”
# $submask = Read-Host “Enter Subnet Mask”
# $GW = Read-Host “Enter Default Gateway”

$ipaddress = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your ip address", "IP ADDRESS")
$submask = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your subnet mask", "Subnet Mask", "255.255.255.0")
$GW = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your Gateway", "Gateway")

$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration | where {$_.MACAddress -eq "00:24:E8:B0:7D:E2"}
Foreach($NIC in $NICs) {
$NIC.EnableStatic("$ipaddress","$submask")
$NIC.SetGateways("$GW")
$DNSServers = "10.5.5.30","10.5.6.30"
$NIC.SetDNSServerSearchOrder($DNSServers)
$NIC.SetDynamicDNSRegistration("TRUE")
}