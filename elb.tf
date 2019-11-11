module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "ELB-${var.cluster_name}"
  description = "Security group for kebernetes ELB"
  vpc_id      = "${module.vpc.vpc_id}"

  # ingress_cidr_blocks = "${var.allow_elb}"
  # https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  ingress_with_cidr_blocks = [
    {
      from_port   = "${var.elb_api_port}"
      to_port     = "${var.k8s_secure_api_port}"
      protocol    = "tcp"
      description = "Kubernetes Secure API port (ipv4)"
      cidr_blocks = "${var.allow_elb}"
    },
  ]
  egress_rules        = ["all-all"]
  tags = "${merge(map("app", "${var.app_name}"), map("cluster", "${var.cluster_name}"), var.vpc_tags)}"
}