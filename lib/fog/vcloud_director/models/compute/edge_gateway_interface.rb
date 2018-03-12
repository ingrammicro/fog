require 'fog/core/model'

module Fog
  module Compute
    class VcloudDirector
      class EdgeGatewayInterface < Model
        attribute :name
        attribute :display_name
        attribute :network
        attribute :interface_type
        attribute :subnet_participation
        attribute :in_rate_limit
        attribute :out_rate_limit
        attribute :use_for_default_route
      end      
    end
  end
end
