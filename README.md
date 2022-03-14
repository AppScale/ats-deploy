# Ansible playbook for Eucalyptus Cloud deployment

Create an inventory for your environment:

```
cp inventory_example.yml inventory.yml
vi inventoy.yml
```

to install with EDGE network mode:

```
ansible-playbook -i inventory.yml playbook[_edge].yml
```

to install with VPCMIDO network mode:

```
ansible-playbook -i inventory.yml playbook_vpcmido.yml
```

to remove a eucalyptus installation and main dependencies:

```
ansible-playbook -i inventory.yml playbook_clean.yml
```

Tags can be used to control which aspects of the playbook are used:

* `image` : `packages` and generic configuration
* `packages` : installs yum repositories and rpms
* `eucalyptus_get_midonet: downloads only Midonet packages locally

Example tag use:

```
ansible-playbook --tags      image -i inventory.yml playbook.yml
ansible-playbook --skip-tags image -i inventory.yml playbook.yml
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
