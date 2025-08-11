###################################################################################################
##### THIS SCRIPT MUST BE RUN FROM  WINDOWS 2012 ENVOIREMENT OR ABOVE WITH DNS ROLE INSTALLED  ####
################################ AND WITH ADMINISTRATOR RIGHTS ####################################

# Skrypt można uruchamiać z parametrem -verbose


[CmdletBinding()]
    param (
    #tutaj można definiować parametry, które mają być przekazywane przy uruchamianiu skryptu
    #na chwilę obecną głównie po to, aby można było uruchomić skrypt z parametrem -verbose
    )

$pNumber_pPings = 3 # ile razy ping ma badać dostępność serwera? Tę zmienną można ustawiać wg potrzeb. 


#pobieram strefy typu Conditional Forwarder z DNSa. Dlatego skrypt ten musi być uruchamiany na maszynie na której znajduje się serwer DNS.
#$strefy = Get-WmiObject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -Filter "ZoneType = 4" | Select-Object Name, MasterServers
$strefy = Get-CimInstance -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Zone -property "Name", "MasterServers" -filter "zonetype = 4"

# Rozpoczynam testowanie stref
$strefy | ForEach-Object {

    # Tablica przechowująca wyniki testów. Za każdą iteracją pętli ForEach-Object tworzona od nowa, aby zawierała dane tylko aktualnej strefy
    $rezultat = @() 

    # Nazwę strefy przypisuję do zmiennej
    $strefa =  $_ | Select-Object "Name"

    Write-Verbose "STREFA $($strefa | Select-Object -ExpandProperty Name)"

    # Serwery należące do strefy przypisuję do zmiennej
    $serwery = $_."MasterServers"
    # Zliczam listę serwerów - potrzebne dla progress bara i lp.
    $pNumber_serwerow =  $serwery.count
    # Zmienna będąca iteratorem pętli badającej serwery. Potrzebne dla progress bara i lp.
    $iterator_serwerow = 1 



    # Rozpoczynam testowanie serwerów w strefie
    $serwery | ForEach-Object {
        
        $iterator_pPings = 1# iterator pętli w której wykonywane są pingi
        $iterator_lp = 1    # zmienna będąca iteratorem pętli, numerującej kolumnę lp w obiekcie $rezultat. Numerowanie wyników wykonywane jest dopiero po ich posortowaniu wg wyników testu DNS i PING.
        $ping_ok = 0        # zmienna przechowująca wyniki pingów typu PASS
        $ping_nie_ok = 0    # zmienna przechowująca wyniki pingów typu FAIL
        $czas_start = [system.diagnostics.stopwatch]::StartNew()

        # progress bar
        Write-Progress -Id 1 -Activity “Testing servers for zone $($strefa | Select-Object -ExpandProperty Name)” -status “Server $iterator_serwerow z $pNumber_serwerow ($_)” -percentComplete ($iterator_serwerow / $pNumber_serwerow*100)

        Write-Verbose "$iterator_serwerow. $_"
        
        ############################################################## TESTY PING ##############################################################
        # test DNS
        Write-Verbose " DNS Test..."
        Write-Progress -Id 2 -Activity "DNS Test..."
        $wynik_testdns = Test-DnsServer $_
        Write-Verbose " - $($wynik_testdns.Result)"

        ############################################################## TESTY PING ##############################################################
        # test PING
        DO{
            Write-Verbose " PING Test nr $iterator_pPings of $pNumber_pPings..."
            Write-Progress -Id 2 -Activity "PING Test $iterator_pPings of $pNumber_pPings..."
            # Pinguję sewer
            #$ping = get-wmiobject -Query "select * from win32_pingstatus where Address='$_'"
            $ping = Get-CimInstance -Query "select * from win32_pingstatus where Address='$_'"

            # Jeżeli PING uzyskał odpowiedź
            if ($ping.statuscode -eq 0) {
                Write-Verbose " - $($ping | Select-Object -ExpandProperty ResponseTime)ms"
                $suma_pPings += $ping.ResponseTime
                $ping_ok++;
            }
            # Jeżeli PING nie uzyskał odpowiedzi
            else {
                Write-Verbose " - Server did not respond to PING."
                $ping_nie_ok++;
            }

            # zmienna zliczająca ile pingów zostało wykonanych
            $iterator_pPings++

        } While ($iterator_pPings -le $pNumber_pPings)

        # testy DNS i PING zostały zakończone, więc zmienna iteracyjna serwerów zwiększana jest o 1. Wykorzystywana chyba tylko do progress bara 
        $iterator_serwerow++


        ###################################### OBLICZANIE ŚREDNIEJ Z PINGÓW I TWORZENIE OBIEKTU PRZECHOWUJĄCEGO WYNIKI ###############################     
        # obliczanie średniej z pingów
        if (($ping_nie_ok+1) -eq $iterator_pPings){
            $srednia_pPings = "n/d"
        }
        else {     
            $srednia_pPings = $suma_pPings / ($iterator_pPings-1)
            $srednia_pPings = [math]::round($srednia_pPings,2)
        }

        
        #Tworzę obiekt z wynikami testów DNS i Ping
        $rezultat += New-Object psobject -Property @{
            Lp = 1
            IPAddress = $wynik_testdns.IPAddress
            Result = $wynik_testdns.Result
            RoundTripTime = $wynik_testdns.RoundTripTime
            TcpTried = $wynik_testdns.TcpTried
            UdpTried = $wynik_testdns.UdpTried
            Pingi = "$ping_ok/$ping_nie_ok"
            Srednia_pPings = $srednia_pPings
        }


        ########################################################## CZYSZCZENIE ZAWARTOŚCI ZMIENNYCH ###################################################
        Clear-Variable -Name "srednia_pPings" -Scope Script
        #Clear-Variable -Name "suma_pPings" -Scope Script

    }# koniec pętli ForEach-Object przetwarzającej serwery ze strefy

    # czyszczenie zmiennej zliczającej ilość testowanych serwerów. Ta zmienna potrzebna jest tylko do progress bara.
    Clear-Variable -Name "iterator_serwerow" -Scope Script 


    ######################################################### SORTOWANIE REZULTATÓW I WYŚWIETLANIE WYNIKÓW ################################################
    # sortowanie rezultatów w tablicy wg testu dns i pingów
    $rezultat = $rezultat | Sort-Object @{expression="Result";Descending=$true}, @{expression="Srednia_pPings";Ascending=$true}

    # dopiero po posortowaniu wyników numerowana jest kolumna lp w obiekcie z wynikami.
    $rezultat | ForEach-Object {
        $_.lp = $iterator_lp
        $iterator_lp ++
    }


    # wyświetlana nazwa strefy
    Write-Output "RESULTS FOR ZONE $($strefa | Select-Object -ExpandProperty Name)"

    #wyświetlanie wyników
    Write-Output ($rezultat | Format-Table -property "Lp", "IPaddress", @{LABEL="Test DNS";Expression="Result"}, @{LABEL="Round Trip Time";Expression="RoundTripTime"}, @{LABEL="Ping Pass/Fail";Expression="Pingi"}, @{LABEL="Ping avg. time (ms)";Expression="Srednia_pPings"} | Out-String)

    Clear-Variable -Name "rezultat" -Scope Script 
    Clear-Variable -Name "iterator_lp" -Scope Script

}#koniec przetwarzania pętli ForEach-Object ze strefą Conditional Forwarder
