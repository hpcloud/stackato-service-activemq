#!/usr/bin/env bash
VERSION=5.6.0

# Install prerequisites for elasticsearch to run
apt-get update
apt-get install -y openjdk-7-jre-headless

# grabbed a mirror
# install activemq to /opt
[ -d /opt/activemq ] || mkdir /opt/activemq
wget http://psg.mtu.edu/pub/apache/activemq/apache-activemq/$VERSION/apache-activemq-$VERSION-bin.tar.gz
tar xvzf apache-activemq-$VERSION-bin.tar.gz
mv apache-activemq-$VERSION /opt/activemq
chown --recursive stackato:stackato /opt/activemq

#clean up
rm apache-activemq-$VERSION-bin.tar.gz
