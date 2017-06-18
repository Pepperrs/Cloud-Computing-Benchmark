Cloud Computing
================
Summer Term 2017
----------------

### Student group
  Name: CC_GROUP_16

  Members:
  1. Peter Schuellermann |   380490
  2. Sebastian Schasse   |   318569
  3. Felix Kybranz       |   380341
  4. Hafiz Umar Nawaz    |   389922

* * *

###Submission Deliverable

##### 1. A screenshot showing the budget you created in Amazon AWS that notifies you when you used 70% of your yearly budget ​

    Define a yearly Budget that will notify you via Email when you use more than 70% of your Amazon Educate credits.

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/aws_billing1.png)

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/aws_billing2.png)

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/aws_billing3.png)

    We doesn't even used our aws credits because of the given free i/o contingent.

##### 2. A ​commented command-line listing used to prepare the Amazon EC2 instance

```sh
    #!bin/bash

    # importing and generating key pair
    if [[ ! -f $HOME/KEY ]]; then
      mkdir ~/KEY
    fi

    if [[ ! -f $HOME/KEY/CC17key.pem ]]; then
      openssl genrsa -out $HOME/KEY/CC17key.pem 2048
    fi

    openssl rsa -in $HOME/KEY/CC17key.pem -pubout > $HOME/KEY/CC17key.pub
    sed -e '2,$!d' -e '$d' $HOME/KEY/CC17key.pub >> $HOME/KEY/CC17key_without_headntail.pub
    aws ec2 import-key-pair --public-key-material file://~/KEY/CC17key_without_headntail.pub --key-name CC17key

    # creating a security group
    aws ec2 create-security-group --group-name CC17GRP16 --description "My security group"

    # enable ssh for security group
    aws ec2 authorize-security-group-ingress --group-name CC17GRP16 --protocol tcp --port 22 --cidr 0.0.0.0/0 --region eu-central-1

    # creating an instance -check
    aws ec2 run-instances --image-id ami-f603d399 --count 1 --instance-type m3.medium --key-name CC17key --security-groups CC17GRP16 --region eu-central-1

    # getting the DNS Addr & InstanceID & InstanceIP
    PubDNS=$(aws ec2 describe-instances --filters "Name=instance-type,Values=m3.medium" | grep PublicDnsName | awk -F'"' '{ print $4}' | sort | uniq | sed 1d)
    InstanceID=$(aws ec2 describe-instances --filters "Name=instance-type,Values=m3.medium" | grep InstanceId | awk -F'"' '{ print $4}' | sort | uniq)
    InstanceIP=$(aws ec2 describe-instances --filters "Name=instance-type,Values=m3.medium" | grep PublicIp | awk -F'"' '{ print $4}' | sort | uniq)

    printf "\ngrab a coffee and wait for the machine $PubDNS to boot\n"
    while [[ $(bash -c "(echo > /dev/tcp/$PubDNS/22) 2>&1") ]]; do
      echo 'still waiting...'
      sleep 10
    done

    # transfer files for benchmarking // <rsync buggy;dont know why i get permission denied>
    #git clone https://github.com/Pepperrs/Cloud-Computing-Benchmark.git ~/CCBenchmark
    #rsync -ae ssh -i $HOME/KEY/CC17key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null --progress ~/CCBenchmark/ ec2-user@$InstanceIP:~/ -v

    # connecting
    ssh -i $HOME/KEY/CC17key.pem ec2-user@$PubDNS

    # delete everything
    #aws ec2 terminate-instances --instance-ids $InstanceID --region eu-central-1
    #aws ec2 delete-security-group --group-name CC17GRP16 --region eu-central-1
    #aws ec2 delete-key-pair --key-name CC17key
    #rm -rf ~/KEY
    #rm -rf ~/CCBenchmark
    #unset PubDNS InstanceIP InstanceID
    #echo"deleted everything related to your aws instance"
```

##### 3. A commented command-line listing used to prepare and launch the virtual machine in OpenStack

Create a ssh key unless you have one.
```
ssh-keygen -t rsa -b 4096 -C $USER
```
Upload your ssh key to openstack.
```
cc-openstack keypair create $USER --public-key ~/.ssh/id_rsa.pub
```
Create a security group and allow icmp ingress as well as ingress on port 22 for a ssh connection.
```
cc-openstack security group create grp17
cc-openstack security group rule create grp17 --description ssh-ingress \
  --ingress --protocol tcp --dst-port 22:22
cc-openstack security group rule create grp17 --description icmp-ingress \
  --ingress --protocol icmp
```
Actually create the openstack virtual machine.
```
cc-openstack server create grp17_openstackvm --image ubuntu-16.04 \
  --flavor 'Cloud Computing' --network cc17-net --security-group grp17 \
  --key-name $USER
```
We need a floating ip, which is reachable from tu berlin network, and
attach it to the running instance.
```
cc-openstack floating ip create tu-internal
grp17_ip=$(cc-openstack floating ip list -c 'Floating IP Address' -f value)
cc-openstack server add floating ip grp17 $grp17_ip
```
Now we need to wait some until the instance is ready. Afterwards we can connect to it via ssh.
```
ssh -i ~/.ssh/id_rsa ubuntu@$grp17_ip
```

