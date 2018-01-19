module Fog
    module Compute
      class VcloudDirector
        class Real
          # List Public/External IPs on specific Edge Gateway.
          # Rights required for the operation: Gateway: View External IP Addresses.
          #
          # @param [String] gateway_id Object identifier of the catalog.
          # @return [Excon::Response]
          #   * body<~Hash>:
          #
          # @see https://code.vmware.com/web/dp/explorer-apis?id=72#/doc/doc/operations/GET-VdcTemplate-AdminView.html
          # @since vCloud API version 5.7
          def get_edge_gateway_external_ip_usage(gateway_id)
            request(
              :expects    => 200,
              :idempotent => true,
              :method     => 'GET',
              :parser     => Fog::ToHashDocument.new,
              :path       => "/admin/edgeGateway/#{gateway_id}/externalIpUsage"
            )
          end
        end
      end
    end
  end
  