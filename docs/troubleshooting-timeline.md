# Troubleshooting timeline: symptom → evidence → correction

| Stage | Symptom | Evidence / diagnosis | Resolution |
| --- | --- | --- | --- |
| 0 | Direct EVE ↔ Hyper-V attempt was not repeatable | The two virtualisation boundaries and an internal Hyper-V switch did not provide a dependable Layer-2 path | Introduced SoftEther as a dedicated bridge transport, then kept routing in EVE/R1 |
| 1 | VLAN 20 clients did not receive an address | `tcpdump` showed DHCP Discover forwarded from `10.10.20.1` to `10.10.10.20`, with `Gateway-IP 10.10.20.1`; no reply was seen in the capture | Proved the relay/SoftEther forward path was alive and moved investigation to DHCP scope/return behaviour rather than EVE bridging |
| 1a | DHCP scope did not match the intended server network | An earlier scope used `10.99.100.0/24` as a placeholder for the wrong network | Replaced it with the server scope and matched each remote scope to its relay gateway |
| 2 | Intermittent connectivity | Windows host `vEthernet (DC-LAB)` and R1 `e0/0.10` both used `10.10.10.1` | Removed host `.1`, set host management address to `10.10.10.254`, and cleared stale ARP caches |
| 3 | Windows 10 was added behind SW2 | Need an isolated client segment without disturbing VLANs 10/20 | Created `10.10.30.0/24`; R1 `e0/1 = 10.10.30.1`; SW2 access VLAN 30 |
| 4 | DHCP worked on LAN 30 but PC3 could not ping | PC3 received `10.10.30.100/24` with gateway `10.10.10.2` | Corrected DHCP scope 30 option 003 to `10.10.30.1`; each scope now receives its own gateway |
| 5 | Hyper-V server network lacked Internet | `DC-LAB` is intentionally an internal switch | Made R1 the sole Internet gateway and enabled NAT/PAT to `e0/3` over libvirt `virbr0` |
| 6 | SoftEther connection broke after network change/restart | Cascade destination remained a previous Wi-Fi address | Changed Cascade target to `vpn-lab.example.net:443`; confirmed `Online (Established)` |
| 7 | SoftEther service would not start after editing | `systemd` reported `Assignment outside of section` | Corrected the unit file, reloaded systemd, enabled the service, and checked active/enabled state |
| 8 | TAP device was assumed to be required | `BridgeList` showed the local bridge to `br-eve` | Kept the simpler Linux bridge path and verified `br-eve` directly |
| 7 | Confusion over DHCP helper placement | SW2 is a Layer-2 switch | Kept `ip helper-address` only on the L3 gateway interfaces R1 `e0/0.20` and `e0/1` |
| 8 | NAT concern on a trunk parent | `ip nat inside` was accidentally considered/applied to parent `e0/0` | Remove it from parent with `no ip nat inside`; apply it only to routed subinterfaces |

## Additional service-side and extension observations

| Area | Symptom or question | Evidence-led conclusion | Recorded next step |
| --- | --- | --- | --- |
| Docker | Registry pull/build reported a name-resolution failure | A container workflow still depends on client DNS and an Internet route; it is not automatically a Dockerfile problem | Validate DHCP DNS, DC forwarders, R1 NAT, then `nslookup registry-1.docker.io` before retrying |
| Docker | `docker build` did not behave as expected | A Dockerfile, image, and running container are different stages; the build context is required | Use a confirmed directory and `docker build -t hello-docker .` |
| Windows file service | Folder access or deletion failed | Share and NTFS permissions combine, and an earlier naming typo complicated the check | Verify the exact path; recover ownership/ACL only on the confirmed target |
| Printer planning | A virtual printer was expected as an EVE-NG node | EVE-NG has no native printer appliance | Use a Windows print server or a Linux/Red Hat VM with CUPS as an optional lab endpoint |
| Red Hat/CUPS | Printer network layout was still undecided | A dedicated VLAN can be a useful exercise but was not required by the proven core topology | Treat VLAN 60 and CUPS configuration as `[confirm]` extension work |

## Lessons retained from the failures

1. A Layer-2 switch carries a VLAN; it does not define a routed subnet.
2. DHCP address assignment alone is not proof of end-to-end connectivity. Verify its router option.
3. DHCP relay debugging benefits from packet capture: it separates broadcast forwarding, DHCP-server response, and client delivery.
4. An address conflict can look random because ARP chooses between competing MAC addresses.
5. DNS resolves names; a default gateway forwards Internet traffic.
6. A VPN transport should use a stable FQDN or controlled address—not a changing Wi-Fi DHCP address.
