# Command reference and expected evidence

The commands below are a reference, not a blind copy-and-paste deployment. Interface names, scope ranges, credentials, and service paths must be checked in the live lab. Examples intentionally use anonymized data.

## Windows: DHCP, DNS, and client validation

Create example remote scopes and set the correct router option per scope:

```powershell
Add-DhcpServerv4Scope -Name 'VLAN20-CLIENTS' -StartRange 10.10.20.100 -EndRange 10.10.20.200 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.10.20.0 -Router 10.10.20.1 -DnsServer 10.10.10.10 -DnsDomain 'kurs.intern'

Add-DhcpServerv4Scope -Name 'VLAN30-CLIENTS' -StartRange 10.10.30.100 -EndRange 10.10.30.200 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.10.30.0 -Router 10.10.30.1 -DnsServer 10.10.10.10 -DnsDomain 'kurs.intern'

Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 10.10.30.0
```

Expected: a VLAN 30 scope exists and option 003/router is `10.10.30.1`, not a gateway from VLAN 10 or 20.

Client-side evidence:

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
ping 10.10.30.1
ping 10.10.10.10
nslookup kurs.intern
Test-NetConnection 8.8.8.8 -Port 53
```

Expected: the client address, subnet mask, default gateway, and DNS server align with its own scope. A public name lookup is only expected after gateway, NAT, and DNS forwarder checks succeed.

## Cisco IOS: routing, relay, NAT, and proof

Representative R1 Layer-3 configuration:

```cisco
interface Ethernet0/0.10
 encapsulation dot1Q 10
 ip address 10.10.10.1 255.255.255.0
 ip nat inside

interface Ethernet0/0.20
 encapsulation dot1Q 20
 ip address 10.10.20.1 255.255.255.0
 ip helper-address 10.10.10.20
 ip nat inside

interface Ethernet0/1
 ip address 10.10.30.1 255.255.255.0
 ip helper-address 10.10.10.20
 ip nat inside

interface Ethernet0/3
 ip address dhcp
 ip nat outside

ip access-list standard NAT_INSIDE
 permit 10.10.10.0 0.0.0.255
 permit 10.10.20.0 0.0.0.255
 permit 10.10.30.0 0.0.0.255
ip nat inside source list NAT_INSIDE interface Ethernet0/3 overload
```

Do not place `ip nat inside` on parent `Ethernet0/0`; the routed subinterfaces are the right inside interfaces.

Evidence commands:

```cisco
show ip interface brief
show ip route
show ip dhcp relay statistics
show vlan brief
show interfaces trunk
show ip nat translations
show ip nat statistics
ping 10.10.10.10
ping 10.10.10.20
ping 172.20.122.1
```

Expected: R1 has connected routes for the three inside subnets, reaches both Windows services, and creates NAT translations only when a client generates outside-bound traffic.

## Linux / EVE-NG / SoftEther: bridge and service evidence

```bash
ip -br link
ip link show br-eve
systemctl is-active softether-vpnbridge
systemctl is-enabled softether-vpnbridge
sudo systemctl daemon-reload
sudo systemctl enable --now softether-vpnbridge
sudo tcpdump -ni br-eve '(port 67 or port 68)'
```

In SoftEther `vpncmd`, confirm the actual bridge and remote transport:

```text
BridgeList
CascadeList
CascadeOffline WINDOWS-DC-LAB
CascadeSet WINDOWS-DC-LAB /SERVER:vpn-lab.example.net:443 /HUB:BRIDGE
CascadeUsernameSet WINDOWS-DC-LAB /USERNAME:bridge-user
CascadePasswordSet WINDOWS-DC-LAB /TYPE:standard
CascadeOnline WINDOWS-DC-LAB
```

`CascadePasswordSet` must be completed interactively. Never save the password in a script or Git repository.

Expected: `br-eve` is present, `BridgeList` reports it as `Operating`, and `CascadeList` reports `Online (Established)`. If a capture shows a forwarded Discover with relay address `10.10.20.1`, focus next on DHCP scope and server reply behaviour.

## Service extensions

For Docker, CUPS, and Windows file-service recovery examples, see [Application services and optional extensions](application-services-and-extensions.md). These are kept separate from the router and bridge commands so an optional service experiment cannot be mistaken for required transport configuration.
