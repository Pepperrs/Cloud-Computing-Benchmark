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

