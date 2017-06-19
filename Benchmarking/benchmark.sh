#!/bin/bash -x

#RUNTIME=300
#printf "Runtime is" $RUNTIME "seconds for linpack and memsweep each!"

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "running Benchmark and saving results to results.txt"

# prepare instance and install deps
# apt-get update
# apt-get install -y build-essential

printf "Date: " > results.txt
date >> results.txt

printf "Benchmark for: " >> results.txt
hostname >> results.txt

lscpu | grep '^CPU(s): ' >> results.txt

printf "\nIP Adress:\n">> results.txt
curl -s ipinfo.io/ip >> results.txt


printf "\nlinpack:\n">> results.txt
sh linpack.sh | grep "result" >> results.txt

printf "\nmemsweep:\n">> results.txt
sh memsweep.sh | grep "seconds" >> results.txt

printf "\nHardware:\n" >> results.txt
lshw -short >> results.txt

printf "\nDiskbenchmark:\n" >> results.txt
./diskbenchmark.sh >> results.txt
#printf "\nDiskbenchmark:\n" >> results.txt
#./diskbenchmark_aws.sh >> results.txt
