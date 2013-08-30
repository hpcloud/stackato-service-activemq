# Copyright (c) 2009-2011 VMware, Inc.
require "fileutils"
require "logger"
require "datamapper"
require "uuidtools"
require 'socket'

module VCAP
  module Services
    module ActiveMQ
      class Node < VCAP::Services::Base::Node
      end
    end
  end
end

require "activemq_service/common"
require "activemq_service/activemq_error"
require "activemq_service/util"

VALID_CREDENTIAL_CHARACTERS = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a

class VCAP::Services::ActiveMQ::Node

  include VCAP::Services::ActiveMQ::Common
  include VCAP::Services::ActiveMQ::Util
  include VCAP::Services::ActiveMQ

  class ProvisionedService
    include DataMapper::Resource
    property :name,		String,   :key => true
    property :port,		Integer,  :unique => true
    property :plan,		Integer,  :required => true
    property :plan_option,	String,   :required => false 
    property :admin_port,	Integer,  :unique => true
    property :admin_username,	String,   :required => true
    property :admin_password,	String,   :required => true
    # property plan is deprecated. The instances in one node have same plan.
    property :pid,              Integer
    property :memory,           Integer,  :required => true
    property :status,           Integer,  :default => 0

    def listening?(interface_ip, instance_port=port)
      puts "*** listening?"

      begin
        TCPSocket.open(interface_ip, instance_port).close
        return true
      rescue => e
        return false
      end
    end

    def running?
      puts "*** running"
      value = true
      #system("/var/vcap/services/activemq/instances/#{name}/bin/#{name} status")
      hostname = Socket.gethostname
      pidfile = "/var/vcap/services/activemq/instances/#{name}/data/activemq-#{hostname}.pid"
      begin
        pid = IO.read(pidfile).to_i
      rescue
        value = false 
      end
      value 
    end

    def kill(sig=:SIGTERM)
      puts("*** kill")

      #system("/var/vcap/services/activemq/instances/#{name}/bin/#{name} stop")
      
      hostname = Socket.gethostname
      pidfile = "/var/vcap/services/activemq/instances/#{name}/data/activemq-#{hostname}.pid"
      pid = IO.read(pidfile).to_i
      Process.kill(:SIGKILL, pid) if Process.kill(0, pid)
      FileUtils.rm_r("/var/vcap/services/activemq/instances/#{name}/data/activemq-#{hostname}.pid")
      puts("*** (pid= #{pid}) kill..end")

    end

    def wait_killed(timeout=10, interval=0.2)
      puts "*** wait_killed"
      begin
        Timeout::timeout(timeout) do
          #@wait_thread.join if @wait_thread
          while running? do
            sleep interval
          end
        end
      rescue Timeout::Error
        return false
      end
      true
    end

  end


  def all_bindings_list
    @logger.debug("*************")
  end

  def initialize(options)
    super(options)
    

    @supported_versions = ["1.0"]

    @free_ports = Set.new
    @free_admin_ports = Set.new
    @free_ports_mutex = Mutex.new
    options[:port_range].each {|port| @free_ports << port}
    options[:admin_port_range].each {|port| @free_admin_ports << port}
    @port_gap = options[:admin_port_range].first - options[:port_range].first
  
    @max_memory_factor = options[:max_memory_factor] || 0.5
    @local_db = options[:local_db]
    @binding_options = nil
    @base_dir = options[:base_dir]
    FileUtils.mkdir_p(@base_dir) if @base_dir
    @activemq_server = @options[:activemq_server]
    @activemq_log_dir = @options[:activemq_log_dir]
    @max_clients = @options[:max_clients] || 500

    @initial_username = "guest"
    @initial_password = "guest"
    @hostname = get_host
  end


  def pre_send_announcement
    super
    FileUtils.mkdir_p(@base_dir) if @base_dir
    start_db
    start_provisioned_instances
  end

  def start_provisioned_instances
    @logger.debug("*** start_provisioned_instances ***")
    @capacity_lock.synchronize do
      ProvisionedService.all.each do |instance|
        @free_ports_mutex.synchronize do
          @free_ports.delete(instance.port)
          @free_admin_ports.delete(instance.admin_port)
        end
        @capacity -= capacity_unit

        if instance.listening?(@local_ip)
          @logger.warn("Service #{instance.name} already running on port #{instance.port}")
          next
        end
        begin
          instance.pid = start_instance(instance)
          save_instance(instance)
        rescue => e
          @logger.warn("Error starting instance #{instance.name}: #{e}")
          begin
            cleanup_instance(instance)
          rescue => e2
            # Ignore the rollback exception
          end
        end
      end
    end    
  end

  def shutdown
    super
    ProvisionedService.all.each { |instance|
      @logger.debug("Try to terminate ActiveMQ server pid:#{instance.pid}")
      instance.kill
      instance.wait_killed ?
        @logger.debug("ActiveMQ server pid: #{instance.pid} terminated") :
        @logger.error("Timeout to terminate ActiveMQ server pid: #{instance.pid}")
    }
    true
  end

  def announcement
    @capacity_lock.synchronize do
      { :available_capacity => @capacity,
        :capacity_unit => capacity_unit }
    end
  end

  def provision(plan, credentials = nil, version=nil)
    raise ActiveMQError.new(ActiveMQError::ACTIVEMQ_INVALID_PLAN, plan) unless plan.to_s == @plan

    instance = ProvisionedService.new
    instance.plan = 1
    instance.plan_option = ""
    if credentials
      instance.name = credential["name"]
      instance.admin_username = credentials["user"]
      instance.admin_password = credentials["pass"]
      @free_ports_mutex.synchronize do
      if @free_ports.include?(credentials["port"])
        @free_ports.delete(credentials["port"])
        @free_admin_ports.delete(credentials["port"] + @port_gap)
        instance.port = credentials["port"]
        instance.admin_port = credentials["port"] + @port_gap
      else
        port = @free_ports.first
        @free_ports.delete(port)
        @free_admin_ports.delete(port + @port_gap)
        instance.port = port
        instance.admin_port = port + @port_gap
       end
      end
    else
      instance.name = UUIDTools::UUID.random_create.to_s
      instance.admin_username = "au" + generate_credential
      instance.admin_password = "ap" + generate_credential
      port = @free_ports.first
      @free_ports.delete(port)
      @free_admin_ports.delete(port + @port_gap)
      instance.port = port
      instance.admin_port = port + @port_gap
    end
    begin
      #FIXME: actually this field has no effect on instance, the memory usage is decided by max_capacity
      instance.memory = 1
    rescue => e
      raise e
    end
    begin

      add_instance(credentials, instance)

      start_instance(instance)

      save_instance(instance)

      credentials = {"username" => @initial_username, "password" => @initial_password, "admin_port" => instance.admin_port}

      credentials["username"] = instance.admin_username
      credentials["password"] = instance.admin_password
      credentials["admin_port"] = instance.admin_port

    rescue => e1
      @logger.error("Could not save instance: #{instance.name}, cleanning up")
      begin
        #destroy_instance(instance)
      rescue => e2
        @logger.error("Could not clean up instance: #{instance.name}")
      end
      raise e1
    end

    gen_credential(instance)
  end

  def unprovision(name, credentials = [])
    return if name.nil?
    @logger.debug("Unprovision activemq service: #{name}")
    instance = get_instance(name)
    destroy_instance(instance)
    {} 
  end

  def bind(instance_id, binding_options, binding_credentials = nil)
    instance = get_instance(instance_id)
    user = nil
    pass = nil
    if binding_credentials
      user = binding_credentials["user"]
      pass = binding_credentials["pass"]
    else
      user = "u" + generate_credential
      pass = "p" + generate_credential
    end
    credentials = gen_admin_credentials(instance)
    gen_credentials(instance, user, pass)
  end

  def unbind(credential)

    @logger.debug("Unbind service: #{credential.inspect}")
    true
  end

  def start_db
    DataMapper.setup(:default, @local_db)
    DataMapper::auto_upgrade!
  end

  def save_instance(instance)

    raise ActiveMQError.new(ActiveMQError::ACTIVEMQ_SAVE_INSTANCE_FAILED, instance.inspect) unless instance.save
    true
  end

  def destroy_instance(instance)
    @logger.debug("destroy_instance")
    dir = instance_dir(instance.name)
    stop_instance(instance)
    FileUtils.rm_r(dir) 
    FileUtils.rm_r("/home/stackato/.activemqrc-instance-#{instance.name}")

    raise ActiveMQError.new(ActiveMQError::ACTIVEMQ_DESTROY_INSTANCE_FAILED, instance.inspect) unless instance.destroy
  end

  def get_instance(name)
    @logger.debug("get_instance")
    instance = ProvisionedService.get(name)
    raise ActiveMQError.new(ActiveMQError::ACTIVEMQ_FIND_INSTANCE_FAILED, name) if instance.nil?
    instance
  end

  def gen_credential(instance, user = nil, pass = nil)
    @logger.debug("gen_credential")

    credentials = {
      "name" => instance.name,
      "host" => @hostname,
      "hostname" => @hostname,
      "port" => instance.port,
    }

    if user && pass # Binding request
      credentials["username"] = user
      credentials["user"] = user
      credentials["password"] = pass
      credentials["pass"] = pass
    else # Provision request
      credentials["username"] = instance.admin_username
      credentials["user"] = instance.admin_username
      credentials["password"] = instance.admin_password
      credentials["pass"] = instance.admin_password
    end

    credentials["url"] = "tcp://#{credentials["user"]}:#{credentials["pass"]}@#{credentials["host"]}:#{credentials["port"]}"
    credentials
  end

  def start_instance(instance)
    @logger.debug("Starting: #{instance.inspect} on port #{instance.port}")
    
    #$0 = "Starting ActiveMQ instance: #{instance.name}"

    dir = instance_dir(instance.name)
    config_dir = File.join(dir, "config")
    log_dir = instance_log_dir(instance.name)
    admin_port = instance.admin_port

    #placeholder
    instance.pid = 1

    @logger.debug("*** starting main process: #{@base_dir}/#{instance.name}/bin/#{instance.name}")

    env = {}

    pid = Process.spawn(env, "#{@base_dir}/#{instance.name}/bin/#{instance.name} start")

    # In parent, detach the child
    Process.detach(pid)

    instance.pid = pid

    @logger.debug("Service #{instance.name} started with pid #{pid}")

  end

  def stop_instance(instance)
    instance.kill
    EM.defer do
      FileUtils.rm_rf(instance_dir(instance.name))
      FileUtils.rm_rf(instance_log_dir(instance.name))
    end
  end

  def instance_dir(instance_id)
    File.join(@base_dir, instance_id)
  end

  def instance_log_dir(instance_id)
    File.join(@activemq_log_dir, instance_id)
  end

  def import_instance(service_credentials, binding_credentials_map, dump_dir, plan)
    @logger.debug(import_instance)
    provision(plan, service_credentials)
  end

  def generate_credential(length = 12)
    Array.new(length) {VALID_CREDENTIAL_CHARACTERS[rand(VALID_CREDENTIAL_CHARACTERS.length)]}.join
  end

  def get_varz(instance)
    varz = {}
    varz[:name] = instance.name
    varz[:plan] = @plan
    varz[:admin_username] = instance.admin_username
    varz[:usage] = {}
    credentials = gen_admin_credentials(instance)
    varz
  end

  def varz_details
    varz = {}
    varz[:provisioned_instances] = []
    varz[:provisioned_instances_num] = 0
    varz[:max_capacity] = @max_capacity
    varz[:available_capacity] = @capacity
    varz[:instances] = {}
    ProvisionedService.all.each do |instance|
      varz[:instances][instance.name.to_sym] = get_status(instance)
    end
    ProvisionedService.all.each do |instance|
      varz[:provisioned_instances_num] += 1
      begin
        varz[:provisioned_instances] << get_varz(instance)
      rescue => e
        @logger.warn("Failed to get instance #{instance.name} varz details: #{e}")
      end
    end
    varz
  rescue => e
    @logger.warn(e)
    {}
  end

  def get_status(instance)
    get_permissions(gen_admin_credentials(instance), instance.name, instance.admin_username) ? "ok" : "fail"
  rescue => e
    "fail"
  end

  def gen_credentials(instance, user = nil, pass = nil)

    credentials = {
      "name" => instance.name,
      "hostname" => @hostname,
      "host" => @hostname,
      "port"  => instance.port,
    }
    if user && pass # Binding request
      credentials["username"] = user
      credentials["user"] = user
      credentials["password"] = pass
      credentials["pass"] = pass
    else # Provision request
      credentials["username"] = instance.admin_username
      credentials["user"] = instance.admin_username
      credentials["password"] = instance.admin_password
      credentials["pass"] = instance.admin_password
    end
    credentials["tcp"] = "amqp://#{credentials["user"]}:#{credentials["pass"]}@#{credentials["host"]}:#{credentials["port"]}/#{credentials["name"]}"
    credentials
  end

  def gen_admin_credentials(instance)
    credentials = {
      "admin_port"  => instance.admin_port,
      "username" => instance.admin_username,
      "password" => instance.admin_password,
    }
  end
end
