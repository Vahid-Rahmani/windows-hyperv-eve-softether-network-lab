# Example addressing and names

These are safe, readable placeholders for documentation and portfolio publication. They are **not** the live environment.

| Role | Example value | Why it exists |
| --- | --- | --- |
| Domain | `kurs.intern` | Example internal AD DNS namespace |
| R1 VLAN 10 | `10.10.10.1/24` | Server VLAN gateway |
| DC/DNS | `10.10.10.10/24` | Domain and DNS services |
| DHCP/File server | `10.10.10.20/24` | DHCP scopes and SMB services |
| Hyper-V host management | `10.10.10.254/24` | Management only; no gateway on DC-LAB |
| R1 VLAN 20 | `10.10.20.1/24` | EVE client VLAN gateway and relay address |
| R1 LAN 30 | `10.10.30.1/24` | Windows 10 / VPCS LAN gateway and relay address |
| SW2 optional SVI | `10.10.30.2/24` | Switch management only—not the gateway |
| VLAN 30 DHCP range | `10.10.30.100–200` | Client lease range |
| WAN/libvirt | `172.20.122.0/24` | Example NAT transport; R1 uses DHCP on e0/3 |
| VPN endpoint | `vpn-lab.example.net:443` | Stable name instead of a Wi-Fi DHCP address |

Never publish real home/school Wi-Fi IP addresses, public IPs, VPN credentials, real user accounts, or a live hostname. Keep any mapping to real values in a private password manager or private repository.
