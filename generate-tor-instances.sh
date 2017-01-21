#!/bin/bash
startAllInstances(){
	for i in $(ls /etc/tor/torrc*); do  
		proc=$(ps aux | grep -v grep | grep $i)
		if [ -z "$proc" ]; then 
			tor -f $i &
		fi 	
	done
}

killInstances() {
	killall tor
}

getAllRunning() {
	runList=$(ps aux | grep -v grep | grep torrc. | awk {'print $13'})
	for i in $(echo -e "$runList"); do
		port=$(grep -i "^SocksPort" $i | awk {'print $2'})
		echo "localhost:$port"
	done
}

getAvailableTorNumber() {
	lastTor=$(ls /etc/tor/torrc* | cut -d"." -f2 | grep -v "torrc" | sort -h | tail -1)
	case $lastTor in
    	''|*[!0-9]*) lastTor=1 ;;
	esac
	availableTor=$((lastTor+1))
	echo $availableTor
}

getAvailablePort() {
	for i in $(ls /etc/tor/torrc*); do 
		list=$list" "$(grep -i "^SocksPort" $i | awk {'print $2'})
	done
	if [ -z "$(echo "$list" | tr -d '\n')" ]; then list=9050; fi
	lastNumber=$(echo $list | tr ' ' '\n' | sort -h | tail -1)
	availabilePort=$((lastNumber+5))
	echo $availabilePort
}

generateNewTor() {
	torNumber=$1
	port=$(getAvailablePort)
	controlPort=$((port+1))

	cp -R /var/lib/tor /var/lib/tor$torNumber
	echo "SocksPort $port
	ControlPort $controlPort
	DataDirectory /var/lib/tor$torNumber" > /etc/tor/torrc.$torNumber
	tor -f /etc/tor/torrc.$torNumber 	&
	check=$(curl -s localhost:$port)
	check=$(echo -e $check | grep -i 'tor')
	if [ -n "$check" ]; then
		echo "localhost:$port appears to be working"
	fi
}

startGeneration() {
	numberOfTorInstancesToGenerate=$1
	for i in `seq 1 $numberOfTorInstancesToGenerate`; do
		generateNewTor $(getAvailableTorNumber) &
		wait
	done
}

displayHelp() {
cat << helpcontent
$0 [options]
	-r |--running	displays the host:port of the current socks tor proxies
					$0 --running
	-g | --generate	generates X number of new tor instances 
					$0 --generate=5
	-k | --kill     killall tor 
	-s | --start    starts all instances
helpcontent
exit 1
}

argParse() {
	for i in "$@"; do
	case $i in
		-r|--running)
			run=true
			shift # past argument=value
             ;;
		-g=*|--generate=*)
    		generateNumber="${i#*=}"
    		shift # past argument=value
    		;;
		-s|--start)
    		startvar=true
    		shift # past argument=value
    		;;
 		-k|--kill)
    		kill=true
    		shift # past argument=value
    		;;   
    	-h|--help)
    		help=true
    		shift # past argument with no value
    		;;
    	*)
	       	help=true # unknown option
    		;;
	esac
	done
	if [ "$help" == true ]; then displayHelp; fi
	if [ "$run" == true ]; then getAllRunning; fi
	if [ "$startvar" == true ]; then startAllInstances; fi
	if [ "$kill" == true ]; then killInstances; fi
	if [ -n "$generateNumber" ]; then startGeneration $generateNumber; fi
}

argParse "$@"