#### 4. Benchmarks

##### A. Disk benchmark

###### 1. A description of your benchmarking methodology, including any written source code or scripts.

For benchmarking the disks, we're using `dd` for sequential reads and writes and also measure with it whether there is caching or no caching. To measure random access we're using `fio`. We were measuring on openstack and aws in the morning, early afternoon and midnight. On our local machine, we just made 3 successive measurements, because it's not shared with anybody else and should give the same results for all daytimes. In the following is our script, we used for measures.

```bash
#!/bin/bash -e

tempfile=$1

if [[ $tempfile == '' ]]; then
  tempfile=/tmp/benchmarking_testfile
fi

printf 'sequential write: '
# write 1GB data and print throughput
dd if=/dev/zero of=$tempfile bs=1M count=1024 conv=fdatasync,notrunc \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'

printf 'sequential read (w/o cache): '
# drop buffer caches
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
dd if=$tempfile of=/dev/null bs=1M count=1024 \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'
printf 'sequential read (w cache): '
dd if=$tempfile of=/dev/null bs=1M count=1024 \
  2>&1 | tail -n 1 | awk '{split($0,a,", "); print a[4]}'

rm $tempfile

printf 'random write: '
fio --rw=randwrite --name=test --size=1024M --direct=1 --bs=1024k --output-format=terse \
  | awk '{split($0,a,";"); print a[49] " IOPS"}'

printf 'random read: '
fio --rw=randread --name=test --size=1024M --direct=1 --bs=1024k --output-format=terse \
  | awk '{split($0,a,";"); print a[8] " IOPS"}'
```

###### 2. Look at the disk measurements. Are they consistent with your expectations. If not, what could be the reason?

2.1 Sequential reads/writes

To compare the sequential read/write performance of the different machine types we representatively plotted the results for sequential writes. The difference of read vs. write on each machine doesn't look too interesting. There are two interesting findings in the results. The first finding is, that the performance of our local machine is much higher than the performance of the cloud providers. The second thing is, that we expected to see different results, varying in performance, for both cloud providers. That's true for openstack. The measurements in the morning were more than twice as fast compared to afternoon and midnight. aws' performance is surprisingly stable.

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/sequential_writes_benchmarks.png)

2.2 Random access

For random access the results look really similar to compared to the sequential access. There is just to mention, that the differences between the types and the daytimes is even bigger.

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/iops_writes_benchmarks.png)

2.3 Cache

We also measured whether there is caching or not. The plot tells us, that the local machine and aws provide a cache, whereas openstack doesn't.

![](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/cache_reads_benchmarks.png)

###### 3. Based on the comparison with the measurements on your local hard drive, what kind of storage solutions do you think the two clouds use?

On our local machine, we measured a solid state disk. Due to the big performance differences, aws as well as openstack have regular hard disks.

##### B. CPU benchmark (​ linpack.sh​ )

######  1. A description of your benchmarking methodology, including any written source code or scripts
  We run the linpack scripts on all machines multiple times and analysed the results. Also we run the .C script to see detailed information about DGEFA and DGESL with different Array sizes. We did experiments by changing the array size for matrix in th given code so that it creates enough repetations that  we consume far more than 10 CPU cyles. We checked the diffrences of KFLOPS with incresing number of repetitions of matrix calculation with respect to implemented linear system of equations.  
######  2. The benchmarking results for the three platforms, including descriptions and plots ​
  The bar chart shows the number of kilo floating-point operations per second on Openstack, AWS and local machines. The array size for this experiment was [1000].

![Linpack Benchmark Result](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/linpackresult.png "Linpack")

![Linpack Benchmark Chart](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/linpackchart.png "Linpack")

