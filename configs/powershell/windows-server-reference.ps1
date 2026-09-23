# Reference commands for Windows Server / Hyper-V. Review before running.
# Values follow the final lab plan; commands change live configuration.

# Hyper-V host management address: intentionally no DefaultGateway.
Remove-NetIPAddress -InterfaceAlias "vEthernet (DC-LAB)" -IPAddress 10.10.10.1 -Confirm:$false
New-NetIPAddress -InterfaceAlias "vEthernet (DC-LAB)" -IPAddress 10.10.10.254 -PrefixLength 24

# DHCP scope for the routed LAN 30.
Add-DhcpServerv4Scope -Name "VLAN30-CLIENTS" -StartRange 10.10.30.100 -EndRange 10.10.30.200 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.10.30.0 -Router 10.10.30.1 -DnsServer 10.10.10.10 -DnsDomain "kurs.intern"

# Inspect scopes and ensure each scope's option 003 matches its local R1 interface.
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 10.10.10.0
Get-DhcpServerv4OptionValue -ScopeId 10.10.20.0
Get-DhcpServerv4OptionValue -ScopeId 10.10.30.0

# If an unwanted server-level Router option overrides scope behaviour, remove only option 003.
# Remove-DhcpServerv4OptionValue -OptionId 3

# DC forwards non-kurs.intern names outward. Confirm policy before setting public resolvers.
Get-DnsServerForwarder
# Set-DnsServerForwarder -IPAddress 1.1.1.1,8.8.8.8

# Client-side DHCP reset (run on the client; alias may differ).
# Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Enabled
# Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ResetServerAddresses
# ipconfig /release
# ipconfig /renew

# Diagnostics after correcting an address conflict.
# arp -d *
# Restart-Service DHCPServer
