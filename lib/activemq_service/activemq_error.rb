# Copyright (c) 2009-2011 VMware, Inc.

module VCAP
  module Services
    module ActiveMQ
      class ActiveMQError < VCAP::Services::Base::Error::ServiceError
        # 31300 - 31399  ActiveMQ-specific Error
        ACTIVEMQ_SAVE_INSTANCE_FAILED         = [31300, HTTP_INTERNAL, "Could not save instance: %s"]
        ACTIVEMQ_DESTORY_INSTANCE_FAILED      = [31301, HTTP_INTERNAL, "Could not destroy instance: %s"]
        ACTIVEMQ_FIND_INSTANCE_FAILED         = [31302, HTTP_NOT_FOUND, "Could not find instance: %s"]
        ACTIVEMQ_START_INSTANCE_FAILED        = [31303, HTTP_INTERNAL, "Could not start instance: %s"]
        ACTIVEMQ_STOP_INSTANCE_FAILED         = [31304, HTTP_INTERNAL, "Could not stop instance: %s"]
        ACTIVEMQ_CLEANUP_INSTANCE_FAILED      = [31305, HTTP_INTERNAL, "Could not cleanup instance, the reasons: %s"]
        ACTIVEMQ_INVALID_PLAN                 = [31306, HTTP_INTERNAL, "Invalid plan: %s"]
        ACTIVEMQ_START_SERVER_FAILED          = [31307, HTTP_INTERNAL, "Could not start activemq server"]
        ACTIVEMQ_STOP_SERVER_FAILED           = [31308, HTTP_INTERNAL, "Could not stop activemq server"]
        ACTIVEMQ_ADD_VHOST_FAILED             = [31309, HTTP_INTERNAL, "Could not add vhost: %s"]
        ACTIVEMQ_DELETE_VHOST_FAILED          = [31310, HTTP_INTERNAL, "Could not delete vhost: %s"]
        ACTIVEMQ_ADD_USER_FAILED              = [31311, HTTP_INTERNAL, "Could not add user: %s"]
        ACTIVEMQ_DELETE_USER_FAILED           = [31312, HTTP_INTERNAL, "Could not delete user: %s"]
        ACTIVEMQ_GET_PERMISSIONS_FAILED       = [31313, HTTP_INTERNAL, "Could not get user %s permission"]
        ACTIVEMQ_SET_PERMISSIONS_FAILED       = [31314, HTTP_INTERNAL, "Could not set user %s permission to %s"]
        ACTIVEMQ_CLEAR_PERMISSIONS_FAILED     = [31315, HTTP_INTERNAL, "Could not clean user %s permissions"]
        ACTIVEMQ_GET_VHOST_PERMISSIONS_FAILED = [31316, HTTP_INTERNAL, "Could not get vhost %s permissions"]
        ACTIVEMQ_LIST_USERS_FAILED            = [31317, HTTP_INTERNAL, "Could not list users"]
        ACTIVEMQ_LIST_QUEUES_FAILED           = [31318, HTTP_INTERNAL, "Could not list queues on vhost %s"]
        ACTIVEMQ_LIST_EXCHANGES_FAILED        = [31319, HTTP_INTERNAL, "Could not list exchanges on vhost %s"]
        ACTIVEMQ_LIST_BINDINGS_FAILED         = [31320, HTTP_INTERNAL, "Could not list bindings on vhost %s"]
        ACTIVEMQ_INSTANCE_CREATE_FAILED         = [31321, HTTP_INTERNAL, "Could not create instance %s"]
      end
    end
  end
end
