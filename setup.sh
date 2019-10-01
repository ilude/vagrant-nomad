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
sudo curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

curl -L https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/33838df898b305c796ca2818acc552ca407ecc2a/gitconfig -o $HOME/.gitconfig
sudo curl -L https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/33838df898b305c796ca2818acc552ca407ecc2a/git-prompt.sh -o /etc/profile.d/git-prompt.sh
sudo chmod +x /etc/profile.d/git-prompt.sh

mkdir $HOME/.ssh
curl -L https://gist.githubusercontent.com/ilude/e2342829a97c3c3d3da5f9c73976c4ec/raw/33838df898b305c796ca2818acc552ca407ecc2a/authorized_keys -o $HOME/.ssh/authorized_keys
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/*


sudo mkdir -p /apps
sudo chown $USER:$USER /apps

# tone down the adware and login noise
sudo chmod -x 50-motd-news
sudo chmod -x 80-livepatch
sudo chmod -x 10-help-text

cat << EOF >> $HOME/.profile
# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export USERNAME=production
export RAILS_ENV=production
alias dc=docker-compose
alias l='ls --color -lha --group-directories-first'
EOF

source $HOME/.profile

echo "Fetching Consul..."
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o /tmp/consul.zip

echo "Installing Consul..."
unzip /tmp/consul.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul --version

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul