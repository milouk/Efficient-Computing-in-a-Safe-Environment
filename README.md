# Efficient_computering_in_safe_environments
Research where we try to achieve the most energy savings and run-time performance by turning off unnecessary protection mechanisms of the modern computer systems


The idea is that in a protected controlled environment (e.g. on a
non-cloud data center or a single tenant machine) one can get a
measurable performance boost by dispensing with measures that protect
against malicious users.

Examples include

* SSL and TLS for web services
* Protections against cache attacks
* Main and secondary storage blanking
* ...

Protection measures that increase reliability but also guard against
attacks, such as process separation and array bounds checking, would be
retained.

## To clone
Because we are using git submodule, be advised to clone this repo using the following command:

	$ git clone --recursive https://github.com/stefanos1316/efficient_computering_in_safe_environments.git

Or, if you cloned normally use the following to obtain the submodules

	$ git submodule init
	$ git submodule update

## Introduction
Nowadays, many mitigation patches are hitting modern micro-processers
to shield them from vulnerabilities.
However, the cost of protection is tigthly associated with run-time
performance tax to the best.
Nevertheless, disabling such mitigations, to achieve immeasurable performance,
is feasible on run-time through various options.

Booting the kernel with pti=off spectre_v2=off l1tf=off nospec_store_bypass_disable no_stf_barrier
To add boot parameters follow this [link](https://askubuntu.com/questions/19486/how-do-i-add-a-kernel-boot-parameter)

To disable weak security such as SSL and TLS follow this [link](https://www.leaderssl.com/news/471-how-to-disable-outdated-versions-of-ssl-tls-in-apache)

For a detailed description of the mitigation flags for CVE-2017-5754, CVE-2017-5715 and CVE-2018-3639 check [here](https://wiki.ubuntu.com/SecurityTeam/KnowledgeBase/SpectreAndMeltdown/MitigationControls)

To disable main and secondary storage blanking, a memset in the linux kernel's source code is available, which we have to disable somehow and
recompile the kernel.

Then execute to apply changed and reboot:

	$ grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

## To consider

Some database systems systems that are using non-blocking models (such as MongoDB) relay heavily of CPUs.
Thus, the more cores in the database server, the more performance is feasible.
Some operations that relay heavily on CPU for storage engine and  concurrency model such as response to incoming requests read/writes,
page compression, data calculation, aggregation framework operations, and map reduce.

## Magic bash pipeline

To extract data from file and add to jupyter
	
	$ cat mitigations_off/energy_mean.txt | awk '{print $1":"$2}' | sed 's/^/"/' | sed 's/:/":/' | sed "s/$/,/" | tr "\n" " " | sed 's/cachebench_/CB /g' | sed 's/mcperf_/MC /g' | sed 's/openssl_//g' | sed 's/create/OS create/g' | sed 's/launch/OS launch/' | sed 's/mem_alloc/OS mem_alloc/'


# Notes
## SSL/TLS
To execute the ssl/tls test case on Fedore follow the steps enlisted below:

	* Copy the server.cert in the /etc/pki/ca-trust/source/anchors for both server and client otherwise the node will hit an error because of the self-signed certificate.
	* Execute command in both client and server terminals: sudo update-ca-trust
	* Install the required modules in the ssl directory by executing the npm i
	* Start the server with http or https env. variable: TEST=http node index.js
	* Start the client with http or https command line arguments: bash client.js http

## CacheBench
To execute test cases with cachebench

	* Enter the llcbench/cachebench directory
	* Execute by following this [instructions](https://github.com/elijah/cachebench/blob/master/cachebench.README)	

## Crypto++
To execute test cases with Crypto++:
ss
	* To install consult the following [instructions](https://github.com/weidai11/cryptopp/blob/master/Install.txt)
	* To perform test on specific algorithm execute the following: $ cryptest.exe tv algrotihmname (check the names from the directory TestVectors)

## Memcached
To install execute the following:
	
	* Install libevent libevent-devel
	* Download the latest version of memcached
	* If using a multithreaded 54bit machince execute the following: $./configure --enable-threads --enable-64bit 
	* To intall: $make & sudo make
        * Start the server using this: $memcached -d -u localhost -m 512 -p 11211 127.0.0.1

## Mcperf
Download and install mcperf since it is used alongside memcached

	* Use the following [instructions](https://github.com/phoronix-test-suite/test-profiles/blob/master/pts/mcperf-1.1.1/test-definition.xml)
	* Phoronix is using the following arguments: --linger=0 --call-rate=0 --num-calls=1000000 --conn-rate=0 --num-conns=1 --sizes=d5120 --method=[get|set|delete|add|replace|append|prepend]

## Apache/Nginx
Install packags found in your supported distro and make sure apache is listening to 9999 and nginx to 80.
For these test cases we are using the ab command to benchmark our server. 
The webpage we are using is the test.html that is given by Phoronix.

## OSbench
	* To recompile download and the [following](https://github.com/mbitsnbites/osbench)
	* After executing all the commands found in the readme file, mv the content of out to /mitigations/osbench. 

## Netperf
Donwload and install using the following:

	$ wget http://www.phoronix-test-suite.com/benchmark-files/netperf-2.7.0.tar.bz2
	$ bash install.sh
	$ netserver -p 22113 (to start the server at port 22113)
	$ netperf -H localhost -p 22113 UDP_STREAM -b 10G (to test that is working)

## SQLite
    * To run the test download both packages from [here](http://sqlite.org/2018/sqlite-autoconf-3220000.tar.gz) and [here](http://www.phoronix-test-suite.com/benchmark-files/pts-sqlite-tests-1.tar.gz)
    * Copy them in Sqlite dir.
    * Run install.sh 

## IO
    * To run the test download package from [here](http://phoronix-test-suite.com/benchmark-files/S-20181019.zip)
    * Copy them in startup-time-1.3.0 dir.
    * Install Dependencies build-utilities, libaio-development or libaio-dev, awk, dd, fio, time, iostat or sysstat, egrep
    * Chmod + x install.sh and Run it
    * Run with ROOT permissions startup-time bla bla
