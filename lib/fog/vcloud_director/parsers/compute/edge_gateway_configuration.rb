module Fog
    module Parsers
        module Compute
            module VcloudDirector
                class EdgeGatewayConfiguration < VcloudDirectorParser
                    def reset
                        @gateway_interfaces = []
                        @gateway_interface = {}
                        @subnet_participation = {}
                        @edge_gateway_service_configuration = {}
                        @ip_ranges = []
                        @ip_range = {}
                        @firewall = {}                  
                        @response = {}                    
                    end
        
                    def start_element(name, attributes)
                        super
                        case name
                        when 'IpRange'
                            @ip_range = {}
                        when 'GatewayInterface'
                            @gateway_interface = {}
                        when 'SubnetParticipation'
                            @subnet_participation = {}
                        when 'FirewallService'
                            @firewall = {}
                        when 'EdgeGatewayServiceConfiguration'
                            @edge_gateway_service_configuration = {}
                        end
                    end
        
                    def end_element(name)
                        case name
                        when 'GatewayBackingConfig'
                            @response[:gateway_backing_config] = value             
                        #subnet_participation                                                                    
                        when 'Gateway'
                            @subnet_participation[:gateway] = value
                        when 'Netmask'
                            @subnet_participation[:netmask] = value
                        when 'IpAddress'
                            @subnet_participation[:ip_address] = value
                        when 'ApplyRateLimit'
                            @subnet_participation[:apply_rate_limit] = value
                        when 'IpRanges'
                            @subnet_participation[:ip_ranges] = @ip_ranges
                        when 'IpRange'
                            @ip_ranges << @ip_range
                        when 'StartAddress'
                            @ip_range[:start_address] = value
                        when 'EndAddress'
                            @ip_range[:end_address] = value
                        #gateway_interface
                        when 'Name'
                            @gateway_interface[:name] = value
                        when 'DisplayName'
                            @gateway_interface[:display_name] = value
                        when 'Network'
                            @gateway_interface[:network] = value
                        when 'InterfaceType'
                            @gateway_interface[:interface_type] = value
                        when 'SubnetParticipation'
                            @gateway_interface[:subnet_participation] = @subnet_participation   
                        when 'ApplyRateLimit'
                            @gateway_interface[:apply_rate_limit] = value
                        when 'InRateLimit'
                            @gateway_interface[:in_rate_limit] = value
                        when 'OutRateLimit'
                            @gateway_interface[:out_rate_limit] = value
                        when 'UseForDefaultRoute'
                            @gateway_interface[:use_for_default_route] = value
                        when 'GatewayInterface'        
                            @gateway_interfaces << @gateway_interface
                        when 'GatewayInterfaces'
                            @response[:gateway_interfaces] = @gateway_interfaces
                        #firewall_service
                        when 'IsEnabled'
                            @firewall[:is_enabled] = (value == "true")
                        when 'DefaultAction'
                            @firewall[:default_action] = value
                        when 'LogDefaultAction'
                            @firewall[:log_default_action] = (value == "true")
                        when 'FirewallService'
                            @edge_gateway_service_configuration[:firewall] = @firewall
                        when 'EdgeGatewayServiceConfiguration'
                            @response[:edge_gateway_service_configuration] = @edge_gateway_service_configuration
                        when 'HaEnabled'
                            @response[:ha_enabled] = (value == "true")
                        when 'UseDefaultRouteForDnsRelay'
                            @response[:use_default_route_for_dns_relay] = value
                        end
                    end
                end
            end
        end
    end
end
  