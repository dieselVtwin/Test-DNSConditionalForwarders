# Test-DNSConditionalForwarders

## Overview

**Test-DNSConditionalForwarders** is a PowerShell script to check servers listed in DNS Conditional Forwarders for working as an DNS server and measuring how fast they reply to PING command.

## How to use it and what it requires?

Simply download script to your local DNS server and run it with command:

```powershell
.\Test-DNSConditionalForwarders.ps1
```

### Parameters

By default the script shows progress bar and summary at the end of its work.

If you want to know what it actually doing you can run it with parameter *-verbose*, like below:

```powershell
.\Test-DNSConditionalForwarders.ps1 -verbose
```

### Requirements

* As script getting information about Conditional Forwarder zones from local DNS server using CIMInstance, it must be run at Windows Server with DNS role installed.

* Because of above it also require to be run with administrators rights.

---

## What it can be used for?

It can be used for maintaing **Conditional Forwarders Zones** in DNS servers which you administrate.
For example, running it regularly you will know:

* if servers listed in Conditional Forwarders are still accessible

* if they accessible, are they still working as DNS servers

* by using PING you will know how fast is the connection to them

* it will sort servers by ping results - may be helpful to know if you should change the order of the servers in Conditional Forwarder zone

*Example of results:*

```powershell
RESULTS FOR ZONE xx.xx.xx.xx
Lp IPAddress       Test DNS   Round Trip Time Ping Pass/Fail Ping avg. time (ms)
-- ---------       --------   --------------- -------------- -------------------
 1 xxx.xxx.xxx.xxx Success    00:00:00        10/0                             3
 2 xxx.xxx.xxx.xxx Success    00:00:00        10/0                           6,2
 3 xxx.xxx.xxx.xxx Success    00:00:00        10/0                           8,7
 .
 .
 .
18 xxx.xxx.xxx.xxx NoResponse 00:00:12        0/10                           n/d
19 xxx.xxx.xxx.xxx NoResponse 00:00:12        0/10                           n/d
20 xxx.xxx.xxx.xxx NoResponse 00:00:12        0/10                           n/d
```

## How it works?

1. By using the cmdlet [Test-DnsServer](https://docs.microsoft.com/en-us/powershell/module/dnsserver/test-dnsserver?view=win10-ps) it checks if the server is working as a DNS and returns either "Success" or "NoResponse" for each server and it shows the Round Trip Time (RRT).

2. By using the PING command it checks each server if it responds to the ICMP packets, and how fast it will do it. By default the script sends PING for 10 times, and then it calculates the average score.
