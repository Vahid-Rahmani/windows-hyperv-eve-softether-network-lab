# Build and validation runbook

## 1. Windows / Hyper-V foundation

1. Create or retain the Hyper-V **Internal** switch `DC-LAB`.
2. Put the DC/DNS server at `10.10.10.10/24` and DHCP server `SRV-APP01` at `10.10.10.20/24`.
3. Set their default gateway to `10.10.10.1` and DNS to `10.10.10.10`.
4. Give the Windows host's `vEthernet (DC-LAB)` management address `10.10.10.254/24`; leave its default gateway blank.

The host is not a router for the lab. Do not enable ICS, do not turn `DC-LAB` into an external switch, and do not attach lab VMs to the Hyper-V Default Switch.

## 2. EVE and SoftEther bridge

On Ubuntu, EVE-NG runs with KVM/virt-manager. Its lab cloud attaches through `br-eve`. The SoftEther VPN Bridge has a local bridge from hub `BRIDGE` to `br-eve` and a Cascade named `WINDOWS-DC-LAB` toward the Windows SoftEther server.

Use the FQDN transport endpoint after a Wi-Fi change:

```text
CascadeOffline WINDOWS-DC-LAB
CascadeSet WINDOWS-DC-LAB /SERVER:vpn-lab.example.net:443 /HUB:BRIDGE
CascadeUsernameSet WINDOWS-DC-LAB /USERNAME:bridge-user
CascadePasswordSet WINDOWS-DC-LAB /TYPE:standard
CascadeOnline WINDOWS-DC-LAB
CascadeList
```

`CascadePasswordSet` prompts interactively; no password belongs in this repository. The recorded healthy status was `Online (Established)` and `BridgeList` showed `BRIDGE | br-eve | Operating`.

## 3. R1 and switches

Apply the reference configuration in `configs/cisco/r1-reference.ios` only after comparing interface names to the actual appliance. Configure SW1 and SW2 as documented in that file. VLAN 20 and LAN 30 interfaces require the helper address because the DHCP server lives on VLAN 10.

## 4. DHCP and DNS

Create a scope per routed subnet, not one shared gateway option. The scope option 003 must match the scope:

```text
10.10.10.0/24 → 10.10.10.1
10.10.20.0/24 → 10.10.20.1
10.10.30.0/24 → 10.10.30.1
```

All clients can use DNS `10.10.10.10`. If public names are needed, configure forwarders on the DC; do not point domain clients directly at public DNS servers.

## 5. Validate in layers

Run the test plan in order. Stop at the first failed layer; that makes a broken path much easier to localise. For example, a lease with an unreachable gateway is a DHCP option error, while a Discover visible in tcpdump with no Offer points to the DHCP-server return path or scope handling.

## Domain join

After a Windows 10 client has an address, correct gateway, and DNS `10.10.10.10`:

```text
nslookup kurs.intern
sysdm.cpl → Computer Name → Change → Domain: kurs.intern
```

Use an authorized domain credential and restart when prompted. A network-connected computer is not automatically a domain member.
