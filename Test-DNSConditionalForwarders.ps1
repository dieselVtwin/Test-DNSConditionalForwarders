###################################################################################################
##### THIS SCRIPT MUST BE RUN FROM  WINDOWS 2012 ENVOIREMENT OR ABOVE WITH DNS ROLE INSTALLED  ####
################################ AND WITH ADMINISTRATOR RIGHTS ####################################

# The script can be run with the -verbose parameter


[CmdletBinding()]
    param (
    #here you can define parameters to be passed when running the script
    #for now, this is mainly to allow the script to be run with the -verbose parameter
    )

$pNumber_pPings = 3 # How many times should ping check server availability? This variable can be set as needed.


#I'm downloading Conditional Forwarder zones from DNS. Therefore, this script must be run on the machine hosting the DNS server.
#$pZones = Get-WmiObject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -Filter "ZoneType = 4" | Select-Object Name, MasterServers
$pZones = Get-CimInstance -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -property "Name", "MasterServers" -filter "zonetype = 4"

# I'm starting to test the zones
$pZones | ForEach-Object {

    # An array storing test results. It is recreated with each iteration of the ForEach-Object loop to contain only the data for the current zone.
    $pResult = @() 

    # I assign the name zones to the variable
    $pZone =  $_ | Select-Object "Name"

    Write-Verbose "Zone $($pZone | Select-Object -ExpandProperty Name)"

    # I assign servers belonging to zones to a variable
    $pServers = $_."MasterServers"
    # I'm counting the server list - needed for the progress bar and lp.
    $pNumber_pServerList =  $pServers.count
    # A variable that is an iterator for the loop examining servers. Needed for the progress bar and lp.
    $iterator_pServerList = 1 



    # I'm starting to test servers in the zone
    $pServers | ForEach-Object {
        
        $iterator_pPings = 1# iterator of the loop in which pings are performed
        $iterator_lp = 1    # a variable that is an iterator for the loop that numbers the lp column in the $pResult object. The results are numbered only after they are sorted by the DNS and PING test results.
        $ping_ok = 0        # a variable storing the results of pings that PASS
        $ping_not_ok = 0    # a variable storing the results of pings that FAIL
        $time_start = [system.diagnostics.stopwatch]::StartNew()

        # progress bar
        Write-Progress -Id 1 -Activity “Testing servers for zone $($pZone | Select-Object -ExpandProperty Name)” -status “Server $iterator_pServerList z $pNumber_pServerList ($_)” -percentComplete ($iterator_pServerList / $pNumber_pServerList*100)

        Write-Verbose "$iterator_pServerList. $_"
        
        ############################################################## TESTS PING ##############################################################
        # test DNS
        Write-Verbose " DNS Test..."
        Write-Progress -Id 2 -Activity "DNS Test..."
        $wynik_testdns = Test-DnsServer $_
        Write-Verbose " - $($wynik_testdns.Result)"

        ############################################################## TESTS PING ##############################################################
        # test PING
        DO{
            Write-Verbose " PING Test nr $iterator_pPings of $pNumber_pPings..."
            Write-Progress -Id 2 -Activity "PING Test $iterator_pPings of $pNumber_pPings..."
            # I'm pinging the server
            #$ping = get-wmiobject -Query "select * from win32_pingstatus where Address='$_'"
            $ping = Get-CimInstance -Query "select * from win32_pingstatus where Address='$_'"

            # If PING got a response
            if ($ping.statuscode -eq 0) {
                Write-Verbose " - $($ping | Select-Object -ExpandProperty ResponseTime)ms"
                $suma_pPings += $ping.ResponseTime
                $ping_ok++;
            }
            # If PING did not get a response
            else {
                Write-Verbose " - Server did not respond to PING."
                $ping_not_ok++;
            }

            # a variable counting how many pings have been performed
            $iterator_pPings++

        } While ($iterator_pPings -le $pNumber_pPings)

        # DNS and PING tests have been completed, so the server iteration variable is incremented by 1. Probably only used for the progress bar
        $iterator_pServerList++


        ###################################### AVERAGING THE PINGS AND CREATING AN OBJECT TO STORE THE RESULTS ###############################
        # calculating the average of pings
        if (($ping_not_ok+1) -eq $iterator_pPings){
            $srednia_pPings = "n/d"
        }
        else {     
            $srednia_pPings = $suma_pPings / ($iterator_pPings-1)
            $srednia_pPings = [math]::round($srednia_pPings,2)
        }

        
        # I create an object with DNS and Ping test results
        $pResult += New-Object psobject -Property @{
            Lp = 1
            IPAddress = $wynik_testdns.IPAddress
            Result = $wynik_testdns.Result
            RoundTripTime = $wynik_testdns.RoundTripTime
            TcpTried = $wynik_testdns.TcpTried
            UdpTried = $wynik_testdns.UdpTried
            Pingi = "$ping_ok/$ping_not_ok"
            Srednia_pPings = $srednia_pPings
        }


        ########################################################## CLEARING VARIABLE CONTENT ###################################################
        Clear-Variable -Name "srednia_pPings" -Scope Script
        #Clear-Variable -Name "suma_pPings" -Scope Script

    }# end of the ForEach-Object loop processing servers from zones

    # Clearing the variable counting the number of servers being tested. This variable is only needed for the progress bar.
    Clear-Variable -Name "iterator_pServerList" -Scope Script 


    ######################################################### SORTING AND DISPLAYING RESULTS ################################################
    # sorting results in the table by DNS and ping test
    $pResult = $pResult | Sort-Object @{expression="Result";Descending=$true}, @{expression="Srednia_pPings";Ascending=$true}

    # only after the results are sorted, the number column in the results object is numbered.
    $pResult | ForEach-Object {
        $_.lp = $iterator_lp
        $iterator_lp ++
    }


    # displayed name zones
    Write-Output "RESULTS FOR ZONE $($pZone | Select-Object -ExpandProperty Name)"

    # displaying results
    Write-Output ($pResult | Format-Table -property "Lp", "IPaddress", @{LABEL="Test DNS";Expression="Result"}, @{LABEL="Round Trip Time";Expression="RoundTripTime"}, @{LABEL="Ping Pass/Fail";Expression="Pingi"}, @{LABEL="Ping avg. time (ms)";Expression="Srednia_pPings"} | Out-String)

    Clear-Variable -Name "pResult" -Scope Script 
    Clear-Variable -Name "iterator_lp" -Scope Script

} # end of ForEach-Object loop processing with Conditional Forwarder zone