######  3. Answers to the questions ​
  1. Look at ​ linpack.sh and ​ linpack.c and shortly describe how the benchmark works.
  Linkpack solves a dense system of linear equations and measures the floating point computing power. 
  The script generates matrices then do dot product on them then decpmpose. So the target of code is to create enough linear manipulations for CPU that we keep it busy for max time within our program execution. 

  ```
    On local machine. 
    Memory required:  7824K.
    LINPACK benchmark, Double precision.
    Machine precision:  15 digits.
    Array size 1000 X 1000.
    Average rolled and unrolled performance:
        Reps Time(s) DGEFA   DGESL  OVERHEAD    KFLOPS
    ----------------------------------------------------
           4   0.95  97.40%   0.63%   1.97%  723277.901
           8   1.91  97.38%   0.64%   1.99%  716577.807
          16   3.77  97.37%   0.64%   1.99%  725907.109
          32   7.66  97.37%   0.64%   1.98%  714802.029
          64  15.60  97.37%   0.65%   1.98%  701711.571
  ```
  
  2. Find out what the LINPACK benchmark measures (try Google). Would you expect paravirtualization to affect the LINPACK benchmark? Why? 
  According to lecture, because virtualization is a good approach for compute intensive applications so we expect that AWS and Openstack will give less FLOPS than our local non-virtualized machine. Also we expect that AWS will perform better that Openstack due to better specifiactions and more cores. 
  
  3. Look at your LINPACK measurements. Are they consistent with your expectations? If not, what could be the reason?
  The difference between AWS and Openstack is less than our expectaions this urges us to think that openstack is using hardware virtualization and so do covers previliged instructions checks overhead. 

##### C. Memory benchmark (​ memsweep.sh​ )

######  1. A description of your benchmarking methodology, including any written source code or scripts ​
  `
  We execueted the given memsweep script and measured memory benchmark at diffrent times of day and also took multiple readings for correctness. Though on local we didn't run it multiple time beleiving that it's resoureces are not shared with anyother users.
  `
