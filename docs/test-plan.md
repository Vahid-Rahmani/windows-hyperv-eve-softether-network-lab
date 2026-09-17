# Test plan and expected results

| Layer | Where | Command | Expected result |
| --- | --- | --- | --- |
| SoftEther service | Ubuntu | `systemctl is-active softether-vpnbridge` | `active` |
| Cascade | `vpncmd` / hub `BRIDGE` | `CascadeList` | `WINDOWS-DC-LAB` is `Online (Established)`; destination is the SoftEther FQDN |
| Local bridge | `vpncmd` | `BridgeList` | `BRIDGE` to `br-eve` is `Operating` |
| DHCP relay evidence | Ubuntu | `sudo tcpdump -vvv -s0 -eni br-eve 'udp port 67 or udp port 68'` | Relay traffic includes correct `Gateway-IP` for the client VLAN |
| R1 reachability | R1 | `ping 10.10.10.10` / `ping 10.10.10.20` | DC and DHCP reachable over bridged VLAN 10 |
| R1 WAN | R1 | `ping 172.20.122.1` then `ping 8.8.8.8` | libvirt gateway and external IP reachable |
| Client lease | Windows / VPCS | `ipconfig /all` or `show ip` | Correct subnet, gateway, DHCP server `.10.20`, DNS `.10.10` |
| Local routing | client | ping own gateway, then `ping 10.10.10.10` | Both answer |
| NAT | client then R1 | `ping 8.8.8.8`; `show ip nat translations` | Client has Internet IP reachability and translation appears |
| DNS | client | `nslookup google.com` | Query succeeds through DC DNS / configured forwarders |
| Path | Windows client | `tracert 8.8.8.8` | First hop is the gateway of the client subnet |

For a VLAN 30 lease, the expected values are:

```text
Address:      10.10.30.100–200 [example range]
Gateway:      10.10.30.1
DHCP server:  10.10.10.20
DNS server:   10.10.10.10
Domain:       kurs.intern
```
