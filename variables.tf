variable "app_name" {
  default = "my-app"
  description = "Aplication Name"
}

variable "region" {
  default = "eu-west-2"
}

variable "profile" {
  default = "default"
  description = "AWS profile for provider"
}

variable "cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region"
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "vpc_tags" {
  description = "The set of VPC tags."
  type = "map"
  default = {
    "Environment" = "dev",
    "Component" = "vpc",
    "Type" = "application"
  }
}

variable "ec2_tags" {
  description = "The set of VPC tags."
  type = "map"
  default = {
    "Environment" = "dev",
    "Component" = "ec2",
    "Type" = "application"
  }
}

# variable "XXX_tags" {
#   description = "The set of XXX tags."
#   type = "map"
#   default = {
#     "app" = "reaction",
#     "TerminationDate" = "03.23.2018",
#     "Environment" = "dev",
#     "Department" = "dev",
#     "Subsystem" = "subsystem_name",
#     "Component" = "XXX",
#     "Type" = "application",
#     "Team" = "team_name"
#   }
# }
//General Cluster Settings
variable "cluster_name" {
  default = "mycluster"
  description = "Name of Kubernetes Cluster"
}

variable "ami" {
  description = "AMI image od"
  default = "none"
}

variable "ssh_key_name" {
  default = "id_rsa.pub"
  description = "Id SSH public key"
}

/*
* AWS EC2 Settings
* The number should be divisable by the number of used
* AWS Availability Zones without an remainder.
*/
variable "kube_master_num" {
  default = 1
  description = "Number of Kubernetes Master Nodes"
}

variable "kube_master_size" {
  default = "t3.small"
  description = "Instance size of Kube Master Nodes"
}

variable "master_public_ip_address" {
  default = true
  description = "Associate public IP address for master instance"
}

variable "master_volume_size" {
  description = "Master Instance volume size"
  default = 30
}

variable "etcd_member_name" {
  description = "etcd member name"
  default = "etcd1"
}

variable "etcd_num" {
  default = 0
  description = "Number of etcd Nodes"
}

variable "etcd_size" {
  default = "t3.nano"
  description = "Instance size of etcd Nodes"
}

variable "kube_worker_num" {
  default = 2
  description = "Number of Kubernetes Worker Nodes"
}

variable "kube_worker_size" {
  default = "t3.medium"
  description = "Instance size of Kubernetes Worker Nodes"
}

variable "worker_public_ip_address" {
  default = false
  description = "Associate public IP address for worker instance"
}

variable "worker_volume_size" {
  description = "Worker Instance volume size"
  default = 30
}

variable "allow_elb" {
  description = "Allow network to ELB"
  default = "0.0.0.0/0"
}

variable "elb_api_port" {
  description = "Port for AWS ELB"
  default = 6443
}

variable "k8s_secure_api_port" {
  description = "Secure Port of K8S API Server"
  default = 6443
}
variable "empty" {
  default = "no value"
}

variable "inventory_file" {
  default = "./hosts"
  description = "Where to store the generated inventory file"
}

variable "sshconfig_file" {
  default = "./ssh_config"
  description = "Where to store the generated ssh config file"
}

variable "username" {
  description = "SSH user name"
  default = "ec2-user"
}
