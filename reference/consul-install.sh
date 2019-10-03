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