######  2. The benchmarking results for the three platforms, including descriptions and plots ​

  The bar chart shows the average access time in seconds for memory sweeping on Openstack, AWS and local machines. The array size (ARR_SIZE) for this experiment was [8096 * 4096].

  Results are somewhat different than our expectation.

  ![Memory Sweep Benchmark](https://github.com/Pepperrs/Cloud-Computing-Benchmark/blob/master/memsweep.png "MemSweep")
######  3. Answers to the questions ​
  1. Find out how the memsweep benchmark works by looking at the shell script and the C code. Would you expect virtualization to affect the memsweep benchmark? Why?

  The given memsweep script measures memory access time at diffrent locations. It accesses the memory such that it hits the heap memory and then release the space. 
  We genrally expect degraded performance on vitualized systems maybe because of two reasons. First, the memsweep (a sort of data intensive algorithem) script will result frequent context switches that leads to complete TLB flush. Second, XEN hypervisor validate write requests to ensure isolation. Though, we expect that Openstack will show a slower performance due to low specifications (488MiB Memory, Intel Core 2 Duo) than our AWS(3750 MiB SSD, Intel Xeon CPU E5-2670 v2 @ 2.50GHz). 

  2. Look at your memsweep measurements. Are they consistent with your expectations. If not, what could be the reason?

  Yes, but we were not expecting this huge difference between Openstack and AWS where openstack is almost 8 times slower. This suggests thet physical memory on AWS is somehow very fast. On the other hand our local non virtualized machine is even faster due to better hardware specifications.


#### References:

  1. Linpack: http://www.netlib.org/utk/papers/old.latbe/node10.html
  2. Linpack paper: http://www.cs.yale.edu/homes/yu-minlan/teach/csci599-fall12/papers/xen.pdf
  3. Virtualization: Cloud Computing Slides or Lecture 

* * *

##### Everything Else:

###### Some Detailed Results: 
#### AWS
    Date: Sat Jun 17 10:27:30 UTC 2017
    Benchmark for: ip-172-31-25-111
    CPU(s):                1

    IP Adress:
    52.57.110.245

    linpack:
    Benchmark result: 977292.046 KFLOPS

    memsweep:
    Memsweep time in seconds: 8.530

    Hardware:
    H/W path  Device  Class      Description
    ========================================
                      system     Computer
    /0                bus        Motherboard
    /0/0              memory     3750MiB System memory
    /0/1              processor  Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz
    /1        eth0    network    Ethernet interface

    Diskbenchmark:
    sequential write: 40.8 MB/s
    sequential read (w/o cache): 28.4 MB/s
    sequential read (w cache): 3.2 GB/s
    random write: 39 IOPS
    random read: 37 IOPS

#### OpenStack
    Date: Mon Jun 12 08:12:47 UTC 2017
    Benchmark for: grp17
    CPU(s):                1

    IP Adress:
    130.149.248.93

    linpack:
    Benchmark result: 1790709.393 KFLOPS

    memsweep:
    Memsweep time in seconds: 24.425

    Hardware:
    H/W path        Device  Class      Description
    ==============================================
                            system     Computer
    /0                      bus        Motherboard
    /0/0                    memory     488MiB System memory
    /0/1                    processor  Intel Core 2 Duo P9xxx (Penryn Class Core 2)
    /0/100                  bridge     440FX - 82441FX PMC [Natoma]
    /0/100/1                bridge     82371SB PIIX3 ISA [Natoma/Triton II]
    /0/100/1.1              storage    82371SB PIIX3 IDE [Natoma/Triton II]
    /0/100/1.2              bus        82371SB PIIX3 USB [Natoma/Triton II]
    /0/100/1.2/1    usb1    bus        UHCI Host Controller
    /0/100/1.2/1/1          input      QEMU USB Tablet
    /0/100/1.3              bridge     82371AB/EB/MB PIIX4 ACPI
    /0/100/2                display    GD 5446
    /0/100/3        ens3    network    Virtio network device
    /0/100/4                storage    Virtio block device
    /0/100/5                generic    Virtio memory balloon

    sequential write: 113 MB/s
    sequential read (w/o cache): 130 MB/s
    sequential read (w cache): 130 MB/s
    random write: 126 IOPS
    random read: 134 IOPS

#### Local 
    Date: Sa 17. Jun 13:36:24 CEST 2017
    Benchmark for: schasse-ThinkPad
    CPU(s):                4

    IP Adress:
    95.91.246.110

    linpack:
    Benchmark result: 2656709.289 KFLOPS

    memsweep:
    Memsweep time in seconds: 3.764

    Hardware:
    H/W path       Device           Class          Description
    ==========================================================
                                    system         20F90060GE (LENOVO_MT_20F9_BU_Think_FM_ThinkPad T460s)
    /0                              bus            20F90060GE
    /0/3                            memory         64KiB L1 cache
    /0/4                            memory         64KiB L1 cache
    /0/5                            memory         512KiB L2 cache
    /0/6                            memory         3MiB L3 cache
    /0/7                            processor      Intel(R) Core(TM) i5-6200U CPU @ 2.30GHz
    /0/8                            memory         20GiB System Memory
    /0/8/0                          memory         4GiB SODIMM DDR4 Synchronous 2133 MHz (0,5 ns)
    /0/8/1                          memory         [empty]
    /0/8/2                          memory         16GiB SODIMM DDR4 Synchronous 2133 MHz (0,5 ns)
    /0/8/3                          memory         [empty]
    /0/e                            memory         128KiB BIOS
    /0/100                          bridge         Skylake Host Bridge/DRAM Registers
    /0/100/2                        display        HD Graphics 520
    /0/100/8                        generic        Skylake Gaussian Mixture Model
    /0/100/14                       bus            Sunrise Point-LP USB 3.0 xHCI Controller
    /0/100/14/0    usb1             bus            xHCI Host Controller
    /0/100/14/0/5                   generic        EMV Smartcard Reader
    /0/100/14/0/7                   communication  Bluetooth wireless interface
    /0/100/14/0/8                   multimedia     Integrated Camera
    /0/100/14/0/9                   generic        Generic USB device
    /0/100/14/1    usb2             bus            xHCI Host Controller
    /0/100/14.2                     generic        Sunrise Point-LP Thermal subsystem
    /0/100/16                       communication  Sunrise Point-LP CSME HECI #1
    /0/100/17                       storage        Sunrise Point-LP SATA Controller [AHCI mode]
    /0/100/1c                       bridge         Intel Corporation
    /0/100/1c/0                     generic        RTS522A PCI Express Card Reader
    /0/100/1c.2                     bridge         Intel Corporation
    /0/100/1c.2/0  wlp4s0           network        Wireless 8260
    /0/100/1f                       bridge         Sunrise Point-LP LPC Controller
    /0/100/1f.2                     memory         Memory controller
    /0/100/1f.3                     multimedia     Sunrise Point-LP HD Audio
    /0/100/1f.4                     bus            Sunrise Point-LP SMBus
    /0/100/1f.6    enp0s31f6        network        Ethernet Connection I219-V
    /0/0           scsi1            storage        
    /0/0/0.0.0     /dev/sda         disk           256GB SAMSUNG MZNTY256
    /0/0/0.0.0/1   /dev/sda1        volume         511MiB Windows FAT volume
    /0/0/0.0.0/2   /dev/sda2        volume         488MiB EXT4 volume
    /0/0/0.0.0/3   /dev/sda3        volume         237GiB EFI partition
    /1                              power          00HW022
    /2                              power          01AV405
    /3             br-c0effff5c382  network        Ethernet interface
    /4             docker0          network        Ethernet interface
    /5             br-86096929758f  network        Ethernet interface
    /6             br-a4368559fa14  network        Ethernet interface
    /7             br-2f497b685b6c  network        Ethernet interface

    Diskbenchmark:
    sequential write: 404 MB/s
    sequential read (w/o cache): 533 MB/s
    sequential read (w cache): 5,9 GB/s
    random write: 202 IOPS
    random read: 227 IOPS





