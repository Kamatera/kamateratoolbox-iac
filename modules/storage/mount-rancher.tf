# mount the nfs server on rancher server:
# run following on rancher server:
# apt-get install -y nfs-common
# mkdir /mnt/storage
# echo "172.16.0.6:/storage/ /mnt/storage nfs defaults 0 0" >> /etc/fstab
# mount -a
# CERTBOT_PATH="/mnt/storage/$(ls /mnt/storage/ | grep certbot-certbot-pvc-)/etc/live/${var.defaults.root_domain}"
# if [ ! -d "$CERTBOT_PATH" ]; then echo "ERROR: $CERTBOT_PATH does not exist"; exit 1; fi
# cp /usr/local/bin/rancher_start /usr/local/bin/rancher_start.$(date +%Y-%m-%d).bak
# sed -i "s;/etc/letsencrypt/live/"'$'"(cat /etc/rancher/domain);${CERTBOT_PATH};g" /usr/local/bin/rancher_start
# docker stop rancher
# rancher_start
