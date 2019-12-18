#!/bin/bash

yum -y update
yum -y install epel-release
yum -y install munin munin-node httpd

systemctl start munin-node
systemctl enable munin-node

chown -R munin:apache /var/log/munin/

cat > /etc/httpd/conf.d/munin.conf << eof
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

eof

systemctl restart httpd

echo
echo "Install complete, thank you."
echo
