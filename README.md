# Ansible playbook for Eucalyptus Cloud deployment

## Deploying Eucalyptus Cloud

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

Example tag use:

```
ansible-playbook --tags      image -i inventory.yml playbook.yml
ansible-playbook --skip-tags image -i inventory.yml playbook.yml
```

which would run the playbook in two parts, the first installing packages
and non-deployment specific configuration, and the second completing the
deployment.

## Maintaining Eucalyptus Cloud

Maintenance playbooks support operations of a previously deployed cloud.

* Add a new node controller
* Remove a node controller
* Passivate a node controller
* Activate a node controller
* Evict node controller instances

### Adding or removing nodes

Adding a node will install all the required software, and register the
node, while removing a node will deregister the node, and remove the
installed software.

Maintenance playbooks use the same inventory as the initial deployment.
For the add/remove node playbooks some inventory changes should be made
as follows.

To add a node controller you would update the inventory with information
for the new host and then run the corresponding playbook:

```
ansible-playbook -i inventory.yml node_add.yml
```

To remove a node controller you would update the inventory so the host
is not present in the `children`/`node` section but **is not** removed
from the main `hosts` section. Once the node removal is completed the
`hosts` section should then be updated.

### Node activation and eviction

A passive a node controller will not be available for launching new
instances. Activate a passive node controller to make it available for
new instances.

Evicting instances from a node controller will migrate running instances
to other node controllers in the same availability zone.

When using maintenance playbooks to activate, passivate or evict a node
an additional `pattern` is used:

```
ansible-playbook -i inventory.yml node_active.yml -e pattern='*.70'
```

the pattern controls the nodes that are acted on, and can be a host
group, such as the default `all` group:

```
ansible-playbook -i inventory.yml node_active.yml -e pattern=all
```

you can define host groups in the inventory if you need to act on
certain groups of nodes.
