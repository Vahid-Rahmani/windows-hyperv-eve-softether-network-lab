# Journey reflection — what this project really represents

The author reports that reaching the working result took **several weeks**. This repository therefore documents more than a final topology: it records the reasoning, failed assumptions, command-line practice, evidence collection, and corrections that turned separate experiments into one working lab.

## Where the journey began

The first exercises were Windows Server fundamentals: installing and addressing a domain controller, learning the difference between a member server and a DC, configuring DNS, creating DHCP scopes, and building an Active Directory structure. The fictional `kurs.intern` domain was used for practice. Users, OUs, global groups, domain-local groups, AGDLP membership, SMB shares, and NTFS inheritance were scripted with PowerShell.

The file-server exercise also produced a real permissions lesson. A deliberately protected folder tree returned `Access is denied` when deletion was attempted. Instead of treating that as a mysterious failure, the path, spelling (`Firma` versus a misspelled variant), share, ownership, inheritance, and ACLs were checked in sequence. `takeown`, `icacls`, share removal, and administrator recovery were learned as a consequence of that failure.

## The platform and virtual machines

Ubuntu, KVM, QEMU, and virt-manager were then used to host EVE-NG. A Windows 10 QEMU image was prepared with an ISO, a thin-provisioned QCOW2 disk, `qemu-img info`, and EVE-NG permission repair. A black VNC screen led to checking the console type, QEMU version, CD-ROM naming, disk format, and the running QEMU command line. The important lesson was to inspect evidence before changing several settings at once.

The physical Linux interface `enp2s0` was another useful distinction: `UP` with `NO-CARRIER` means the interface is enabled but no cable/peer is present. Bringing the interface up in software cannot manufacture a physical link.

## Connecting two separate hosts

The difficult architectural step was joining an EVE-NG lab on Ubuntu to the Hyper-V `DC-LAB` internal switch on Windows 11. A direct external switch or Internet Connection Sharing would have introduced a second, competing gateway. SoftEther was used instead:

```text
EVE cloud → br-eve → SoftEther VPN Bridge / BRIDGE
         → Cascade WINDOWS-DC-LAB
         → SoftEther VPN Server / BRIDGE
         → Hyper-V DC-LAB
```

`systemctl` proved that the Linux service was running; `CascadeList` proved that the remote connection was established; `BridgeList` proved that `br-eve` was operating. Entering `ping` inside `vpncmd` was a syntax mistake because `vpncmd` is not a Linux shell; the test had to be run after leaving that management prompt.

## The routing decisions that mattered

The lab deliberately uses two link types:

* SW1 ↔ R1 is a trunk carrying VLAN 10 and VLAN 20. R1 uses subinterfaces (`e0/0.10` and `e0/0.20`) as gateways.
* SW2 ↔ R1 is an access VLAN 30 link. R1 uses a physical routed interface (`e0/1`) as `10.10.30.1` in the example plan; a `.30` subinterface is not required on that separate link.

This is why the same interface cannot be treated as both a simple access connection and a multi-VLAN trunk. It is also why `ip helper-address` belongs on R1's Layer-3 gateway interfaces, not on a Layer-2 switch.

## Evidence-driven troubleshooting

The most valuable captured evidence was DHCP traffic on `br-eve`. A Discover was seen leaving the relay with the relay/gateway address and reaching the DHCP server. That proved the client, switch, R1 helper, SoftEther bridge, and Windows-side path were at least forwarding the request. When no Offer appeared in the capture, the next investigation moved to scope selection, option 003, and the return route instead of repeatedly rebuilding the bridge.

Other high-value evidence included `show ip interface brief`, `show ip route`, `show running-config | include helper-address`, `show vlan brief`, `show interfaces status`, `ipconfig /all`, `Get-NetAdapter`, `Get-DhcpServerv4OptionValue`, `nslookup`, `tracert`, and `show ip nat translations`.

## The problems that changed the design

1. A duplicate gateway address on the Hyper-V host and R1 created ARP ambiguity. The host became management-only at `.254`; R1 retained `.1` as the gateway.
2. Some SW2 ports remained in VLAN 1 while R1 was in VLAN 30. The router-facing and client-facing ports were made access VLAN 30.
3. DHCP could succeed while routing still failed because a client received a gateway from the wrong subnet. The router option was corrected per scope.
4. The internal Hyper-V switch did not provide Internet access. R1 became the only lab router and performed NAT/PAT toward the libvirt NAT network.
5. A Cascade pointed to a Wi-Fi DHCP address. After the Wi-Fi address changed, the tunnel failed. The transport target was changed to a stable FQDN.
6. Applying `ip nat inside` to the trunk parent was a conceptual error. NAT inside belongs on routed subinterfaces and routed LAN interfaces; the parent carries tags.

## What the author can now explain

* A subnet is represented by an L3 interface and a route; a Layer-2 switch only carries the VLAN.
* DHCP, DNS, default gateway, NAT, and VPN transport solve different problems.
* A lease is not enough: the address, mask, gateway, DHCP server, DNS server, and path all need verification.
* A service can be running while its connection is down; service status and tunnel/bridge status are separate tests.
* A stable FQDN removes dependence on a changing private Wi-Fi address, while a dedicated wired transport `/30` is a separate design option—not something to claim as deployed unless it was actually built.
* The safest troubleshooting loop is: observe → form one hypothesis → change one layer → test → record the result.

## What is intentionally not claimed

This portfolio version does not claim that the proposed redundant DCs, OSPF, ACL lab, monitoring stack, Azure/Entra integration, or dedicated Ethernet `/30` were completed. Those appeared as future expansion ideas. The completed path is the one evidenced by the conversations: one Windows domain/DNS/DHCP environment, Hyper-V, Ubuntu/KVM/EVE-NG, SoftEther bridging, Cisco VLAN routing, DHCP relay, and Internet NAT.
