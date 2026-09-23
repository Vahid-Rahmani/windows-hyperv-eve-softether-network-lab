#!/usr/bin/env bash
# Reference commands only. Do not store SoftEther passwords in scripts or Git.

# Service state.
systemctl is-active softether-vpnbridge
systemctl is-enabled softether-vpnbridge
systemctl status softether-vpnbridge --no-pager
# If a unit edit reports "Assignment outside of section":
# sudo systemctl daemon-reload
# sudo systemctl enable softether-vpnbridge
# sudo systemctl restart softether-vpnbridge

# Capture DHCP traffic at the EVE/SoftEther bridge. Trigger a client renewal while it runs.
sudo tcpdump -vvv -s0 -eni br-eve 'udp port 67 or udp port 68'

# Connectivity checks (a bridge without a host IP need not answer ping itself).
ping -c 4 10.10.10.10
ping -c 4 10.10.10.20

# Enter SoftEther management. In vpncmd select server administration, then hub BRIDGE.
cd /usr/local/vpnbridge
sudo ./vpncmd

# vpncmd commands:
# Hub BRIDGE
# CascadeList
# BridgeList
# CascadeOffline WINDOWS-DC-LAB
# CascadeSet WINDOWS-DC-LAB /SERVER:vpn-lab.example.net:443 /HUB:BRIDGE
# CascadeUsernameSet WINDOWS-DC-LAB /USERNAME:bridge-user
# CascadePasswordSet WINDOWS-DC-LAB /TYPE:standard
# CascadeOnline WINDOWS-DC-LAB
