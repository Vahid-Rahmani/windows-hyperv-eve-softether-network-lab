# Application services and optional extensions

This document records the service-side exercises from the wider lab journey. It separates confirmed core infrastructure from optional experiments so a reader can reproduce the work without assuming every idea was a completed production feature.

All addresses are safe examples. See [Example IP plan](example-ip-plan.md).

## Windows Server services used by the core lab

| Service | Example host | Role in the lab |
| --- | --- | --- |
| AD DS and DNS | `10.10.10.10` | Domain authentication and authoritative DNS for `kurs.intern` |
| DHCP and SMB | `10.10.10.20` | Scope delivery through R1 relay and the `Firma` file share |
| R1 | `10.10.10.1`, `.20.1`, `.30.1` | Client gateways, DHCP relay, and NAT/PAT |

### File-server and identity practice

The Windows service work included OUs, users, global groups, domain-local groups, and an AGDLP-style path to share permissions. The `Firma` share contained departmental folders, including a restricted payroll folder. These exercises highlighted practical checks:

* Verify the exact folder/share name before changing ACLs; a spelling mismatch can look like a permission failure.
* Share access and NTFS access are evaluated together; changing one is not always enough.
* For a confirmed administrator-recovery case, take ownership and restore an intended ACL. Do not apply broad permissions to an unverified path.

Example recovery commands, to be used only after confirming the target path and policy:

```powershell
takeown /F 'C:\Firma\Lohn' /R /D Y
icacls 'C:\Firma\Lohn' /grant 'Administrators:(OI)(CI)F' /T
```

## Docker/nginx learning path

Docker was explored on the application-server side as a separate service exercise. A failure to pull from a registry, expressed as a name-resolution error, is evidence to check DNS and Internet routing before treating it as a Dockerfile issue.

```text
Dockerfile -> docker build -> image -> docker run -> container
```

The working syntax requires a build context; the final dot is meaningful:

```powershell
docker build -t hello-docker .
docker run --rm -p 8080:80 hello-docker
```

If an image pull fails in this lab, validate in this order:

1. `ipconfig /all` shows DNS `10.10.10.10` and the correct R1 gateway.
2. The DNS server has a usable forwarder for public names.
3. The client can reach an Internet IP through R1 NAT.
4. `nslookup registry-1.docker.io` succeeds.
5. Retry the Docker action.

An offline environment may also need a preloaded image or an approved internal registry. That is a deployment constraint, not a reason to weaken DNS or NAT verification.

## Optional virtual-printer extension

EVE-NG does not provide a native printer node. Two realistic ways to represent a network printer are:

| Option | What it teaches | Status in this repository |
| --- | --- | --- |
| Windows Print Server | Shared queue, AD permissions, and GPO deployment such as `\\PRINT01\\Office-Printer` | Documented extension |
| Linux/Red Hat + CUPS | IPP, Linux services, firewall, SELinux, and an EVE endpoint | Documented extension |

For a Red Hat endpoint inside EVE, begin by identifying the installed release and actual interface names:

```bash
cat /etc/redhat-release
ip addr
ip route
```

If the VM is intentionally placed on a separate printer segment, use an example such as VLAN 60 `10.10.60.0/24`, with R1 at `10.10.60.1` and the CUPS VM at `10.10.60.10`. This segment was proposed as an extension; confirm that it exists before adding it to a live topology.

Example CUPS setup on a supported Red Hat release:

```bash
sudo dnf install cups
sudo systemctl enable --now cups
systemctl status cups
sudo firewall-cmd --add-service=ipp --permanent
sudo firewall-cmd --reload
lpstat -t
```

SELinux policy and the exact CUPS queue configuration depend on the release and intended client protocol, so they are `[confirm]` items rather than hard-coded claims.

## Why these exercises belong in the case study

The network was built to make services usable, not only to pass pings. File shares, domain DNS, application pulls, and a planned print endpoint each test a different part of the same chain: identity, name resolution, gateway selection, routing, NAT, and firewall policy.
