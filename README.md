ActiveMQ Service for Stackato
==================================

NOTE: This is currently in development, and is not production ready at the moment. If you're
having troubles installing this service, please take a look at the issues tab before asking a
question on IRC or by email.

This has been tested and proved working on Stackato v2.10.6

Apache ActiveMQ is an open source message broker written in Java together with a full Java Message Service (JMS) client. It provides "Enterprise Features" which in this case means fostering the communication from more than one client or server. Supported clients include the obvious Java via JMS 1.1 as well as several other "cross language" clients.

# Contributing

If you want to contribute to this service, please feel free to create issues or pull requests.

# Deploying onto Stackato

After logging into stackato as the stackato user, run the following commands:

    cd ~
    git https://github.com/ActiveState/stackato-activemq-service
    cd stackato-activemq-service

    # Edit the 'cloud_controller_uri' to reflect - you guessed it - the Cloud Controller's URI.
    vim config/activemq_gateway.yml

    # installs activemq for the stackato user under /opt/activemq.
    # Also installs any dependencies activemq relies on.
    # if you want to install a newer/older version of ActiveMQ, change the VERSION variable to your needs.
    sudo ./scripts/install-activemq.sh

    # installs the activemq service to this node
    ./scripts/bootstrap.sh

Bootstrapping runs all of the commands specified within
[the echo service example]
(https://github.com/ActiveState/stackato-echoservice/blob/master/README.md#echo-service-for-stackato),
including installing the service gems, installing to supervisord and kato, loading into Doozer,
adding the service AUTH token to the Cloud Controller, adding activemq as a role and
restarting kato. After all this is done, you should be able to see activemq as a
useable service in the Stackato client.

You'll also want to edit /s/vcap/common/lib/vcap/services_env.rb to add ACTIVEMQ_URL for all your apps
that include ActiveMQ:

      only_item(vcap_services['activemq']) do |s|
        c = s[:credentials]
        e["ACTIVEMQ_URL"] = "tcp://#{c[:username]}:#{c[:password]}@#{c[:host]}:#{c[:port]}/#{c[:name]}"
      end

once created and logged in using the CLI, you can test out the installation yourself:

```
$ st services

============== System Services ==============

+---------------+---------+------------------------------------------------+
| Service       | Version | Description                                    |
+---------------+---------+------------------------------------------------+
| activemq      | 1.0     | ActiveMQ full-text searching and indexing      |
| filesystem    | 1.0     | Persistent filesystem service                  |
| harbor        | 1.0     | External port mapping service                  |
| memcached     | 1.4     | Memcached in-memory object cache service       |
| mongodb       | 2.4     | MongoDB NoSQL store                            |
| mysql         | 5.5     | MySQL database service                         |
| postgresql    | 9.1     | PostgreSQL database service                    |
| rabbitmq      | 2.4     | RabbitMQ message queue                         |
| redis         | 2.6     | Redis key-value store service                  |
+---------------+---------+------------------------------------------------+

=========== Provisioned Services ============

$ st create-service activemq
Creating Service [activemq-be13d]: OK
$ st service activemq-be13d

activemq-be13d
+-------------+--------------------------------------+
| What        | Value                                |
+-------------+--------------------------------------+
| credentials |                                      |
| - host      | 192.168.69.147                       |
| - hostname  | 192.168.69.147                       |
| - name      | 5fec7340-befe-448e-bb19-648f5601bfb7 |
| - node_id   | activemq_node_1                      |
| - port      | 9200                                 |
|             |                                      |
| email       | s@s.com                              |
| meta        |                                      |
| - created   | Tue Jul 09 12:14:42 PDT 2013         |
| - tags      | activemq                             |
| - updated   | Tue Jul 09 12:14:42 PDT 2013         |
| - version   | 1                                    |
|             |                                      |
| properties  |                                      |
| tier        | free                                 |
| type        | generic                              |
| vendor      | activemq                             |
| version     | 1.0                                  |
+-------------+--------------------------------------+
```
