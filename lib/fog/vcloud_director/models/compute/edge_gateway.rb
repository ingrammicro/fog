require 'fog/core/model'

module Fog
  module Compute
    class VcloudDirector
      class EdgeGateway < Model
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

        def external_ip_usage
          #This should be done using get_edge_gateway_external_ip_usage, when it works
          requires :id
          @connections = []
          data = service.get_edge_gateway(id).body
          gateway_interfaces = data[:gateway_interfaces]
          edge_gateway_service_configuration = data[:edge_gateway_service_configuration]
          gateway_interfaces.each do |interface|
            if interface[:subnet_participation].key?(:ip_ranges)
              interface[:subnet_participation][:ip_ranges].each do |ip_range|
                (ip_range[:start_address]..ip_range[:end_address]).to_a.each do |ip|
                  @connections << Fog::Compute::VcloudDirector::EdgeGatewayExternalConnection.new(ip_address: ip, is_used_in_rule: false, external_network_name: interface[:name], external_network_href: interface[:href])
                end
              end
            end
          end
          nat_service = edge_gateway_service_configuration[:nat_service]
          if nat_service && nat_service[:is_enabled] == "true"
            if nat_rules = nat_service[:nat_rule]
              nat_rules.each do |rule|
                connection = @connections.select{|c| c.ip_address == rule[:gateway_nat_rule][:original_ip]}.first
                connection.is_used_in_rule = true if connection
                connection = @connections.select{|c| c.ip_address == rule[:gateway_nat_rule][:translated_ip]}.first
                connection.is_used_in_rule = true if connection
              end
            end
          end
          @connections.sort_by{ |connection| connection.ip_address }
        end

        def configuration
          requires :id
          data = service.get_edge_gateway(id).body
          @gateway_interfaces = []
          data[:gateway_interfaces].each{|interface| @gateway_interfaces << (Fog::Compute::VcloudDirector::EdgeGatewayInterface.new interface) }         
          data[:gateway_interfaces] = @gateway_interfaces
          item = Fog::Compute::VcloudDirector::EdgeGatewayConfig.new data
        end

        # Reconfigure an edge gateway using any of the configuration documented in
        # post_configure_edge_gateway_services
        def reconfigure(configuration)
          response = service.post_configure_edge_gateway_services(id, configuration)
          service.process_task(response.body)
        end

        def add_nat_rules(nat_rules)
          requires :id
          @nat_rules = []
          data = service.get_edge_gateway(id).body
          edge_gateway_service_configuration = data[:edge_gateway_service_configuration]
          nat_service = edge_gateway_service_configuration[:nat_service]
          nat_service[:nat_rule].each do |rule|
            @nat_rules << {
              RuleType: rule[:rule_type], 
              IsEnabled: rule[:is_enabled], 
              Id: rule[:id],
              GatewayNatRule: 
              {
                Interface: 
                {
                  name: rule[:gateway_nat_rule][:interface_name], 
                  href: rule[:gateway_nat_rule][:interface_href] 
                }, 
                OriginalIp: rule[:gateway_nat_rule][:original_ip], 
                OriginalPort: rule[:gateway_nat_rule][:original_port],
                TranslatedIp: rule[:gateway_nat_rule][:translated_ip],
                TranslatedPort: rule[:gateway_nat_rule][:translated_port],
                Protocol: rule[:gateway_nat_rule][:protocol]                
              }
            }
          end
          nat_rules.each do |nat_rule|
            @nat_rules << {
              RuleType: nat_rule[:rule_type], 
              IsEnabled: true, 
              GatewayNatRule: 
              {
                Interface: 
                {
                  name: nat_rule[:interface_name], 
                  href: nat_rule[:interface_href] 
                }, 
                OriginalIp: nat_rule[:original_ip], 
                OriginalPort: nat_rule[:original_port].nil? ? 'ANY' : nat_rule[:original_port],
                TranslatedIp: nat_rule[:translated_ip],
                TranslatedPort: nat_rule[:translated_port].nil? ? 'ANY' : nat_rule[:translated_port],
                Protocol: nat_rule[:protocol].nil? ? 'ANY' : nat_rule[:protocol]
              }
            }
          end
          configuration = { NatService: { IsEnabled: nat_service[:is_enabled], NatRule: @nat_rules.uniq } }          
          response = service.post_configure_edge_gateway_services(id, configuration)
          service.process_task(response.body)
        end

        def remove_nat_rules(nat_rule_ip)
          requires :id
          @nat_rules = []
          data = service.get_edge_gateway(id).body
          edge_gateway_service_configuration = data[:edge_gateway_service_configuration]
          nat_service = edge_gateway_service_configuration[:nat_service]
          nat_service[:nat_rule].each do |rule|
            @nat_rules << {
              RuleType: rule[:rule_type], 
              IsEnabled: rule[:is_enabled], 
              Id: rule[:id],
              GatewayNatRule: 
              {
                Interface: 
                {
                  name: rule[:gateway_nat_rule][:interface_name], 
                  href: rule[:gateway_nat_rule][:interface_href] 
                }, 
                OriginalIp: rule[:gateway_nat_rule][:original_ip], 
                OriginalPort: rule[:gateway_nat_rule][:original_port],
                TranslatedIp: rule[:gateway_nat_rule][:translated_ip],
                TranslatedPort: rule[:gateway_nat_rule][:translated_port],
                Protocol: rule[:gateway_nat_rule][:protocol]                  
              }
            } if rule[:gateway_nat_rule][:translated_ip] != nat_rule_ip && rule[:gateway_nat_rule][:original_ip] != nat_rule_ip
          end 
          configuration = { NatService: { IsEnabled: nat_service[:is_enabled], NatRule: @nat_rules.uniq } }          
          response = service.post_configure_edge_gateway_services(id, configuration)
          service.process_task(response.body)
        end

      end      
    end
  end
end
