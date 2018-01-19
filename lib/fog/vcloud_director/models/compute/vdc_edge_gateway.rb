require 'fog/core/model'

module Fog
  module Compute
    class VcloudDirector
      class VdcEdgeGateway < Model
        identity  :id

        attribute :name
        attribute :type
        attribute :href
        attribute :gateway_status
        attribute :ha_status
        attribute :is_busy
        attribute :is_syslog_server_setting_in_sync
        attribute :number_of_ext_networks
        attribute :number_of_org_networks
        attribute :vdc_id

        def configuration
          requires :id
          data = service.get_edge_gateway(id).body
          @gateway_interfaces = []
          data[:gateway_interfaces].each{|interface| @gateway_interfaces << (Fog::Compute::VcloudDirector::VdcEdgeGatewayInterface.new interface) }         
          data[:gateway_interfaces] = @gateway_interfaces
          item = Fog::Compute::VcloudDirector::VdcEdgeGatewayConfig.new data
        end
      end
      
    end
  end
end
