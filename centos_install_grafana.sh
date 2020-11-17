#!/bin/bash
yum -y update

## Install Prometheus
useradd --no-create-home -s /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.22.2/prometheus-2.22.2.linux-amd64.tar.gz
tar xzvf prometheus-2.22.2.linux-amd64.tar.gz 
mv prometheus-2.22.2.linux-amd64/* /var/lib/prometheus/
chown -R prometheus:prometheus /var/lib/prometheus
cd
mv /var/lib/prometheus/prometheus.yml /etc/prometheus/
ln -s /var/lib/prometheus/prometheus /usr/local/bin/prometheus

tee /usr/lib/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/var/lib/prometheus/consoles \
--web.console.libraries=/var/lib/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl enable prometheus
systemctl start prometheus

## Install Node exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xzvf node_exporter-1.0.1.linux-amd64.tar.gz 
mkdir -p /var/lib/prometheus/node_exporter
mv node_exporter-1.0.1.linux-amd64/* /var/lib/prometheus/node_exporter
cd
chown -R prometheus:prometheus /var/lib/prometheus/node_exporter/

tee /usr/lib/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/var/lib/prometheus/node_exporter/node_exporter

[Install]
WantedBy=default.target
EOF

systemctl enable node_exporter
systemctl start node_exporter

tee -a /etc/prometheus/prometheus.yml << EOF
  - job_name: 'node_exporter'
    static_configs:
    - targets: ['localhost:9100']
EOF
systemctl restart prometheus

## Install Grafana
tee /etc/yum.repos.d/grafana.repo << EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

yum -y makecache fast
yum install -y grafana
systemctl enable grafana-server
systemctl start grafana-server

echo "grafana is installed, please check on http://<server>:3000"



