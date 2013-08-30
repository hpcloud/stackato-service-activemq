# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

require 'activemq_service/activemq_node'

module VCAP
  module Services
    module ActiveMQ
      class Node

      end
    end
  end
end

module VCAP
  module Services
    module ActiveMQ
      class ActiveMQError
          attr_reader :error_code
      end
    end
  end
end

describe "ActiveMQ service node" do
  include VCAP::Services::ActiveMQ

  before :all do
    @opts = get_node_test_config
    @opts.freeze
    @logger = @opts[:logger]
    # Setup code must be wrapped in EM.run
    EM.run do
      @node = Node.new(@opts)
      EM.add_timer(1) { EM.stop }
    end
  end

  before :each do
    @default_plan = "free"
    @default_opts = "default"
    @activemqer = @node.provision(@default_plan)
    @activemqer.should_not == nil
  end

  it "should provison a activemq service with correct credential" do
    EM.run do
      @activemqer.should be_instance_of Hash
      @activemqer["port"].should be 5002
      EM.stop
    end
  end

  it "should create a crediential when binding" do
    EM.run do
      binding = @node.bind(@activemqer["name"], @default_opts)
      binding["port"].should be 5002
      EM.stop
    end
  end

  it "should supply different credentials when binding evoked with the same input" do
    EM.run do
      binding1 = @node.bind(@activemqer["name"], @default_opts)
      binding2 = @node.bind(@activemqer["name"], @default_opts)
      binding1.should_not be binding2
      EM.stop
    end
  end

  it "shoulde delete crediential after unbinding" do
    EM.run do
      binding = @node.bind(@activemqer["name"], @default_opts)
      @node.unbind(binding)
      EM.stop
    end
  end

  after :each do
    name = @activemqer["name"]
    @node.unprovision(name)
  end
end
