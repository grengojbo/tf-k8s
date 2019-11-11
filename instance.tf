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
  ami                    = "${var.ami == "none" ? data.aws_ami.k8s_linux.id : var.ami}"
  instance_type          = "${var.kube_master_size}"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  # vpc_security_group_ids = ["sg-12345678"]
  associate_public_ip_address = "${var.master_public_ip_address}"
  subnet_id              = "${element(tolist(module.vpc.public_subnets), 0)}"
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
    map("Etcd", "${var.etcd_member_name}"),
    var.ec2_tags)}"
}

module "worker_node" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "worker"
  instance_count         = "${var.kube_worker_num}"

  ami                    = "${var.ami == "none" ? data.aws_ami.k8s_linux.id : var.ami}"
  instance_type          = "${var.kube_worker_size}"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  associate_public_ip_address = "${var.worker_public_ip_address}"
  subnet_id              = "${element(tolist(module.vpc.public_subnets), 0)}"

  use_num_suffix = true
  # user_data = ""

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = "${var.worker_volume_size}"
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
    map("Role", "worker"),
    var.ec2_tags)}"
}

/*
* Generate ssh config file
*/
data "template_file" "sshconfig" {
  template = "${file("./templates/ssh.tpl")}"

  vars = {
    username = "${var.username}"
    worker_hostnames = "${join(" ", module.worker_node.private_dns)}"
    bastion_hostname = "${length(module.master_node.public_dns) > 0 ? module.master_node.public_dns[0] : var.cidr}"
  }
}

resource "null_resource" "create_sshconfig" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.sshconfig.rendered}' > ${var.sshconfig_file}"
  }

  triggers = {
    template = "${data.template_file.sshconfig.rendered}"
  }
}

# data "node_tags" "master" {
#   vars = {
#     tags = "${module.master_node.tags[0]}"
#   }
# }

/*
* Create Kubespray Inventory File
*
*/
data "template_file" "inventory" {
  template = "${file("templates/inventory.tpl")}"

  vars = {
    # master_hosts = "${join("\n", formatlist("%s", module.master_node.public_ip))}"
    username = "${var.username}"
    connection_strings_master = "${join("\n", formatlist("%s ansible_host=%s ansible_user=%s etcd_member_name=%s", module.master_node.tags.*.Name,  module.master_node.private_dns, var.username, module.master_node.tags.*.Etcd))}"
    connection_strings_worker = "${join("\n", formatlist("%s ansible_host=%s ansible_user=%s", module.worker_node.tags.*.Name,  module.worker_node.private_dns, var.username))}"
    list_master               = "${join("\n", module.master_node.tags.*.Name)}"
    list_etcd                 = "${join("\n", module.master_node.tags.*.Name)}"
    list_worker               = "${join("\n", module.worker_node.tags.*.Name)}"
    public_ip_address_bastion = "${length(module.master_node.public_ip) > 0 ? "bastion ansible_host=${module.master_node.public_ip[0]}" : "bastion ansible_host=${var.cidr}"}"
    elb_api_fqdn              = "apiserver_loadbalancer_domain_name=\"dc1.cluster\""
    # elb_api_fqdn              = "apiserver_loadbalancer_domain_name=\"${module.aws-elb.aws_elb_api_fqdn}\""
  }
}

resource "null_resource" "inventories" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > ${var.inventory_file}"
  }

  triggers = {
    template = "${data.template_file.inventory.rendered}"
  }
}