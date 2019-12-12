#!/bin/bash

yum -y update
yum -y install httpd
yum -y install munin munin-node
systemctl start httpd
systemctl enable httpd
systemctl start munin-node
systemctl enable munin-node
touch /etc/httpd/conf.d/munin.conf

tee /etc/httpd/conf.d/munin.conf << EOF
alias /munin /var/www/html/munin
ScriptAlias   /munin-cgi/munin-cgi-graph /var/www/html/munin/cgi/munin-cgi-graph

#ScriptAlias /munin-cgi/ /var/www/html/munin/cgi/

# FastCGI
<Directory "/var/www/html/munin/cgi">
    Options +ExecCGI
    <IfModule mod_fcgid.c>
        SetHandler fcgid-script
    </IfModule>
    <IfModule !mod_fcgid.c>
        SetHandler cgi-script
    </IfModule>
</Directory>

<directory /var/www/html/munin>
    Satisfy Any
</directory>
EOF

chown -R munin:apache /var/log/munin/

sleep 5

echo "Restarting httpd"
systemctl restart httpd

echo "Restarting munin"
systemctl restart munin-node

echo
echo "Done, you should be good to go"
echo
