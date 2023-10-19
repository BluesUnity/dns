#!/bin/bash

apt update
apt install slapd ldap-utils
apt install rsyslog

dpkg-reconfigure slapd

domaine = "mondomaine"
ip_ldap = "192.168.64.177"

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
echo "fin rsyslog"
ldapsearch -x -H ldap://localhost -D cn=admin,dc=$domaine,dc=private -W -b cn=config

touch /etc/ldap/access-admin.ldif
echo "
dn: olcDatabase={0}config,cn=config
changeType: modify
add: olcAccess
olcAccess: to * by dn.exact=cn=admin,dc=$domaine,dc=private manage by * break
" >> /etc/ldap/acces-admin.ldif

ldapmodify -Y external -H ldapi:/// -f /etc/ldap/acces-admin.ldif

ldapsearch -x -H ldap://localhost -D cn=admin,dc=$domaine,dc=private -W -b cn=config

ldapsearch -x -s one -H ldap://localhost -D cn=admin,dc=$domaine,dc=private -W -b cn=schema,cn=config cn -LLL
echo "fin accessadmin"
touch /etc/ldap/ppolicy-module.ldif
echo "
dn: cn=module{0},cn=config
changeType: modify
add: olcModuleLoad
olcModuleLoad: ppolicy" >> /etc/ldap/ppolicy-module.ldif


