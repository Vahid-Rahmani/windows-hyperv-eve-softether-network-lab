# LinkedIn portfolio kit

This page contains copy that can be used for a LinkedIn profile and a portfolio post. It is written to accurately describe the lab without claiming a certification credential, employer, or production deployment that has not been independently verified.

## Suggested headline

```text
Network Engineer | Windows Server, Hyper-V, EVE-NG & Cisco Labs | CCNA Learning Path Completed | Working toward CCNP and CCIE
```

If an official Cisco credential is held, replace `CCNA Learning Path Completed` with the exact credential name only after adding the credential's verification URL or ID in LinkedIn's Licenses & Certifications section.

## Suggested About section

```text
I build hands-on network and infrastructure labs that connect Windows Server services with Cisco routing and switching in EVE-NG.

My recent project integrated Active Directory, DNS, DHCP, SMB file services, Hyper-V, Ubuntu/KVM, EVE-NG, SoftEther Layer-2 bridging, VLAN routing, DHCP relay, and Cisco NAT/PAT. The work was documented as a troubleshooting journey: from an unreliable direct Hyper-V-to-EVE connection to a validated bridge, correct DHCP scopes, per-VLAN gateway options, and Internet access through R1.

My CCNA learning path is complete. I am now building deeper routing, switching, troubleshooting, automation, and enterprise-design skills while working toward CCNP and, long term, CCIE.

I value evidence-based troubleshooting: verify the link, bridge, VLAN, route, DHCP relay, DNS, and NAT in that order.
```

## Suggested Skills section

Add only skills that genuinely represent your work:

```text
Cisco IOS | Routing and Switching | VLANs | Inter-VLAN Routing | DHCP Relay
Windows Server | Active Directory | DNS | DHCP | Hyper-V
EVE-NG | KVM/QEMU | Ubuntu Linux | SoftEther VPN | NAT/PAT
Network Troubleshooting | tcpdump | PowerShell | Systemd
```

## Ready-to-post project update

```text
I completed a multi-platform network lab that took several weeks of building, testing, troubleshooting, and documenting.

The goal was to connect a Windows Server environment in Hyper-V with a Cisco topology in EVE-NG running on Ubuntu/KVM.

What the final lab includes:
- Active Directory, DNS, DHCP, and SMB services on Windows Server
- Hyper-V internal networking carried to EVE-NG through a SoftEther Layer-2 bridge
- Cisco R1 router-on-a-stick with VLAN routing
- DHCP relay validated with packet capture
- Correct per-scope DHCP gateway/DNS settings
- Internet access through Cisco NAT/PAT

The most valuable part was the troubleshooting path: an unreliable direct Hyper-V-to-EVE connection, an ARP conflict, incorrect DHCP scope/options, a changing Wi-Fi transport address, SoftEther service repair, and NAT placement all had to be diagnosed layer by layer.

My CCNA learning path is complete. Next, I am focusing on CCNP-level routing, switching, troubleshooting, and enterprise design, with CCIE as a long-term goal.

Project documentation and topology:
https://github.com/Vahid-Rahmani/windows-hyperv-eve-softether-network-lab

#Networking #Cisco #CCNA #CCNP #CCIE #WindowsServer #HyperV #EVENG #Linux #NetworkEngineering #Homelab
```

## Image and repository links

* Editable topology: `assets/eve-ng-simple-real-topology.svg`
* LinkedIn-ready PNG: `assets/eve-ng-simple-real-topology-linkedin.png`
* Main project page: `README.md`
* Full troubleshooting narrative: `docs/complete-project-case-study.md`

Before publishing, attach the image and read the final post once. The topology image intentionally uses the owner's real private lab addresses. Do not add passwords, VPN hostnames, Wi-Fi addresses, or domain credentials.
