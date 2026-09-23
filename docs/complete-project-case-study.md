# Complete project case study

This is the portfolio version of a lab that took several weeks to assemble and debug. It is deliberately honest: the finished topology is documented alongside the failed direct connection, the wrong DHCP data, the service-repair work, and the small configuration assumptions that cost time.

All IP addresses, hostnames, user names, and public endpoints below are sanitized teaching examples. They describe the design, not a publishable copy of a private environment.

## The finished outcome

The final lab connected a Windows 11 Hyper-V server environment to an Ubuntu-hosted EVE-NG topology. Windows supplied Active Directory, DNS, DHCP, and SMB services. EVE-NG supplied Cisco routing and switching. SoftEther supplied the Layer-2 transport between the two hosts. Cisco R1 supplied inter-VLAN routing, DHCP relay, and NAT/PAT for Internet access.

```text
Windows 11 / Hyper-V                         Ubuntu / KVM / EVE-NG
DC-LAB internal vSwitch                      br-eve -> EVE Cloud
  DC/DNS: 10.10.10.10                               |
  DHCP/SMB: 10.10.10.20                             R1 -> SW1/SW2 -> clients
             |                                        |
       SoftEther Server <== encrypted L2 ==> SoftEther VPN Bridge
                                    stable FQDN endpoint
```

R1 is the only Layer-3 default gateway for the lab subnets. The example service segment is `10.10.10.0/24`; R1 routes VLAN 20 and LAN/VLAN 30 and relays their DHCP broadcasts to `10.10.10.20`.

## The actual build path

### 1. Build the Windows foundation first

The first work was not EVE-NG. It was a Windows Server practice environment on a Hyper-V internal switch named `DC-LAB`:

* a domain controller and DNS server, illustrated here as `10.10.10.10`;
* a DHCP and file server, illustrated here as `10.10.10.20`;
* Active Directory OUs, users, groups, and AGDLP-style access control;
* a `Firma` file share with department folders and a restricted payroll area.

This created real services for later EVE clients to use. It also exposed everyday administration problems: inherited NTFS permissions, an `Access is denied` deletion problem, the difference between a share permission and NTFS permission, and a naming typo between `Firma` and `Frima`. Administrator recovery used ownership and ACL repair only after the affected path was identified.

### 2. Add Ubuntu, KVM, and EVE-NG

Ubuntu was prepared with KVM/QEMU and virt-manager, then EVE-NG was used for the Cisco and endpoint topology. A Windows 10 image was prepared in EVE with an appropriately named QCOW2 disk and an ISO for installation. VNC was needed during installation; RDP was a later-management option after the guest had working networking.

Two early observations avoided false diagnosis:

* a black VNC console is normally a guest boot, ISO, or display problem, not proof of a network failure;
* an interface such as `enp2s0` in `NO-CARRIER` has no link partner. IP configuration cannot manufacture a physical carrier.

### 3. Try the direct cross-host path, then replace it

The first approach attempted to connect the EVE/Ubuntu side directly to the Hyper-V internal-switch side. It was not a dependable, repeatable Layer-2 path across the two virtualisation boundaries. This was the point at which the design changed: transport was separated from routing.

SoftEther was introduced as the transport layer. The Windows side hosted the target hub; Ubuntu ran SoftEther VPN Bridge. The bridge bound the EVE-facing Linux bridge `br-eve` to hub `BRIDGE`, and a Cascade connected to the Windows side.

This is an important distinction: SoftEther carries Ethernet frames. It is not the default gateway and it does not replace Cisco routing.

### 4. Make the bridge observable and persistent

The working evidence was not merely that a daemon existed. The bridge needed to show both of these states:

```text
BridgeList:  BRIDGE | br-eve | Operating
CascadeList: WINDOWS-DC-LAB | Online (Established)
```

An assumed interface named `tap_tap_eve` did not exist. The correction was to stop inventing a TAP device, inspect `ip link`, and use the bridge that SoftEther actually reported: `br-eve`.

Later, a hand-edited systemd unit failed with `Assignment outside of section`. Correcting the unit syntax, running `daemon-reload`, enabling the service, and checking both active and enabled status made the bridge survive reboot.

### 5. Design the Cisco topology around the traffic

