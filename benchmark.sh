#RUNTIME=300
#printf "Runtime is" $RUNTIME "seconds for linpack and memsweep each!"

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "running Benchmark ans saving results to results.txt"

#if debian?
#sudo yam update
#sudo yam upgrade
#sudo yam install gcc

printf "Benchmark for: " > results.txt
hostname >> results.txt

lscpu | grep '^CPU(s): ' >> results.txt

printf "\nIP Adress:\n">> results.txt
curl -s ipinfo.io/ip >> results.txt


printf "\nlinpack:\n">> results.txt
sh linpack.sh | grep "result" >> results.txt

printf "\nmemsweep:\n">> results.txt
sh memsweep.sh | grep "seconds" >> results.txt

printf "\nHardware:\n" >> results.txt
sudo lshw -short >> results.txt


rm linpack
rm memsweep
