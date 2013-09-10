#!/usr/bin/env bash

# Stop kato and supervisord for reconfiguration
kato stop
stop-supervisord

# Copy activemq to the services folder and update gems
cp -R /home/stackato/stackato-activemq-service /s/vcap/services/activemq
cd /s/vcap/services/activemq && bundle install

# Copy the stackato configuration files to supervisord
cp /s/vcap/services/activemq/stackato-conf/activemq_* /s/etc/supervisord.conf.d/

# Install processes and roles snippets to kato
cat /s/vcap/services/activemq/stackato-conf/processes-snippet.yml >> /s/etc/kato/processes.yml
cat /s/vcap/services/activemq/stackato-conf/roles-snippet.yml >> /s/etc/kato/roles.yml

# Restart supervisord
start-supervisord

# Install service config files to kato 
cat /s/vcap/services/activemq/config/activemq_gateway.yml | kato config set activemq_gateway / --yaml
cat /s/vcap/services/activemq/config/activemq_node.yml | kato config set activemq_node / --yaml

# Add the authentication token to kato 
kato config set cloud_controller builtin_services/activemq/token "0xdeadbeef"

# Add the role and restart kato
kato role add activemq
kato start
