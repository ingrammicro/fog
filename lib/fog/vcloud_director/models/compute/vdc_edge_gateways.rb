require 'fog/core/collection'
require 'fog/vcloud_director/models/compute/vdc_edge_gateway'

module Fog
  module Compute
    class VcloudDirector
      class VdcEdgeGateways < Collection
        model Fog::Compute::VcloudDirector::VdcEdgeGateway

        attribute :vdc

        private

        def get_by_id(item_id)
          data = service.get_org_vdc_gateways(vdc.id).body
          return nil if data[:edge_gateways].empty?
          edge = data[:EdgeGatewayRecord].select{|edge| edge[:href].split('/').last == item_id}
          service.add_id_from_href!(edge)
          edge
        end

        def item_list
          data = service.get_org_vdc_gateways(vdc.id).body
          return [] if data[:edge_gateways].empty?
          data = data[:edge_gateways].each {|edge_gateway| service.add_id_from_href!(edge_gateway)}
          data
        end
      end
    end
  end
end
