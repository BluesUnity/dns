#!/bin/bash

apt update
apt install slapd ldap-utils

dpkg-reconfigure slapd

$domaine = mondomaine
$ip_ldap = 192.168.64.177

echo "
BASE dc=$domaine,dc=private
URI ldap://$ip_ldap
SIZELIMIT 12
TIMELIMIT 15
DEREF never " >> /etc/ldap/ldap.conf

ldapsearch -x -b dc=$domaine,dc=private
ldapsearch -Y external -H ldapi:/// -b cn=config "(objectClass=olcGlobal)"olcLogLevel -LLL > slapdlog.ldif
echo "
dn: cn=config
changeType: modify
replace: olcLogLevel
olcLogLevel: conns filter config ACL stats stats2" >> slapdlog.ldif

ldapmodify -Y external -H ldapi:/// -f slapdlog.ldif
echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.d/10-ldap.conf

systemctl restart rsyslog

ldapsearch -x -H ldap://localhost -D cn=admin,dc=$domaine,dc=private -W -b cn=config

