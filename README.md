# Cloud-Computing-Benchmark

### Benchmaking cheatseet

Connect to the instance via ssh and use `ForwardAgent=yes`, so that
you can use your ssh key to push to github.

``` shell
ssh -o ForwardAgent=yes ubuntu@$host
```

Prepare the instance with some packages and our code:

``` shell
# debian/ubuntu:
sudo apt-get update
sudo apt-get install -y build-essential fio

# or aws' linux image:
sudo yam update
sudo yam upgrade
sudo yam install gcc fio

git config --global user.name "John Doe"
git config --global user.email johndoe@example.com

git clone git@github.com:Pepperrs/Cloud-Computing-Benchmark.git
cd Cloud-Computing-Benchmark
git fetch
```

Then do the following for benchmarking (remotely on openstack or aws,
or benchmark your local system):

``` shell
# run the benchmarking scripts at least 3 times
sudo ./benchmark.sh
mv results.txt results16.txt
sudo ./disk_benchmark.sh >> openstack-disk-results16.txt
```

Collect the results and push them to the repository:
``` shell
git add .
git commit -a -m'adding some results, dude!'
git push origin master
```

## Openstack
### CLI Installation

You need to have python installed in version 2.7 or >= 3.4. Then
install the openstack cli by basically one command:

``` shell
pip install python-openstackclient
```

You'll also need to replace the password placeholder in the
`cc-openstack` wrapper script by the correct password, Anton provided
us.

For further information refer to the official installation guide
https://docs.openstack.org/user-guide/common/cli-install-openstack-command-line-clients.html

### Usage

Starting a server instance on openstack is automated by `openstack.sh`
script. Mind to have a tu berlin ip address by using their wifi or vpn.

Stop instance and delete resources again with the following command:

``` shell
cc-openstack server delete grp17 && \
  cc-openstack security group delete grp17 && \
  cc-openstack floating ip delete $grp17_ip && \
  cc-openstack keypair delete $USER
```
