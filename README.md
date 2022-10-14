# Ansible playbook for Eucalyptus Cloud deployment

## Preflight checklist

Before you attempt to install Eucalyptus Cloud, make sure of:
- all machines part of the deployment have been cleanly installed (currently with CentOS or RHEL 7) with as default options as possible (firewalld can be left running, SELinux in permissive mode);
- select the machines roles (CLC, CC, NC, ceph) in case you have more than one machine in the deployment. You should be able to ssh without any password from the machine designated as CLC all other machines;
- make sure the network is setup accordingly to your planning. We suggest at least 2 networks the public facing one and the private facing one: the public will be the one used from clients to connects to the cloud, and the private will be the one mostly used internally for Eucalyptus and Ceph communication;
- all the machine should be able to reach access to Internet for packages, ntp etc... The CLC should have a public IP while all the others can have a masquerade access (or public IP);
- a set of public IPs should  reserved for the Eucalyptus Cloud to use with the instances, elastic load balancers, etc ...
- a DNS (sub)domain should be reserved to the cloud, and it should be delegated to the CLC as the authoritative nameserver for it;
- if you use this ansible playbook for ceph deployment, we suggest to have  full disks available for OSD: the disks should be empty, and one OSD will be started per disk.

## Inventory

Create an inventory for your environment:

```
cp inventory_example.yml inventory.yml
vi inventoy.yml
```

and modify accordingly. If you want a single node deployment (Cloud In A Box option) use instead:

```
cp inventory_example_local.yml inventory.yml
vi inventory.yml
```


## Configuration

To operate the cloud __will need__ a subdomain, and a set of public IPs to be used for the instances and services. The options to set them up are:

```
cloud_system_dns_dnsdomain: <DNS subdomain this deployment is responsible for>
```

the DNS subdomain needs to be delegated to the cloud (CLC) machine. For
example to delegate _ats.mydomain.foo_ with dnsmasq add to dnsmasq configuration (for bind or other DNS server, follow their respective documentation):

```
server=/ats.mydomain.foo/<CLC IP address>
```

to enable the delegation. For the public IPs, you will need to define the network they are in and list them:

```
vpcmido_public_ip_cidr: <public IPs for example 10.1.1.0/24>
vpcmido_public_ip_range: <IPs list for example 10.1.1.5-10.1.1.50>
```

## Configuration Options
There are few variables to use to configure the cloud:

```
cloud_firewalld_configure: yes
```
default is no, but without this one you either disable firewalld or you configure it by hand;

```
cloud_use_dnsmasq: no
```
default is yes and it is recommended to keep it. Without a local dnsmasq running on the CLC configured to delegate the subdomain to the CLC, your deployment will depends on external DNS server to operate some functionalities (for example ELBs and more);

```
ceph_osd_data_path:
  - /dev/sdg
  - /dev/sdh
```
if you choose to let this script setup ceph for you, this is the list (1 or more) of hard disks to delegate to each ceph machine. The disks needs to be empty, without tags;

```
cloud_region_name: my_lovely_cloud
```
you can customize here your deployment region's name (from the unimaginative default of cloud-1);

```
cloud_zone_1_name: developers
cloud_zone_2_name: sales
cloud_zone_3_name: production
```
you can customize here the name if each AZ you have configured. Defaults is to add _a_, _b_ etc... to the deployment name;

```
eucalyptus_console_cname: ec2.clouddns_subdomain
```
this is the CNAME to be used with your deployment Route53 to set an entry for the console. The default assumes you installed the eucaconsole on the CLC machine, and thus we add an entry of _ec2.your_dns_cloud_subdomain_. If you prefer to set a full A record instead add also _eucalyptus_console_ipv4: IP_address_;

```
enable_M1_instances: False
enable_M2_instances: False
enable_M3_instances: False
enable_M4_instances: False
enable_M5D_instances: False
enable_T1_instances: False
enable_T3_instances: False
```
turns each one of the above to True to have more instance types available in your deployment.

## Installing the different networks mode

To install with VPCMIDO network mode (recommended):

```
ansible-playbook -i inventory.yml playbook_vpcmido.yml
```

this is the recommended network mode to have access to all VPC options.

To install with EDGE network mode:

```
ansible-playbook -i inventory.yml playbook[_edge].yml
```

## Remove a deployment
To remove a eucalyptus installation and main dependencies:

```
ansible-playbook -i inventory.yml playbook_clean.yml
```

NOTE: if ceph was installed with this ansible playbook, it will not be touched, thus you will have to clear all the disks yourself if you desire to do a full clean install. For example if you have `/dev/sdb` and `/dev/sdc` dedicated to ceph and you want to clear them on each ceph node do:

```
for x in `lvdisplay |awk '/\/dev\/ceph/ { print $3 }'`; do lvremove -f $x; done
for x in `pvdisplay |awk '/ceph/ {print $3}'`; do vgremove $x; done
pvremove /dev/sdb /dev/sdc
```

## Using tags
Tags can be used to control which aspects of the playbook are used:

* `image`               : `packages` and generic configuration
* `packages`            : installs yum repositories and rpms
* `midonet-packages`     : downloads only Midonet packages locally

Example tag use:

```
ansible-playbook --tags      image             -i inventory.yml playbook.yml
ansible-playbook --skip-tags image             -i inventory.yml playbook.yml
ansible-playbook --skip-tags selinux,firewalld -i inventory.yml playbook.yml
```

which would run the playbook in two parts, the first installing packages
and non-deployment specific configuration, and the second completing the
deployment.

## Ceph options

The ceph cluster can be configured with its own cluster and public network
which can and should be separate from the concept of public or cluster
network for Eucalyptus. The main purpose here is to setup a separate
storage network to be used by the deploymnet (the ceph_public_network),
and/or a private ceph network to be used by OSD for synchronization
(ceph_private_network).

Ceph hosts can be explicitely told which IP is where with ceph_public_ipv4
and ceph_private_ipv4.

Without any specification the Eucalyputs public and cluster networks will be
used.
