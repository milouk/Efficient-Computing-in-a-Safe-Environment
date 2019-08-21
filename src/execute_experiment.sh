#!/bin/bash

# Some functions to make our life easier

# Check via if the give host is running
function checkRemoteHostSSH {
	echo "Checking instance $1@$2"
	if nmap --version | grep "command not found"; then
		echo "Nmap not found in local host."
		echo "Please install nmap before procceding any further."
		echo "Exiting..."
		exit
	fi

	if nmap -p22 $2 -Pn -oG - | grep -q 22/open; then
    	echo "Remote Host's $2 SSH is active"
		echo "Procceding normally..."
		echo " "
	else
    	echo "Remote Host's $2 SSH is not running..."
		echo "Please make sure that is active and try again."
		exit
	fi
}

# Function for help me
function helpMe {
	echo
	echo "-n | --energyMonitorerName [device name]	The name of the host that will act as an energy monitoring instance."
	echo "-a | --energyMonitorerAddress [device IP]	The IP address of the host that acts as an energy monitoring."
	echo "-b | --clientName [devcice name]		The name of the host that will act as a client instance (For TLS/SSL scenarios only)"
	echo "-d | --clientAddress [device IP]		The IP address of the host that acts as a client (For TLS/SSL scenarios only)."
	echo "-h | --help					Prints this message."
	echo
	exit
}

# Command line arguments
DIRECTORY_PATH=""
ENERGY_MONITOR_NAME=""
ENERGY_MONITOR_NAME=""
CLIENT_NAME=""
CLIENT_ADDRESS=""
EXPERIMENT_TYPE=""

OPTIONS=`getopt -o n:a:hb:d: --long help,energyMonitorerName:,energyMonitorerAddress:,clientName:,clientAddress: -n 'execute_experiment.sh' -- "$@"`
eval set -- "$OPTIONS"
while true; do
	case "$1" in
		-n|--energyMonitorerName)
			case $2 in
				*[a-zA-Z0-9]*) ENERGY_MONITOR_NAME=$2 ; shift 2 ;;
				*) >&2 echo "[Error] Host name is required!" ; shift 2 ;;
			esac ;;
		-a|--energyMonitorerAddress)
			case $2 in
				*\.*\.*\.*) ENERGY_MONITOR_ADDRESS=$2 ; shift 2 ;;
				*) >&2 echo "[Error] IP address is required!" ; shift 2 ;;
			esac ;;
		-b|--clientName)
			case $2 in
				*[a-zA-Z0-9]*) CLIENT_NAME=$2 ; shift 2 ;;
				*) >&2 echo "[Error] Host name is required!" ; shift 2 ;;
			esac ;;
		-d|--clientAddress)
			case $2 in
				*\.*\.*\.*) CLIENT_ADDRESS=$2 ; shift 2 ;;
				*) >&2 echo "[Error] IP address is required!" ; shift 2 ;;
			esac ;;
		-h|--help) helpMe ; shift ;;
		--) shift ; break ;;
		*) >&2 echo "Wrong command line argument, please try again." ; exit 1 ;;
	esac
done

# Before creating directories check if the remote host is acticvated and SSH is running
checkRemoteHostSSH ${ENERGY_MONITOR_NAME} ${ENERGY_MONITOR_ADDRESS}
checkRemoteHostSSH ${CLIENT_NAME} ${CLIENT_ADDRESS}

# Define hosts username@ipaddress
ENERGY_COLLECTOR=${ENERGY_MONITOR_NAME}@${ENERGY_MONITOR_ADDRESS}
CLIENT_HOST=${CLIENT_NAME}@${CLIENT_ADDRESS}

# Creating results directories
currentDate=$(date -u | sed -e 's/ /_/g')
resultsDirName="experiment_data_"$currentDate
mkdir -p ../results/${resultsDirName}

# Define directories to store results
DIR_ENERGY_CONSUMPTION="GitHub/wattsuppro/reports/${resultsDirName}"
DIR_PERFORMANCE_CLIENT="/home/sgeorgiou/GitHub/efficient_computering_in_safe_environments/results/${resultsDirName}"
ssh ${ENERGY_COLLECTOR} "mkdir -p ${DIR_ENERGY_CONSUMPTION}"
ssh ${CLIENT_HOST} "mkdir -p ${DIR_PERFORMANCE_CLIENT}"