R1 and SW1 use a trunk because one physical link carries VLANs 10 and 20. R1 uses subinterfaces for those gateways. R1 and SW2 use access VLAN 30 because that physical segment carries only VLAN 30.

```text
R1 e0/0.10  -> VLAN 10 -> 10.10.10.1/24
R1 e0/0.20  -> VLAN 20 -> 10.10.20.1/24
R1 e0/1     -> VLAN 30 -> 10.10.30.1/24
R1 e0/3     -> outside -> example libvirt NAT network
```

This corrected a common mental model error: a Layer-2 switch carries VLAN membership but does not create a routed subnet. R1 owns the subnet gateway. A switch virtual interface, if used, is only a separate management address and must never duplicate the router address.

### 6. Prove DHCP relay rather than guessing

The DHCP server was on the service segment, while VLAN 20 and 30 clients were remote. DHCP broadcasts cannot cross a router, so `ip helper-address 10.10.10.20` belonged on R1's VLAN 20 and VLAN 30 gateway interfaces.

`tcpdump` supplied the decisive evidence: a Discover forwarded to the DHCP server showed the relay gateway field as `10.10.20.1`. This proved that the client-to-R1-to-service-network path was working. When no offer arrived, the investigation moved to DHCP scope selection, options, and reply handling instead of blaming EVE-NG.

Two separate DHCP mistakes were corrected:

* an earlier scope described the wrong network (represented here as `10.99.100.0/24`);
* a VLAN 30 lease was issued with a router option from another subnet. Option 003 was corrected to `10.10.30.1`.

An address lease is therefore not the final test. The lease, mask, DNS server, and especially router option all must match the client subnet.

### 7. Remove the ARP conflict and add Internet access

The Hyper-V host management adapter and R1 initially competed for the same VLAN 10 gateway address. That produced intermittent behaviour because ARP could map one IP address to different MAC addresses. R1 remained at the example address `10.10.10.1`; the host management adapter moved to `10.10.10.254` with no default gateway on the internal switch.

R1 then became the single route to the Internet. It marked only Layer-3 client interfaces as NAT inside, marked the libvirt-facing interface as outside, and translated traffic with PAT. NAT was removed from the trunk parent interface; the subinterfaces and routed LAN interface are the correct inside locations.

### 8. Fix the changing Wi-Fi transport endpoint

The Cascade initially targeted a dynamic Wi-Fi address. When the Wi-Fi network changed, the remote address changed too and the Cascade stopped working. The durable correction was a stable DDNS/FQDN endpoint such as `vpn-lab.example.net:443`, not a remembered DHCP lease.

### 9. Validate from service to Internet

The final validation sequence is intentionally layered:

1. SoftEther service, `BridgeList`, and `CascadeList`.
2. R1 reachability to DNS, DHCP, and the outside gateway.
3. DHCP renew and per-scope router option.
4. Client reachability to its own gateway, DNS/DC, an Internet IP, then a public DNS lookup.
5. R1 NAT translations while a client accesses the Internet.

Only after these tests pass should a Windows client join the domain.

## Additional practice captured by the project

The notes also contain service exercises that belong to the learning journey but are not claimed as required parts of the final core topology:

* Docker and nginx on the application server: an image pull/build issue revealed missing DNS or Internet reachability; the exercise clarified Dockerfile vs. image vs. container and the required build context dot in `docker build -t hello-docker .`.
* Virtual printer planning: EVE-NG has no native printer node. A realistic next module is either Windows Print Server with AD/GPO deployment or a Red Hat VM running CUPS. The latter is documented as an optional extension, not as a completed production printer rollout.

## What this repository does and does not claim

It documents the verified design decisions, observed symptoms, commands used for diagnosis, and corrections. It does not include secrets, VM disks, or claims that an optional printer rollout, every screenshot, or every intermediate configuration was completed exactly as a production deployment. Any setting marked `[confirm]` needs a live-lab check before reuse.

## Portfolio takeaway

The strongest result is not a diagram with all links green. It is the ability to isolate a failure by layer: carrier, bridge, Cascade, VLAN, routing, DHCP relay, DHCP option, DNS, and NAT. The final lab is useful because the troubleshooting history explains why each part exists.
