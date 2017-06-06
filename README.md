# Cloud-Computing-Benchmark

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