##########################################################################################################################################################
# Lauching spetre/meltdown tests for netperf
echo "Executing netperf benchmarks"

netperf_params=("TCP_STREAM" "TCP_MAERTS" "UDP_STREAM" "TCP_RR" "UDP_RR" "TCP_SENDFILE")

# Starting netperf server
netserver -p 22113

for parameter in "${netperf_params[@]}"; do

	test_name=$(echo ${parameter} | tr '[:upper:]' '[:lower:]')

	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_netperf_${test_name}.txt' & " &
	sleep 2

	time (netperf -H localhost -p 22113 ${parameter} -l 60) 2>> ../results/${resultsDirName}/performance_netperf_${test_name}.txt

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for stress-ng
echo "Executing stress-ng benchmarks"

stress_ng=("--cpu 0 --cpu-method all" "--vecmath 0" "--matrix 0" "--fork 0" "--msg 0" "--sem 0" "--sock 0" "--switch 0")

for parameter in "${stress_ng[@]}"; do

	test_name=$(echo ${parameter} | awk '{print $1}' | sed 's/--//')

	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_stress_ng_${test_name}.txt' & " &
	sleep 2

	time (stress-ng -t 30 --metrics-brief ${parameter}) 2>> ../results/${resultsDirName}/performance_stress_ng_${test_name}.txt

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for ctx_clock
# echo "Executing ctx_clock benchmarks"

# # Start remote device to collect energy measurements
# ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_ctx_clock.txt' & " &
# sleep 2

# cd ../mitigations/ctx_clock
# time (./ctx_clock) 2>> ../../results/${resultsDirName}/performance_ctx_clock.txt

# # Once the client stopped running kill Server and WattsUp?Pro instances.
# ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
# echo "[Experiment termindated]"
# sleep 10

# cd ../../src
# echo "Copying all data"
# scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for sqlite
echo "Executing sqlite benchmarks"

#Start remote device to collect energy measurements
ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_sqlite.txt' & " &
sleep 2

cd ../mitigations/sqlite
time (bash sqlite-benchmark) 2>> ../../results/${resultsDirName}/performance_sqlite.txt

#Once the client stopped running kill Server and WattsUp?Pro instances.
ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
echo "[Experiment termindated]"
sleep 30

cd ../../src
echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for OSbench
echo "Executing OSbench benchmarks"

osTest=("create_files.exe" "create_processes.exe" "create_threads.exe" "launch_programs.exe" "mem_alloc.exe")

for osBenchExe in "${osTest[@]}"; do

	# Remove extension
	justTheName=$(echo ${osBenchExe} | awk -F"." '{print $1}')
	dirName=${justTheName}"@exe"
	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_${justTheName}.txt' & " &
	sleep 2

	if [ ${osBenchExe} != "launch_programs.exe" ]; then
		time (../mitigations/osbench/${osBenchExe} ../mitigations/osbench/${dirName}) 2>> ../results/${resultsDirName}/performance_${justTheName}.txt
	else
		time (../mitigations/osbench/${osBenchExe}) 2>> ../results/${resultsDirName}/performance_${justTheName}.txt
	fi

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for apache and nginx
echo "Executing apache and nginx benchmarks"

