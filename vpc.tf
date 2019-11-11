# data "aws_security_group" "default" {
#   name   = "default"
#   vpc_id = "${module.vpc.vpc_id}"
# }

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "SG-${var.app_name}"
  description = "Security group for kubernetes usage with EC2 instance"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  # https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  ingress_rules       = ["ssh-tcp", "https-443-tcp", "http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
  tags = "${merge(map("app", "${var.app_name}"), var.vpc_tags)}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "VPC-${var.app_name}"
  cidr = "${var.cidr}"

  azs             = "${var.azs}"
  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = "${var.public_subnets}"

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # tags = "${merge(map("Name", "VPC-${var.app_name}"), map("app", "${var.app_name}"), var.vpc_tags)}"
  tags = "${merge(map("app", "${var.app_name}"), var.vpc_tags)}"
  vpc_tags = {
    Name = "VPC-${var.app_name}"
  }
  # public_subnet_tags = {
  #   Name = "SUBNET-${var.app_name}"
  # }
}