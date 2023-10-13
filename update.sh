#!/bin/bash

echo "
smtpd_tls_auth_only = yes
smtpd_tls_security_level = encrypt
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_tls_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination
broken_sasl_auth_clients = yes" >> /etc/postfix/main.cf 

systemctl restart postfix
echo check"
