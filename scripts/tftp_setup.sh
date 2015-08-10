> /etc/default/tftpd-hpa
cat >/etc/default/tftpd-hpa<<EOL
# /etc/default/tftpd-hpa 

TFTP_USERNAME="tftp"
#TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_DIRECTORY="${PhyflexDir}/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/platform-phyFLEX-i.MX6/images"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOL
