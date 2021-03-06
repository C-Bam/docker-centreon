#!/bin/sh

# Workaround to get initial configuration from
# archived dir centreon.initial (created during docker build)
if [ ! -f "/etc/centreon/.done" ]; then
  cp -a /etc/centreon.initial/* /etc/centreon/
  touch "/etc/centreon/.done"
fi

# Workaround centreon stuck into infinite install wizard loop
# /!\ After firstrun wizard, RESTART docker so that code gets
# executed
if [ -f "/etc/centreon/conf.pm" -a "${1}" != "upgrade" ]; then
  rm -rf /srv/centreon/www/install/
fi

# Fix perms (do it all the time because centreon uid may change)
chown -R www-data:centreon /etc/centreon
chmod 750 /etc/centreon

# Init folder for the first time
find /var/log/centreon-engine/      -maxdepth 0 -empty -exec rsync -avz /var/log/centreon-engine.initial/ /var/log/centreon-engine/ \;
find /var/lib/centreon-engine/      -maxdepth 0 -empty -exec rsync -avz /var/lib/centreon-engine.initial/ /var/lib/centreon-engine/ \;
find /var/log/centreon-broker/      -maxdepth 0 -empty -exec rsync -avz /var/log/centreon-broker.initial/ /var/log/centreon-broker/ \;
find /var/lib/centreon-broker/      -maxdepth 0 -empty -exec rsync -avz /var/lib/centreon-broker.initial/ /var/lib/centreon-broker/ \;
find /var/lib/centreon/             -maxdepth 0 -empty -exec rsync -avz /var/lib/centreon.initial/        /var/lib/centreon/        \;
find /var/cache/nagvis/userfiles/   -maxdepth 0 -empty -exec rsync -avz /var/cache/nagvis/userfiles.initial/      /var/cache/nagvis/userfiles/ \;
find /etc/centreon-broker/          -maxdepth 0 -empty -exec rsync -avz /etc/centreon-broker.initial/ /etc/centreon-broker/ \;
find /etc/centreon-engine/          -maxdepth 0 -empty -exec rsync -avz /etc/centreon-engine.initial/ /etc/centreon-engine/ \;

# Bad permissions can occurs as the volume is on the host
# systemd uid of centreon-broker and centreon-engine
# may change when regenerating container
chown -R centreon-broker:centreon-broker /etc/centreon-broker/ /var/log/centreon-broker/ /var/lib/centreon-broker/
chown -R centreon-engine:centreon-engine /etc/centreon-engine/ /var/log/centreon-engine/ /var/lib/centreon-engine/
chown -R centreon:centreon-broker /var/lib/centreon/metrics/ /var/lib/centreon/status/
find /var/lib/centreon/metrics/ -type f -exec chmod 0664 {} \;
find /var/lib/centreon/status/ -type f -exec chmod 0664 {} \;
find /var/log/centreon-broker/ -type f -exec chmod 0664 {} \;
find /var/log/centreon-engine/ -type f -exec chmod 0664 {} \;

# Init like system to start services
supervisord -n -c /etc/supervisor/supervisord.conf -e debug
