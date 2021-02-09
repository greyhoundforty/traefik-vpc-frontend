# Ansible
## Overview
**What is Ansible?**
[Ansible][ansible] is an open-source automation tool, or platform, used for IT tasks such as configuration management, application deployment, and intra-service orchestration. While it can be used for provisioning infrastructure as well, this guide will focus more on it as a configuration and application deployment tool.

**What about x, y, or z?**
There is no shortage of good configurtion management tools. [Puppet][puppet], [Chef][chef], [Saltstack][saltstack] are three of the larger names you will see when researching about IT automation. I prefer Ansible, currently, because it does not require per-server agents, has a large set of community provided modules/roles, and commands can be written in almost any programming language. Ansible is written in Python which is built into most Linux and Unix deployments, making setup easier and faster.

**I thought you loved Terraform**
It is no secret that I like Terraform very much and in fact am using it in conjunction with this repository to spin up the infrastructure that the Ansible playbooks will run against. While Terraform can be used for machine management, I think its bread and butter is infrastructure provisioning.

## Main Concepts

### Inventory
Ansible works against multiple managed nodes or “hosts” in your infrastructure at the same time, using a list or group of lists known as inventory. Once your inventory is defined, you use patterns to select the hosts or groups you want Ansible to run against. By default Ansible will attempt to use the file `/etc/ansible/hosts`, but you can specify a different inventory file at the command line using the `-i <path>` option.

Ansible also has the concept of [dynamic inventory][dynamic_inventory] which can utilize scripts or remote Terraform states to build an inventory as your environment expands and changes. 

### Facts 
Ansible facts are data related to your remote systems, including operating systems, IP addresses, attached filesystems, and more.

#### Gathering Facts

```shell
λ ansible <host> -m setup -i </path/to/inventory>
```

#### Output Facts to file 
If you want to output all the facts related to a system in to a file so you can dig through it later or maybe use it as part of your automation, you can add the `--tree` flag:

```shell
λ ansible <host> -m setup --tree </path/to/store/facts> -i </path/to/inventory>
```

Using [jq][jq] we can query against our saved facts file to see what facts will be available to our Playbooks.

```
λ jq -r '.ansible_facts.ansible_default_ipv4.address' < ~/Desktop/traefik-facts/traefik
10.240.64.6
```

#### Gathering a subset of facts/filtering facts
If you want to focus on just one aspect of the remote machine you can use the `gather_subset` option. In this example we are just wanting to gather facts about the networking of the remote machine. **Note:** Some basic facts are always returned, but using the `gather_subset` will greatly reduce the amount of information you have to dig through. 

```shell
λ ansible <host> -m setup -a 'gather_subset=!all,!any,network' -i </path/to/inventory>
```

You can also filter the facts that are returned to you using the `filter=` option. The following example returns just the informtion related to the memory of the system:

```shell
λ ansible traefik -m setup -a 'filter=ansible_*_mb' -i inventory
traefik | SUCCESS => {
    "ansible_facts": {
        "ansible_memfree_mb": 1764,
        "ansible_memory_mb": {
            "nocache": {
                "free": 3638,
                "used": 310
            },
            "real": {
                "free": 1764,
                "total": 3948,
                "used": 2184
            },
            "swap": {
                "cached": 0,
                "free": 0,
                "total": 0,
                "used": 0
            }
        },
        "ansible_memtotal_mb": 3948,
        "ansible_swapfree_mb": 0,
        "ansible_swaptotal_mb": 0,
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false
}
```

### Templates
Ansible uses Jinja2 templating to enable dynamic expressions and access to variables/facts. All templating happens on the Ansible controller before the task is sent and executed on the remote machine. This approach minimizes the package requirements on the remote machine and also limits the amount of data Ansible needs to pass to the remote machines.

### Playbooks
Ansible Playbooks offer a repeatable, re-usable design for managing IT infrastructure. Playbooks can:
 - declare application or service configurations
 - orchestrate deployments in a single or multiple machines, in a defined order
 - launch tasks synchronously or asynchronously

A playbook is composed of one or more ‘plays’ in an ordered list. A playbook runs in order from top to bottom. At minimum a playbook needs to define machines to run against and at least one task to execute.

## And now for the live part

[ansible]: https://www.ansible.com/resources/get-started
[chef]: https://www.chef.io/
[puppet]: https://puppet.com/
[saltstack]: https://www.saltstack.com/
[dynamic_inventory]: https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html#intro-dynamic-inventory
[jq]: https://stedolan.github.io/jq/