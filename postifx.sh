#!/bin/bash

export http_proxy=http://cache.univ-pau.fr:3128
export https_proxy=http://cache.univ-pau.fr:3128



hostname="postfix"
mydomain="caca.tls"
apt update
apt install dovecot-imapd
apt install postfix

hostname $hostname

echo "
# See /usr/share/postfix/main.cf.dist for a commented, more complete version


# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP \$mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 3.6 on
# fresh installs.
compatibility_level = 3.6
# TLS parameters
#smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
#smtpd_tls_key_file=/etc/ssl/certs/ssl-cert-snakeoil.key
#smtpduse_tls=yes
#smtpd_tls_session_cached_database = btree:\${datadirectory}/smtpd_scache
#smtp_tls_session_cached_database = btree:\${datadirectory}/smtp_scache

mydomain = "$mydomain"
myhostname = "$hostname.$mydomain"
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = $hostname.\$mydomain, localhost.\$mydomain, localhost
default_transport = smtp
#relayhost =
mynetworks = 127.0.0.0/8 192.168.40.0/24
virtual_transport = dovecot
mail_spool_directory = /opt/messagerie/
virtual_mailbox_base = /opt/messagerie/
virtual_mailbox_domains = hash:/etc/postfix/vdomain
virtual_mailbox_maps = hash:/etc/postfix/vmail
virtual_alias_maps = hash:/etc/postfix/valias
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000
recipient_delimiter =
inet_interfaces = all
inet_protocols = ipv4
local_recipient_maps =
local_transport = virtual" > /etc/postfix/main.cf



sudo adduser toto << ENDX
tprzo.40
tprzo.40
First Last





ENDX

sudo adduser titi << ENDX
tprzo.40
tprzo.40
First Last




O
ENDX
echo "O"
postfix check
systemctl restart postfix
echo "check 2 "

#FIN CONFIG POSTFIX

sed -i '10i\ disable_plaintext_auth = no ' /etc/dovecot/conf.d/10-auth.conf
sed -i '11i\ auth_mechanisms = login plain' /etc/dovecot/conf.d/10-auth.conf
sed -i '24i\ mail_location = maildir:~/Maildir ' /etc/dovecot/conf.d/10-mail.conf

echo "
log_path = syslog

syslog_facility = mail

auth_verbose = yes

auth_debug = yes
" > /etc/dovecot/conf.d/10-logging.conf

systemctl restart dovecot


echo "check 2 "


mkdir /opt/messagerie
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /opt/messagerie -m
chown -R vmail:vmail /opt/messagerie

echo "$mydomaine #" > /etc/postfix/vdomain
echo "
loulou@$mydomain $mydomain/loulou/
mimi@$mydomain $mydomain/mimi/
admin@$mydomain $mydomain/admin/" > /etc/postfix/vmail

echo "root: admin@$mydomain" > /etc/postfix/valias

echo "
dovecot unix - n n - - pipe
    flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/deliver -f \${sender} -d \${recipient} " >> /etc/postfix/master.cf

echo "Fin des configs"

postmap /etc/postfix/vdomain
postmap /etc/postfix/vmail
postalias /etc/postfix/valias
postfix check
echo "fin des checks"

echo "
disable_plaintext_auth = yes
auth_mechanisms = cram-md5 login plain
#!include auth-deny.conf.ext
#!include auth-master.conf.ext
#!include auth-system.conf.ext
#!include auth-sql.conf.ext
#!include auth-ldap.conf.ext
#!include auth-passwdfile.conf.ext
#!include auth-checkpassword.conf.ext
#!include auth-vpopmail.conf.ext
!include auth-static.conf.ext" > /etc/dovecot/conf.d/10-auth.conf



echo "
passdb {
    #driver = static
    #args = proxy=y host=%1Mu.example.com nopassword=y
    driver = passwd-file
    args = username_format=%u /etc/dovecot/dovecot.users
}
userdb {
    driver = static
    #args = uid=vmail gid=vmail home=/home/%u
    args = uid=vmail gid=vmail home=/opt/messagerie/%d/%n/ allow_all_users=yes
}

" > /etc/dovecot/conf.d/auth-static.conf.ext

sed -i '109i\ mail_uid = 5000 ' /etc/dovecot/conf.d/10-mail.conf
sed -i '110i\ mail_gid = 5000 ' /etc/dovecot/conf.d/10-mail.conf
sed -i '115i\ mail_privileged_group = vmail ' /etc/dovecot/conf.d/10-mail.conf

echo "
#default_process_limit = 100
#default_client_limit = 1000

# Default VSZ (virtual memory size) limit for service processes. This is mainly
# intended to catch and kill processes that leak memory before they eat up
# everything.
#default_vsz_limit = 256M

# Login user is internally used by login processes. This is the most untrusted
# user in Dovecot system. It shouldn't have access to anything at all.
#default_login_user = dovenull

# Internal user is used by unprivileged processes. It should be separate from
# login user, so that login processes can't disturb other processes.
#default_internal_user = dovecot

service imap-login {
  inet_listener imap {
    #port = 143
  }
  inet_listener imaps {
    #port = 993
    #ssl = yes
  }

  # Number of connections to handle before starting a new process. Typically
  # the only useful values are 0 (unlimited) or 1. 1 is more secure, but 0
  # is faster. <doc/wiki/LoginProcess.txt>
  #service_count = 1

  # Number of processes to always keep waiting for more connections.
  #process_min_avail = 0

  # If you set service_count=0, you probably need to grow this.
  #vsz_limit = \$default_vsz_limit
}

service pop3-login {
  inet_listener pop3 {
    #port = 110
  }
  inet_listener pop3s {
    #port = 995
    #ssl = yes
  }
}

service submission-login {
  inet_listener submission {
    #port = 587
  }
}

service lmtp {
  unix_listener lmtp {
    #mode = 0666
  }

  # Create inet listener only if you can't use the above UNIX socket
  #inet_listener lmtp {
    # Avoid making LMTP visible for the entire internet
    #address =
    #port = 
  #}
}

service imap {
  # Most of the memory goes to mmap()ing files. You may need to increase this
  # limit if you have huge mailboxes.
  #vsz_limit = \$default_vsz_limit

  # Max. number of IMAP processes (connections)
  #process_limit = 1024
}

service pop3 {
  # Max. number of POP3 processes (connections)
  #process_limit = 1024
}

service submission {
  # Max. number of SMTP Submission processes (connections)
  #process_limit = 1024
}

service auth {
	unix_listener auth-userdb {
		#mode = 0666
		user = vmail
		group = vmail
}
	unix_listener /var/spool/postfix/private/auth {
		mode = 0666
		user = postfix
		group = postfix
}
}

service auth-worker {
  # Auth worker process is run as root by default, so that it can access
  # /etc/shadow. If this isn't necessary, the user should be changed to
  # \$default_internal_user.
  #user = root
}

service dict {
  # If dict proxy is used, mail processes should have access to its socket.
  # For example: mode=0660, group=vmail and global mail_access_groups=vmail
  unix_listener dict {
    #mode = 0600
    #user = 
    #group = 
  }
}
"/etc/dovecot/conf.d/10-master.conf

echo "check mail conf + dovecot finish"
doveadm pw -s CRAM-MD5 << ENDX
tprzo.40
tprzo.40
ENDX


echo "loulou@domaine.tld:{CRAM-MD5}017ec858afebdc0a0bf7ab508169465750335f608ae201ca22b333b0aaa84f3a:::::" > /etc/dovecot/dovecot.users

systemctl restart postfix
systemctl restart dovecot.service

echo "double restart check"
