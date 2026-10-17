# Evidence from my current lab

This page covers my report, original EVE-NG drawing, earlier command output and the three monitoring screenshots from 17 October 2026.

| Material | What it establishes | Limit |
| --- | --- | --- |
| [German report](reports/Abschlussprojekt_Vahid_Rahmani_DE.pdf) | Decisions, course-task mapping, diagrams and test summary | Does not replace every required task screenshot |
| [Original topology](../assets/two-site-topology.png) | Intended links, VLANs, sites, storage and cluster identities | Earlier names and planning labels remain |
| [Overview](../assets/screenshots/monitoring-overview.png) | UI reports AD discovery successful, 10 hosts, 9 WinRM reachable and 9 with measurements | A snapshot, not an availability history |
| [Host list](../assets/screenshots/monitoring-hosts.png) | Windows DNS names, IP addresses and readings from both sites | Last row partly cut off |
| [Cluster service view](../assets/screenshots/monitoring-cluster-services.png) | TW-FS01 SMB endpoint reachable; TW-CLUSTER role state unverified | Not a file-access or failover result |

## Network observations

BridgeList reported BRIDGE → br-eve Operating. CascadeList reported WINDOWS-DC-LAB Online (Established). R1 received five of five replies from 192.168.10.10, with 4/8/16 ms reported minimum/average/maximum round trips.

DHCP scope output showed active ranges for subnets 10, 20 and 30, from .100 to .200. The DHCP problem was subsequently reported as resolved.

Capture on br-eve showed Hyper-V ARP requests while the expected gateway reply was missing. This narrowed the search. Proposed repair steps are not automatically the proven cause of a later successful ping.

## Monitoring observations

The overview displays averages of 3.4% CPU, 77.5% RAM and 45.8% system-drive usage across nine reporting hosts. Overview and host list were captured at different times; their values need not reproduce the same average.

CLI-01.kurs.intern, 192.168.10.102, has no WinRM response. This does not distinguish a switched-off client from firewall or other reachability problems. Its missing metrics are unavailable, not zero.

The service identities are excluded from the ten-host count. TW-FS01 is 192.168.40.20; TW-CLUSTER is 192.168.40.25. The latter's cluster role state is unverified in the screenshot.

## Results still needing a record here

- A current report of two-site AD replication.
- Automatic failover followed by a successful file open through the unchanged share.
- Backup recovery, distinct from a successful backup run.
- Individual screenshots for every course task A1–A13.
- Any claim of continuous uptime or complete security hardening.

The course work is recorded as completed in my project workflow. This page identifies which results the published material can actually support. The next checks are in the [test plan](test-plan.md).
