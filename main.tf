# Find Public IP
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

# Begin Variables 
variable "aws_ami" {
  description = "AMI to use"
  default     = "ami-0394fe9914b475c53"
}

variable "cluster_name" {
  description = "Name of your DC/OS Cluster"
  default     = "dcos-broadridge"
}

variable "bootstrap_instance_type" {
  description = "[BOOTSTRAP] Instance type"
  default     = "c5.large"
}

variable "num_masters" {
  description = "Number of Masters"
  default     = "3"
}

variable "masters_instance_type" {
  description = "[MASTERS] Instance type"
  default     = "m4.xlarge"
}

variable "num_private_agents" {
  description = "Number of Private Agents"
  default     = "10"
}

variable "private_agents_instance_type" {
  description = "[PRIVATE AGENTS] Instance type"
  default     = "c5.2xlarge"
}

variable "num_public_agents" {
  description = "Number of Public Agents"
  default     = "3"
}

variable "public_agents_instance_type" {
  description = "[PUBLIC AGENTS] Instance type"
  default     = "c5.2xlarge"
}

variable "ssh_public_key_file" {
  description = "SSH Key Location"
  default     = "~/.ssh/id_broadridge.pub"
}


# Begin Modules
module "dcos-infrastructure" {
  source              = "dcos-terraform/infrastructure/aws"
  admin_ips           = ["${data.http.whatismyip.body}/32"]
  aws_ami             = "${var.aws_ami}"
  cluster_name        = "${var.cluster_name}"
  num_masters         = "${var.num_masters}"
  num_private_agents  = "${var.num_private_agents}"
  num_public_agents   = "${var.num_public_agents}"
  ssh_public_key_file = "${var.ssh_public_key_file}"

  bootstrap_instance_type = "${var.bootstrap_instance_type}"
  masters_instance_type   = "${var.masters_instance_type}"
  private_agents_instance_type = "${var.private_agents_instance_type}"
  public_agents_instance_type  = "${var.public_agents_instance_type}" 

  tags = {
    owner      = "dmennell"
    expiration = "never"
  }
}

# Begin Outputs
output "bootstraps" {
  description = "bootsrap IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.bootstrap.public_ip)))}"
}

output "bootstrap_private_ip" {
  description = "bootsrap IPs"
  value       = "${module.dcos-infrastructure.bootstrap.private_ip}"
}

output "masters" {
  description = "masters IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.masters.public_ips)))}"
}

output "masters_private_ips" {
  description = "List of private IPs for Masters (for DCOS config)"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.masters.private_ips)))}"
}

output "private_agents" {
  description = "Private Agents IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.private_agents.public_ips)))}"
}

output "public_agents" {
  description = "Public Agents IPs"
  value       = "${join("\n", flatten(list(module.dcos-infrastructure.public_agents.public_ips)))}"
}

output "cluster-address" {
  value = "${module.dcos-infrastructure.elb.masters_dns_name}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos-infrastructure.elb.public_agents_dns_name}"
}

# Locals
locals {
  bootstrap_ansible_ips         = "${join("\n", flatten(list(module.dcos-infrastructure.bootstrap.public_ip)))}"
  bootstrap_ansible_private_ips = "${module.dcos-infrastructure.bootstrap.private_ip}"
  masters_ansible_ips           = "${join("\n", flatten(list(module.dcos-infrastructure.masters.public_ips)))}"
  masters_ansible_private_ips   = "${join("\n      - ", flatten(list(module.dcos-infrastructure.masters.private_ips)))}"
  private_agents_ansible_ips    = "${join("\n", flatten(list(module.dcos-infrastructure.private_agents.public_ips)))}"
  public_agents_ansible_ips     = "${join("\n", flatten(list(module.dcos-infrastructure.public_agents.public_ips)))}"
}

# Build the vars file
resource "local_file" "vars_file" {
  filename = "./ansible/dcos/dcos_ansible/group_vars/all/dcos.yml"

  content = <<EOF
---
dcos:
  download: "http://downloads.mesosphere.com/dcos-enterprise/stable/1.12.1/dcos_generate_config.ee.sh"
  version: "1.12.1"
  version_to_upgrade_from: "1.12.1"
  enterprise_dcos: true
  selinux_mode: enforcing

  config:
    cluster_name: "${var.cluster_name}"
    security: permissive
    bootstrap_url: http://${local.bootstrap_ansible_private_ips}:8080
    exhibitor_storage_backend: static
    master_discovery: static
    master_list:
      - ${local.masters_ansible_private_ips}
    license_key_contents: "${trimspace(file("./license.txt"))}"
EOF
}


resource "local_file" "ansible_inventory" {
  filename = "./ansible/dcos/dcos_ansible/inventory"

  content = <<EOF
[bootstraps]
${local.bootstrap_ansible_ips}

[masters]
${local.masters_ansible_ips}

[agents_private]
${local.private_agents_ansible_ips}

[agents_public]
${local.public_agents_ansible_ips}

[bootstraps:vars]
node_type=bootstrap

[masters:vars]
node_type=master
dcos_legacy_node_type_name=master

[agents_private:vars]
node_type=agent
dcos_legacy_node_type_name=slave

[agents_public:vars]
node_type=agent_public
dcos_legacy_node_type_name=slave_public

[agents:children]
agents_private
agents_public

[dcos:children]
bootstraps
masters
agents
agents_public
EOF
}