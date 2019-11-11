# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${module.vpc.vpc_cidr_block}"
}

# //output "vpc_ipv6_cidr_block" {
# //  description = "The IPv6 CIDR block"
# //  value       = ["${module.vpc.vpc_ipv6_cidr_block}"]
# //}

# Subnets
# output "private_subnets" {
#   description = "List of IDs of private subnets"
#   value       = "${module.vpc.private_subnets}"
# }

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = "${module.vpc.public_subnets}"
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = "${module.vpc.nat_public_ips}"
}

# AZs
output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = "${module.vpc.azs}"
}

output "vpc_security_group_ids" {
  description = "List of VPC security group ids assigned to the instances"
  value       = "${module.security_group.this_security_group_id}"
}

## IAM

output "kube-master-profile" {
  value = "${aws_iam_instance_profile.kube-master.name}"
}

output "kube-worker-profile" {
  value = "${aws_iam_instance_profile.kube-worker.name}"
}


# Instances
output "ids" {
  description = "List of IDs of instances"
  value       = "${module.master_node.id}"
}

# output "ids_t2" {
#   description = "List of IDs of t2-type instances"
#   value       = module.ec2_with_t2_unlimited.id
# }

output "master_public_dns" {
  description = "List of public DNS names assigned to the Master instances"
  value       = "${module.master_node.public_dns}"
}
output "master_private_dns" {
  description = "List of private DNS names assigned to the Master instances"
  value       = "${module.master_node.private_dns}"
}
output "master_first_dns" {
  description = "Public DNS name assigned to the Master instance"
  value       = "${length(module.master_node.public_dns) > 0 ? module.master_node.public_dns[0] : var.cidr}"
}

output "worker_nodes" {
  value = "${module.worker_node.private_dns}"
}

# output "show_node_variable" {
#   value       = "${module.master_node}"
# }
# output "tags" {
#   description = "List of tags"
#   value       = module.ec2.tags
# }

# output "placement_group" {
#   description = "List of placement group"
#   value       = module.ec2.placement_group
# }

# output "instance_id" {
#   description = "EC2 instance ID"
#   value       = module.ec2.id[0]
# }

# output "t2_instance_id" {
#   description = "EC2 instance ID"
#   value       = module.ec2_with_t2_unlimited.id[0]
# }

# output "credit_specification" {
#   description = "Credit specification of EC2 instance (empty list for not t2 instance types)"
#   value       = module.ec2.credit_specification
# }

# output "credit_specification_t2_unlimited" {
#   description = "Credit specification of t2-type EC2 instance"
#   value       = module.ec2_with_t2_unlimited.credit_specification
# }

output "connect_to_master" {
  description = "Connection to Master node"
  value = "ssh -i \"${var.ssh_key_name}\" -F ./ssh_config ${var.username}@${module.master_node.public_dns[0]}"
}
output "connect_to_worker" {
  description = "Connection to Worker nodes"
  value = "${join("\nssh -i \"${var.ssh_key_name}\" -F ./ssh_config ${var.username}@", module.worker_node.private_dns)}"
}