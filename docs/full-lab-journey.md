# Full lab journey — from first server to working multi-site network

This document deliberately uses **example addresses**. It preserves the engineering path and its failures without publishing the real environment. Replace only the values in `docs/example-ip-plan.md` when reproducing the lab.

## One picture, three layers

```text
SERVICES LAYER                         TRANSPORT LAYER                    NETWORK LAYER
AD DS / DNS / DHCP / SMB               SoftEther Layer-2 bridge           EVE-NG + Cisco R1 + switches
10.10.10.10 / .20                      stable FQDN over Internet           VLAN 10 / 20 / 30 + NAT
        │                                         │                                    │
        └──────── Hyper-V DC-LAB ────────────────┴──────────── br-eve ───────────────┘
```

## Phase 0 — the earlier Windows Server practice lab

Before EVE-NG was connected, the Windows environment was used to practise the services that later became reachable from EVE.

```text
Domain: kurs.intern (example name retained from lab)
DC/DNS: 10.10.10.10
SRV-APP01: 10.10.10.20
Share: \\SRV-APP01\Firma
```

Implemented learning tasks included:

* Active Directory OUs for a fictional organisation, users, global and domain-local groups using AGDLP.
* An SMB share `Firma` with department folders such as `Allgemein`, `Verkauf`, `Werkstatt`, `Buchhaltung`, and restricted `Lohn`.
* NTFS inheritance changes and recovery from an `Access is denied` deletion problem by taking ownership and restoring administrator control.
* The difference between the default gateway and DNS: domain members use the DC DNS address; the router is their gateway.

This service layer matters because later EVE clients obtain DHCP from the server, resolve the domain through DNS, and may join the domain.

## Phase 1 — Ubuntu, KVM, EVE-NG, and Windows 10 in EVE

EVE-NG was deployed on Ubuntu/KVM and managed with virt-manager. A Windows 10 node was then prepared in EVE:

```bash
# On the EVE appliance — example image preparation flow
mkdir -p /opt/unetlab/addons/qemu/win-10
qemu-img create -f qcow2 virtioa.qcow2 60G
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions
qemu-img info /opt/unetlab/addons/qemu/win-10/virtioa.qcow2
```

The VM needed VNC while Windows was not installed. A dark VNC screen was investigated as a boot/ISO/QEMU configuration issue, not as a network failure. `enp2s0` being `NO-CARRIER` was also correctly recognised as a physical-link condition: software cannot create carrier when no cable/peer is connected.

## Phase 2 — joining the two host environments

The key design problem was that Hyper-V lives on the Windows host while EVE-NG lives on Ubuntu. `DC-LAB` was intentionally an internal Hyper-V switch, so a direct Internet-facing switch was not used.

```text
Windows Hyper-V DC-LAB ↔ SoftEther VPN Server / Hub BRIDGE
                               ║ encrypted Layer-2 transport
Ubuntu br-eve          ↔ SoftEther VPN Bridge / Hub BRIDGE
                               ║
                            EVE cloud
```

The local bridge was verified with `BridgeList` showing `br-eve` as `Operating`. The service check `systemctl is-active softether-vpnbridge` only proves the daemon is running; `CascadeList` proves the remote transport is established.

### Before SoftEther: the failed direct path

SoftEther was not the starting point. The first attempt tried to connect the EVE/Ubuntu side directly to the Hyper-V internal-switch side. It was not a stable, repeatable Layer-2 path across the two virtualisation boundaries, so the design was split into a transport layer (SoftEther) and a lab layer (EVE/R1). This failed attempt is part of the learning outcome, not something to hide.

## Phase 3 — routing and VLANs in EVE

R1 has two different designs because the physical links carry different numbers of VLANs:

```text
SW1 ── trunk ── R1 e0/0
                   ├── e0/0.10  VLAN 10  10.10.10.1   server segment
                   └── e0/0.20  VLAN 20  10.10.20.1   client segment

SW2 ── access VLAN 30 ── R1 e0/1 10.10.30.1
       (R1 + Win10 + PC3 are all access VLAN 30)
```

This taught the practical rule: one VLAN across a link can be an access link; multiple VLANs across a single link require a trunk and router subinterfaces.

## Phase 4 — DHCP relay and proof with tcpdump

DHCP runs on the server segment, while VLAN 20 and 30 clients are remote. Therefore the helper is on R1's Layer-3 gateway interfaces—not on Layer-2 switches.

```text
Client broadcast → R1 e0/0.20 or e0/1 → ip helper-address 10.10.10.20 → DHCP server
```

Packet capture supplied the most useful evidence: a Discover reached the DHCP server with R1's gateway address in the relay field. That split the fault domain: transport and helper forwarding were working; any missing Offer had to be investigated on DHCP scope/options/return handling.

An earlier DHCP scope used the wrong network (shown here as `10.99.100.0/24`). It was replaced with the intended server scope; in this public example that is `10.10.10.0/24`. The relay address and the selected scope must describe the same routed design.

## Phase 5 — problems found and corrected

1. **Duplicate gateway address:** the Hyper-V host management adapter and R1 both held the VLAN 10 gateway address. This caused ARP ambiguity. The host was moved to the example management address `10.10.10.254`; R1 remained the sole gateway at `.1`.
2. **Wrong SW2 access membership:** R1 was in VLAN 30 but some Windows/VPCS-facing ports were still VLAN 1. The relevant SW2 ports were placed in access VLAN 30.
3. **Correct lease, wrong gateway:** a VLAN 30 client received an address but a router option from a different subnet. The per-scope router option was corrected to `10.10.30.1`.
4. **Confusing DNS and Internet routing:** DC DNS was retained as client DNS; R1 became the path to the Internet.
5. **Changing Wi-Fi address:** a Cascade configured to a transient Wi-Fi address broke after the Wi-Fi network changed. The target was changed to a stable SoftEther DDNS/FQDN such as `vpn-lab.example.net:443`.
6. **NAT on the wrong interface:** NAT inside belongs on R1's routed subinterfaces and LAN interface, not the trunk parent interface.
7. **systemd unit syntax:** an `Assignment` line outside the service section made the SoftEther unit invalid. The unit was corrected, reloaded, enabled, and checked for both `active` and `enabled` state.
8. **Bridge assumptions:** the working path used `br-eve`; no TAP device was required. `BridgeList` was the authoritative test.

## Phase 6 — final working behaviour

```text
VLAN 20/30 client
  → R1 (its own subnet gateway)
  → VLAN 10 / SoftEther / Hyper-V
  → DHCP, DNS, AD, SMB services

VLAN 20/30 client
  → R1 inside
  → R1 e0/3 outside
  → libvirt NAT network
  → Internet
```

The final checks are recorded in [Test plan](test-plan.md). Only after DHCP, gateway, DNS, and DC reachability pass should a Windows client be domain-joined.