# Safety mechanism
STATUS=""
STATUS=$(curl http://localhost:80/test.html | grep Failed)
if [ "${STATUS}" != "" ]; then
	echo 'Please ensure that your server is running or the test.html exists under /var/www/html'
	exit
fi

serverTest=("apache" "nginx")

for server in "${serverTest[@]}"; do
	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_${server}.txt' & " &
	sleep 2

	if [ "${server}" == "nginx" ]; then
		time (ab -n 1000000 -c 100 http://localhost:80/test.html) 2>> ../results/${resultsDirName}/performance_${server}.txt
	else
		time (ab -n 1000000 -c 100 http://localhost:9999/test.html) 2>> ../results/${resultsDirName}/performance_${server}.txt
	fi

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for cryptopp
echo "Executing memcached mcperf benchmark"

mcperfTests=("get" "set" "delete" "add" "replace" "append" "prepend")

for method in "${mcperfTests[@]}"; do

	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_mcperf_${method}.txt' & " &
	sleep 2

	time (mcperf --linger=0 --call-rate=0 --num-calls=1000000 --conn-rate=0 --num-conns=1 --sizes=d5120 --method=${method}) 2>> ../results/${resultsDirName}/performance_mcperf_${method}.txt

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30

done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for openssl
echo "Executing openssl benchmark"

opensslTests=("aes" "blowfish" "camellia" "cast" "dsa" "ghash" "hmac" "idea" "rc4" "rc5" "rmd160"  "seed" "sha1" "sha256" "sha512" "whirlpool" "ecdsa")

for parameter in "${opensslTests[@]}"; do
	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_openssl_${parameter}.txt' & " &
	sleep 2

	time (openssl speed ${parameter}) 2>> ../results/${resultsDirName}/performance_openssl_${parameter}.txt

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
# Lauching spetre/meltdown tests for cachebench
echo "Executing cacheBech benchmark"
cd ../mitigations/llcbench/cachebench/

cacheBenchArguments=("-r" "-w" "-b" "-s" "-p")
fileName=""
performanceFileName=""
for parameter in "${cacheBenchArguments[@]}"; do

	case $parameter in
		("-r") fileName="energy_cachebench_read.txt";
			performanceFileName="performance_cachebench_read.txt";;
		("-w") fileName="energy_cachebench_write.txt";
			performanceFileName="performance_cachebench_write.txt";;
		("-b") fileName="energy_cachebench_mixed.txt";
			performanceFileName="performance_cachebench_mixed.txt";;
		("-s") fileName="energy_cachebench_memset.txt";
			performanceFileName="performance_cachebench_memset.txt";;
		("-p") fileName="energy_cachebench_memcpy.txt";
			performanceFileName="performance_cachebench_memcpy.txt";;
	esac

	# Start remote device to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/${fileName}' & " &
	sleep 2

	time (./cachebench ${parameter} -x1 -m32 -d1 -e1) 2>> ../../../results/${resultsDirName}/${performanceFileName}

	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"
	sleep 30
done
cd ../../../src/

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
##########################################################################################################################################################
if [ "${CLIENT_HOST}" == "" ]; then
	echo "Please define a client to run the test cases"
	exit
fi

test_cases=("http" "https")
for protocol in "${test_cases[@]}"; do
	echo "Executing SSL/TLS scenario with $protocol"
	cd ../ssl/
	TEST=$protocol node index.js &
	cd ../src/

	# Check is server is up and running
	while true; do
		STATUS=""
		STATUS=$(curl $protocol://195.251.251.27:3000 2>&1 | grep Failed)
		if [ "$STATUS" == "" ]; then
			break
		fi
	done

	# Start remote host to collect energy measurements
	ssh ${ENERGY_COLLECTOR} "sh -c 'sudo ~/GitHub/wattsuppro/watts-up/wattsup ttyUSB0 -s watts >> ${DIR_ENERGY_CONSUMPTION}/energy_$protocol.txt' & " &
	sleep 2

	# Start client host
	ssh ${CLIENT_HOST} "bash -c 'cd /home/sgeorgiou/GitHub/efficient_computering_in_safe_environments/ssl && (time bash client.sh $protocol) 2>> ${DIR_PERFORMANCE_CLIENT}/run_time_$protocol.txt' & " &

	#Check if remote client is still running
	while ssh ${CLIENT_HOST} ps aux | grep -i "client.sh" > /dev/null; do
		sleep 1
	done
						
	# Once the client stopped running kill Server and WattsUp?Pro instances.
	ssh ${ENERGY_COLLECTOR} sudo pkill wattsup
	echo "[Experiment termindated]"

	REMAINING=$(netstat -lntp 2>/dev/null | awk '{print $7}' | grep node | awk -F "/" '{print $1}')
	kill -9 ${REMAINING}
	sleep 30
done

echo "Copying all data"
scp -r ${ENERGY_COLLECTOR}:${DIR_ENERGY_CONSUMPTION}/* ../results/${resultsDirName}/
#scp -r ${CLIENT_HOST}:${DIR_PERFORMANCE_CLIENT}/* ../results/${resultsDirName}/
##########################################################################################################################################################
