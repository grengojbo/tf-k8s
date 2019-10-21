data "aws_ami" "k8s_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

# resource "aws_eip" "this" {
#   vpc      = true
#   instance = module.ec2.id[0]
# }

# resource "aws_placement_group" "web" {
#   name     = "hunky-dory-pg"
#   strategy = "cluster"
# }

# resource "aws_kms_key" "this" {
# }

module "master_node" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "master"
  instance_count         = "${var.kube_master_num}"

  # ami                    = "ami-ebd02392"
  ami                    = "${data.aws_ami.k8s_linux.id}"
  instance_type          = "${var.kube_master_size}"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  # vpc_security_group_ids = ["sg-12345678"]
  associate_public_ip_address = "${var.master_public_ip_address}"
  # subnet_id              = tolist(module.vpc.public_subnets)[0]
  # placement_group             = aws_placement_group.web.id

  use_num_suffix = true
  # user_data = ""

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = "${var.master_volume_size}"
    },
  ]

  # ebs_block_device = [
  #   {
  #     device_name = "/dev/sdf"
  #     volume_type = "gp2"
  #     volume_size = 5
  #     encrypted   = true
  #     kms_key_id  = aws_kms_key.this.arn
  #   }
  # ]

  tags = "${merge(
    map("app", "${var.app_name}"),
    map( "kubernetes.io/cluster/${var.cluster_name}", "member"),
    map("Role", "master"),
    var.ec2_tags)}"
}

module "worker_node" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "worker"
  instance_count         = "${var.kube_worker_num}"

  # ami                    = "ami-ebd02392"
  ami                    = "${data.aws_ami.k8s_linux.id}"
  instance_type          = "${var.kube_master_size}"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  # vpc_security_group_ids = ["sg-12345678"]
  associate_public_ip_address = "${var.master_public_ip_address}"
  # subnet_id              = tolist(module.vpc.public_subnets)[0]
  # placement_group             = aws_placement_group.web.id

  use_num_suffix = true
  # user_data = ""

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = "${var.master_volume_size}"
    },
  ]

  # ebs_block_device = [
  #   {
  #     device_name = "/dev/sdf"
  #     volume_type = "gp2"
  #     volume_size = 5
  #     encrypted   = true
  #     kms_key_id  = aws_kms_key.this.arn
  #   }
  # ]

  tags = "${merge(
    map("app", "${var.app_name}"),
    map( "kubernetes.io/cluster/${var.cluster_name}", "member"),
    map("Role", "master"),
    var.ec2_tags)}"
}