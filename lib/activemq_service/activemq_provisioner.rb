# Copyright (c) 2009-2011 VMware, Inc.
require 'activemq_service/common'

class VCAP::Services::ActiveMQ::Provisioner < VCAP::Services::Base::Provisioner

  include VCAP::Services::ActiveMQ::Common

end
