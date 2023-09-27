#!/bin/bash

ip_addr="192.168.40.x"
ddns="caca.dns"
apt update
echo "ok apt"

apt install bind9 bind9-doc dnsutils

mkdir /var/log/bind
touch /var/log/bind/bind.log
chown -R bind:bind /var/log/bind
touch /etc/bind/db.nom

echo "ok creation de fichier"

echo "include \"/etc/bind/logging.conf\";" >> /etc/bind/named.conf
echo "logging {
	channel bind_log {
		file \"/var/log/bind/bind.log\";
		severity info;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	category default { bind_log; };
	category update { bind_log; };
	category update-security { bind_log; };
	category security { bind_log; };
	category queries { bind_log; };
	category lame-servers { null; };
};" >> /etc/bind/logging.conf

echo "zone \"$ddns\"{
	type master;
	file \"/etc/bind/db.nom\";
};" >> /etc/bind/named.conf.default-zones

echo "
\$TTL 1d
@ IN SOA $ddns. admin.$ddns. (
1 ; serial
6H ; refresh
3H ; retry
12H ; expire
3H ) ; minimum

@ IN NS FQDN
@ IN NS sousdomaine.caca.dns.
\$ORIGIN $ddns.

FQDN IN A $ip_addr

apachedebian IN A $ip_addr 
www IN CNAME apachedebian
" > /etc/bind/db.nom
echo "ok fichier conf"

sed -i '60i\  /var/log/bind/** rw,' /etc/apparmor.d/usr.sbin.named
systemctl restart apparmor.service
systemctl restart bind9

echo "ok apparmor + bind restart"
