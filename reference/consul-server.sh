#! /bin/bash

(
cat <<-EOF
  [Unit]
  Description="Consul Server"
  Documentation=https://www.consul.io/
  Requires=network-online.target
  After=network-online.target
  ConditionFileNotEmpty=/etc/consul.d/consul.hcl

  [Service]
  User=consul
  Group=consul
  ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
  ExecReload=/usr/local/bin/consul reload
  KillMode=process
  Restart=on-failure
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
EOF
) | sudo tee /etc/systemd/system/consul.service

sudo mkdir --parents /etc/consul.d


FILE=/vagrant/server_ip
if [ -f "$FILE" ]; then
  export CONSUL_SERVER=$(cat $FILE)
else 
  ip -h route get 1 | awk '{print $7;exit}' > $FILE
  export CONSUL_SERVER=$(cat $FILE)
fi

export  CONSUL_BIND=$(ip -h route get 1 | awk '{print $7;exit}')

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

sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/*.hcl

sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul
