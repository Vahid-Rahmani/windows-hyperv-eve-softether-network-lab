# Validation checklist for the expanded lab

These are checks to repeat, not a claim that all have passed. Recorded results are on the [evidence page](evidence.md). The [earlier plan](archive/test-plan-first-version.md) uses the first version's example addresses.

## Transport

On Linux, check ip -br link, bridge membership and the actual installed SoftEther service. In vpncmd, select BRIDGE and inspect BridgeList and CascadeList. The recorded working pair was br-eve Operating and WINDOWS-DC-LAB Online (Established).

Do not start a competing daemon merely because a guessed systemd unit name is absent.

## VLANs and routing

Inspect R1 interfaces, routes and ARP. On the relevant switch, inspect VLAN membership, trunks and the dynamic MAC table. Both uplinks are trunks in this version.

Compare the gateway ARP entry with R1's actual MAC. The Hyper-V host must not duplicate 192.168.10.1. A Windows Destination host unreachable message is not an echo reply, even if the packet counter says Received.

The recorded R1-to-192.168.10.10 test returned five of five replies.

## DHCP and DNS

Renew a client in each VLAN with an intended scope. Inspect ipconfig /all on Windows or show ip on VPCS. Confirm its subnet, mask, gateway, internal DNS and DHCP server.

If offers are absent, check scope selection, the router helper, the return route and permitted DHCP traffic. A capture on br-eve with the filter udp port 67 or udp port 68 helps follow the request and reply.

Test external IP and DNS reachability from a client. Inspect R1 NAT translations during that traffic. A test initiated only on R1 is not a client test.

## AD and permissions

Inspect the actual sites, subnet associations and DC objects. Retain repadmin /replsummary and repadmin /showrepl output from an authorised session.

Use a normal domain account to record one allowed file operation and one denied operation. Check both share and NTFS permissions. For the wallpaper GPO, record its effective user scope or loopback handling and the client result.

## Cluster

1. Save the validation report, including warnings.
2. Inspect both nodes, data LUN, witness and quorum.
3. Record the current file-server owner.
4. Open a test file through **\\TW-FS01\Shares** from an authorised client.
5. A manual role move is a planned switch. For automatic failover, safely shut down the active node during a lab test and observe the role on the surviving node.
6. Reopen the file through the same name and record any interruption.

An open TCP 445 port on .40.20 is not a substitute. This guest cluster does not remove the single storage server or physical host as failure points.

## Backup and monitoring

Keep the successful backup event and daily 23:00 schedule. Restore into a separate test location before claiming recovery is verified.

Check a monitored host from each site, timestamps and missing-data states. The supplied run shows nine of ten hosts with telemetry. Investigate CLI-01 separately. Exclude virtual service identities from host counts and hardware averages.

Never publish passwords, recovery keys or credential exports as proof of a test.
