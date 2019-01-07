# Using DC/OS Ansible with DC/OS Terraform
This Repo is being used as placeholder for testing our DC/OS Ansible Roles. We will be using our DC/OS Universal TF installer to standup and manage the infrastucture parts.

The purpose of these Anisble Roles is to provide very flexible way for users to manage their DC/OS Installs and Upgrades using Ansible. 

## Prereqs
You must have Terraform, Ansible and Mazer installed. 

With Mac you can brew install:

```
brew install terraform
```

Use Pip to install Ansible and Mazer (Note Tested with Ansible 2.6.2 so referencing it here):

```
pip install ansible==2.6.2 mazer 
```


## Usage
1) Install Roles
```
mazer install --content-path $PWD/ansible dcos.dcos_ansible
```

This will install the roles in `./anisble/dcos/dcos_ansible`. See tree below:

```
tree dcos/dcos_ansible/

dcos/dcos_ansible/
├── README.md
├── TESTING.MD
├── ansible.cfg
├── dcos.yml
├── group_vars
│   ├── agents_private
│   │   └── dcos.yml
│   ├── agents_public
│   │   └── dcos.yml
│   ├── all
│   │   └── dcos.yaml.example
│   ├── bootstraps
│   │   └── dcos.yml
│   └── masters
│       └── dcos.yml
├── inventory.examle
├── meta
├── molecule
│   ├── default
│   │   └── idempotence.yml
│   ├── ec2
│   │   ├── create.yml
│   │   ├── destroy.yml
│   │   ├── install_1-12_upgrade_1-12.yml
│   │   └── same_version_config_update_1-12.yml
│   ├── ec2_centos7
│   │   ├── molecule.yml
│   │   └── tests
│   │       └── test_default.py
│   ├── ec2_rhel7
│   │   ├── molecule.yml
│   │   └── tests
│   │       └── test_default.py
│   └── vagrant_centos7
│       ├── create.yml
│       ├── destroy.yml
│       ├── install_1-12_upgrade_1-12.yml
│       ├── molecule.yml
│       ├── same_version_config_update_1-12.yml
│       └── tests
│           └── test_default.py
├── roles
│   ├── DCOS.agent
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   └── tasks
│   │       ├── dcos_install.yml
│   │       ├── dcos_upgrade.yml
│   │       └── main.yml
│   ├── DCOS.bootstrap
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── molecule
│   │   │   └── bootstrap_need_prereqs
│   │   │       ├── create.yml
│   │   │       ├── destroy.yml
│   │   │       ├── molecule.yml
│   │   │       ├── playbook.yml
│   │   │       └── tests
│   │   │           └── test_default.py
│   │   ├── tasks
│   │   │   └── main.yml
│   │   └── templates
│   │       ├── config.yaml.j2
│   │       ├── ec2
│   │       │   ├── fault-domain-detect.sh.j2
│   │       │   ├── ip-detect-public.j2
│   │       │   └── ip-detect.j2
│   │       └── onprem
│   │           ├── fault-domain-detect.sh.j2
│   │           ├── ip-detect-public.j2
│   │           └── ip-detect.j2
│   ├── DCOS.master
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   └── tasks
│   │       ├── dcos_install.yml
│   │       ├── dcos_upgrade.yml
│   │       └── main.yml
│   └── DCOS.requirements
│       ├── defaults
│       │   └── main.yml
│       ├── meta
│       │   └── main.yml
│       ├── molecule
│       │   ├── default
│       │   │   ├── create.yml
│       │   │   ├── destroy.yml
│       │   │   ├── molecule.yml
│       │   │   ├── playbook.yml
│       │   │   └── tests
│       │   │       └── test_default.py
│       │   └── with_ec2
│       │       ├── create.yml
│       │       ├── destroy.yml
│       │       ├── molecule.yml
│       │       ├── playbook.yml
│       │       └── tests
│       │           └── test_default.py
│       ├── tasks
│       │   └── main.yml
│       └── vars
│           ├── CentOS7.yml
│           ├── RedHat7.yml
│           ├── RedHat8.yml
│           └── generic.yml
└── test_requirements.txt

48 directories, 71 files
```

2) Drop a `license.txt` with your EE license key. (Note if you are install OSS, Remove the reference from the main.tf)

3) Modify the `main.tf` to your liking such as Number of Masters, Agents, AMI, Cluster Name, SSH Key, etc... If EE, Copy your license key in place of current value for `license_key_contents`. *Currently when you specify `${file(./license.txt)}` with your contents in the file, the local_file resource places a `\n` at the end causing the yaml syntax to fail.* 

4) Auth, Init, Plan and Apply Terraform.
```
eval $(maws li "Team Blah")
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Terraform will handle creation of the `inventory` and vars files for DC/OS (`group_vars/all/dcos.yml`) in the `ansible/dcos/dcos_ansible` directory.

5) Once the infrastructure completes, you can run the Roles (Hint You will likely need to set `host_key_checking` to `False` in the ansible.cfg):
```
cd ansible/dcos/dcos_ansible
ansible-playbook dcos.yml
```
PRO TIP: You can set `host_key_checking` to `False` in the `ansible.cfg` if you would like to skip being prompted the initial run.  

This will take some time to complete.

## Upgrades
To Do

## License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## Author Information
This role was created by team SRE @ Mesosphere and others in 2018, based on multiple internal tools and non-public Ansible roles that have been developed internally over the years.