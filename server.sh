#! /bin/bash

(
cat <<-EOF
datacenter = "dc1"
data_dir = "/opt/consul"
encrypt = "tZp2k/wyXdU1XFvjmNlvreEe72uyBGvZpbxH5ioD4xE="
bind_addr = "$CONSUL_BIND"
retry_join = ["$CONSUL_SERVER"]
performance {
  raft_multiplier = 1
}
EOF
) | sudo tee /etc/consul.d/consul.hcl

(
cat <<-EOF
server = true
bootstrap_expect = 3
ui = true
EOF
) | sudo tee /etc/consul.d/server.hcl