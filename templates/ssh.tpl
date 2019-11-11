Host ${bastion_hostname}
  Hostname ${bastion_hostname}
  User ${username}
  StrictHostKeyChecking no
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m

Host ${worker_hostnames}
  User ${username}
  ProxyCommand ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${username}@${bastion_hostname}