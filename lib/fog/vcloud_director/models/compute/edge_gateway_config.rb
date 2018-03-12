require 'fog/core/model'

module Fog
  module Compute
    class VcloudDirector
      class EdgeGatewayConfig < Model
        attribute :gateway_backing_config
        attribute :gateway_interfaces
        attribute :edge_gateway_service_configuration
        attribute :ha_enabled
        attribute :use_default_route_for_dns_relay
      end      
    end
  end
end
