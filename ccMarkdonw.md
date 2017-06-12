
Cloud Computing
================
Summer Term 2017
----------------
#### Project Assignment No. 1

#### Project Assignment No. 1

### 1.1. Student group
  Name: CC_GROUP_16
  Members:
  1. Peter Schuellermann|   380490
  2. Sebastian Schasse  |   318569
  3. Felix Kybranz      |
  4. Hafiz Umar Nawaz   |   389922
   
* * *

### 2.1. Submission Deliverable

##### 1. A screenshot showing the budget you created in Amazon AWS that notifies you when you used 70% of your yearly budget ​ 

    Define a yearly Budget that will notify you via Email when you use more than 70% of your Amazon Educate credits.

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

##### 4. For every benchmark mentioned above:
  1. A description of your benchmarking methodology, including any written
source code or scripts ​ 

  2. The benchmarking results for the three platforms, including
descriptions and plots ​ 

  3. Answers to the questions ​ 
    
    ###### A. Disk benchmark
      1. Look at the disk measurements. Are they consistent with your expectations. If not, what could be the reason?
      2. Based on the comparison with the measurements on your local hard drive, what kind of storage solutions do you think the two clouds use?

    ###### B. CPU benchmark (​ linpack.sh​ )
        1. Look at ​ linpack.sh and ​ linpack.c and shortly describe how the benchmark works.
        2. Find out what the LINPACK benchmark measures (try Google). Would you expect paravirtualization to affect the LINPACK benchmark? Why? 
        3. Look at your LINPACK measurements. Are they consistent with your expectations? If not, what could be the reason?

    ###### C. Memory benchmark (​ memsweep.sh​ )
        1. Find out how the memsweep benchmark works by looking at the shell script and the C code. Would you expect virtualization to affect the memsweep benchmark? Why?
        2. Look at your memsweep measurements. Are they consistent with your expectations. If not, what could be the reason?



