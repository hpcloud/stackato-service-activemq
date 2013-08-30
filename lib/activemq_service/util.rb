# Copyright (c) 2009-2011 VMware, Inc.
require "json"
require 'nokogiri'

module VCAP
  module Services
    module ActiveMQ
      module Util
        @rabbit_timeout = 2 if @rabbit_timeout == nil
        @local_ip = "127.0.0.1" if @local_ip == nil

	def create_resource(credentials)
	end

	def add_instance(credentials, instance)
          @logger.debug("add_instance")
          instance_name = instance.name

          env = {
          }
          
          pid = Process.spawn(env, "#{@activemq_server}bin/activemq create #{@base_dir}/#{instance_name}")
          Process.waitpid(pid)

          pid = Process.spawn(env, "#{@activemq_server}bin/activemq setup /home/stackato/.activemqrc-instance-#{instance_name}")

          Process.waitpid(pid)

          update_activemq_conf_files(credentials, instance)

          update_jetty_conf_files(credentials, instance)

          create_credentials_conf_file(credentials, instance)

          @logger.debug("add_instance......done")
	end

	def delete_instance(credentials, instance_name)
	end

	def add_user(credentials, username, password)
	end

	def delete_user(credentials, username)
	end

	def get_permissions_by_options(binding_options)
          # FIXME: binding options is not implemented, use the full permissions.
          @default_permissions
        end		

	def get_permissions(credentials, vhost, username)
        end

	def set_permissions(credentials, vhost, username, permissions)
        end

        def clear_permissions(credentials, vhost, username)
        end

        def list_users(credentials)
        end

        def list_queues(credentials, vhost)
        end

        def update_jetty_conf_files(credentials, instance)
          filename = "#{@base_dir}/#{instance.name}/conf/jetty.xml"
          doc = Nokogiri::XML(File.open(filename))

          elems = doc.xpath("//springbean:property[@name='port']","springbean" => "http://www.springframework.org/schema/beans")
          elems.attr('value').value = "#{instance.admin_port}"

          File.open(filename, 'w') {|f| f.puts doc.to_xml }
        end  

        def update_activemq_conf_files(credentials, instance)
          # update two files with port info
          filename = "#{@base_dir}/#{instance.name}/conf/activemq.xml"
          doc = Nokogiri::XML(File.open(filename))
          
          elems = doc.xpath("//activemq:transportConnector", 'activemq' => 'http://activemq.apache.org/schema/core').attr("uri")
          elems.value = "tcp://0.0.0.0:#{instance.port}"
          
          File.open(filename, 'w') {|f| f.puts doc.to_xml }
          
        end

        def create_credentials_conf_file(credentials, instance)
  
          property_file = "#{@base_dir}/#{instance.name}/conf/credentials.properties"
          properties = {}
          properties['activemq.username'] = "#{instance.admin_username}"
          properties['activemq.password'] = "#{instance.admin_password}"
          properties['guest.password'] = "stackato"

          file_contents = ""
          properties.each do |key,value| 
            file_contents << "#{key}=#{value}\n" 
          end
          File.open(property_file, 'w') { |file| file.write(file_contents) }

        end

        def close_fds
          3.upto(get_max_open_fd) do |fd|
            begin
              IO.for_fd(fd, "r").close
            rescue
            end
          end
        end

	def get_max_open_fd
          max = 0

          dir = nil
          if File.directory?("/proc/self/fd/") # Linux
            dir = "/proc/self/fd/"
          elsif File.directory?("/dev/fd/") # Mac
            dir = "/dev/fd/"
          end

          if dir
            Dir.foreach(dir) do |entry|
              begin
                pid = Integer(entry)
                max = pid if pid > max
              rescue
              end
            end
          else
            max = 65535
          end

          max
        end

      end
    end
  end
end


