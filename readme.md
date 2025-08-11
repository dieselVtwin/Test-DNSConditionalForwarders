# Test-DNSConditionalForwarders

## Overview

**Test-DNSConditionalForwarders** is a PowerShell script which checking servers listed in DNS Conditional Forwarders for working as an DNS server and measuring how fast they reply to PING command.

## How to use it and what it requires?

Simply download script to your local DNS server and run it with command:

```powershell
.\Test-DNSConditionalForwarders.ps1

```

## Parameters

By default script shows progress bar and summary at the end of its work. But if you want to know what it actually doing you can run it with parameter *-verbose*, like below:

```powershell
.\Test-DNSConditionalForwarders.ps1 -verbose

```

## Requirements

* As script getting information about Conditional Forwarder zones from local DNS server using CIMInstance, it must be run at Windows Server with DNS role installed.  
* Because of above it also require to be run with administrators rights.

---

## For what it can be used?

It can be used for maintaing **Conditional Forwarders Zones** in DNS server which you administrating.
For example, once in a month, by running it you will know:

* if servers listed in Conditional Forwarders are still accessible,
* if they accessible, is they still working as a DNS servers?
* by using PING you will know how fast is connection to them
* it will sort servers by ping results - knowing that you could change order of servers in Conditional Forwarder zone.

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

1. By using cmdlet [Test-DnsServer](https://docs.microsoft.com/en-us/powershell/module/dnsserver/test-dnsserver?view=win10-ps) it checking if server working as a DNS (it will return "Success" or "NoResponse") and it shows Round Trip Time (RRT).
2. By using PING command it checking if server respond to ICMP packets, and how fast it will do it. By default script run ping for 10 times, and then it calculate average score.
