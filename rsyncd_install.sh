#!/bin/bash

# install rsync
apt install -y rsync
rsync --version
echo 'rsync_backup:$123$rsync_backup$456$' >/etc/rsync.password

# config rsync
cat > /etc/rsyncd.conf <<eof
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsync.log
port = 12000

[files]
path = /data
comment = RSYNC FILES
read only = true
timeout = 300
eof

# create backup directory
mkdir /data
chown -R rsync.rsync /data
chmod 600 /etc/rsync.password

# start rsync service
systemctl enable rsync
systemctl start rsync

# view if it is running ok
netstat -lntp
cat /var/run/rsyncd.pid

