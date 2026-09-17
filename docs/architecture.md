# Architecture and traffic paths

## Final topology

The Windows 11 host supplies an **internal** Hyper-V vSwitch named `DC-LAB`. An internal switch does not give its attached VMs Internet access. That is deliberate: R1 is the only lab router and provides the route and NAT path.

```text
Windows 11 / Hyper-V                         Ubuntu / EVE-NG
--------------------                         ----------------
DC-LAB (internal switch) ← SoftEther → VPN Bridge / br-eve ← EVE cloud
  ├─ DC/DNS 10.10.10.10                              └─ R1 e0/0.10 (VLAN 10)
  ├─ DHCP   10.10.10.20                                 ├─ e0/0.20 (VLAN 20)
  └─ host management .254                              ├─ e0/1 (LAN 30)
                                                       └─ e0/3 → virbr0 → Internet
```

`br-eve` is a Layer-2 attachment for the VPN bridge, not a routed host interface. A missing host IP on `br-eve` is not by itself a bridge failure.

## Routing and switching roles

* **R1** owns each client subnet's default gateway. It routes between VLANs and to the WAN.
* **SW1** is Layer 2: the R1 uplink is an 802.1Q trunk for VLANs 10 and 20. Server ports belong to VLAN 10; EVE client ports belong to VLAN 20.
* **SW2** is Layer 2: both R1 and client ports are access VLAN 30. No trunk is needed because only VLAN 30 traverses that link.
* **DHCP** creates scopes and returns address options. It does not create the routed subnet.
* **DNS** translates names. It is not the Internet gateway.

## DHCP relay path

For a VLAN 20 client, the DHCP Discover broadcast cannot cross a router unaided. R1 receives it on `e0/0.20`, sets `giaddr`/Gateway-IP to `10.10.20.1`, and unicasts it to `10.10.10.20` due to `ip helper-address`.

The observed packet evidence was:

```text
10.10.20.1.67 > 10.10.10.20.67
Gateway-IP 10.10.20.1
DHCP-Message: Discover
```

That proves the request crossed EVE, `br-eve`, SoftEther, and reached the DHCP server-side segment. DHCP chooses the scope from the relay address, so it needs an active `10.10.20.0/24` scope with `10.10.20.1` as Router option.

## Internet path

```text
Client → R1 inside interface → R1 e0/3 (PAT/NAT outside)
       → 172.20.122.1 libvirt virbr0 → Ubuntu Wi-Fi → Internet
```

The NAT rule references the WAN **interface**, not a hard-coded address. Therefore a DHCP-renewed e0/3 address does not require changing the NAT rule.

## SoftEther transport

The early Cascade endpoint was a changing Windows Wi-Fi address such as `10.99.1.50`. It stopped working when the Wi-Fi network/address changed, for example to `10.99.2.50`. The working endpoint was changed to a SoftEther DDNS/FQDN:

```text
vpn-lab.example.net:443
```

This FQDN is the connection target; it is distinct from the lab's private IP plan and must remain resolvable from Ubuntu. The conversation also considered a dedicated wired `/30` transport, but it was a recommendation rather than a confirmed deployed final state.
