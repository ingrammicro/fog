require 'fog/core/model'

module Fog
  module Compute
    class VcloudDirector
      class EdgeGatewayExternalConnection < Model
        attribute :ip_address
        attribute :is_used_in_rule, :type => :boolean, :default => false
        attribute :external_network_name
        attribute :external_network_href	
      end      
    end
  end
end
