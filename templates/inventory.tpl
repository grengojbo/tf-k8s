[all]
${connection_strings_master}
${connection_strings_worker}

#[bastion]
#${public_ip_address_bastion}

[kube-master]
${list_master}

[kube-node]
${list_worker}

[etcd]
${list_etcd}

[k8s-cluster:children]
kube-node
kube-master


#[k8s-cluster:vars]
#${elb_api_fqdn}