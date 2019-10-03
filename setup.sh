#! /bin/bash

# Update apt and get dependencies
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip curl vim apt-transport-https ca-certificates software-properties-common

CONSUL_VERSION=1.6.1


echo "Installing Docker..."
if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
    echo "Docker repository already installed; Skipping"
else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
fi
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce

# Make sure we can actually use docker as the vagrant user
sudo usermod -aG docker $USER
sudo systemctl enable docker
# Restart docker to make sure we get the latest version of the daemon if there is an upgrade
sudo service docker restart

mkdir -p $HOME/.ssh
curl -sSL https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/e858de0efb18a01795b9722796b6126df9696ce1/authorized_keys_limited -o $HOME/.ssh/authorized_keys
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/*

sudo mkdir -p /apps
sudo chown $USER:$USER /apps

# tone down the adware and login noise
sudo chmod -x 50-motd-news > /dev/null 2>&1
sudo chmod -x 80-livepatch > /dev/null 2>&1
sudo chmod -x 10-help-text > /dev/null 2>&1

cat << EOF >> $HOME/.profile
alias l='ls --color -lha --group-directories-first'
EOF

source $HOME/.profile

sudo docker pull consul

FILE=/vagrant/consul-server.ip
if [ ! -e "$FILE" ]; then
  ip -h route get 1 | awk '{print $7;exit}' > $FILE
fi
export CONSUL_SERVER=$(cat $FILE)
export BIND_ADDR=$(ip -h route get 1 | awk '{print $7;exit}')

FILE=/vagrant/consul-server.key
if [ ! -e "$FILE" ]; then
 sudo docker run --rm -it consul consul keygen | awk '{print $1;exit}' > $FILE
fi
export CONSUL_KEY=$(cat $FILE)

mkdir -p /apps/consul/etc

(
cat <<-EOF
datacenter = "dc1"
encrypt = "$CONSUL_KEY"
bind_addr = "$BIND_ADDR"
retry_join = ["$CONSUL_SERVER"]
performance {
  raft_multiplier = 1
}
EOF
) | sudo tee /apps/consul/etc/consul.hcl

(
cat <<-EOF
server = true
bootstrap_expect = 3
ui = true
EOF
) | sudo tee /apps/consul/etc/server.hcl

(
cat <<-EOF
[Unit]
Description=Docker Container %I
Requires=docker.service
After=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStop=/usr/bin/docker stop -t 2 %i
ExecStart=/usr/bin/docker run \
 --rm \
 --net=host \
 --name=consul \
 -v /apps/consul/etc/:/consul/config/ \
 -v /apps/consul/data/:/consul/data/ \
 consul agent -server

[Install]
WantedBy=default.target
EOF
) | sudo tee /etc/systemd/system/docker-container@consul.service

sudo systemctl enable docker-container@consul
sudo systemctl start docker-container@consul
sudo systemctl status docker-container@consul
