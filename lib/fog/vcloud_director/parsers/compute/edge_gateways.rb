module Fog
    module Parsers
        module Compute
            module VcloudDirector
                class EdgeGateways < VcloudDirectorParser
                    def reset
                    @edge_gateway = {}
                    @response = { :edge_gateways => [] }
                    @edge_gateway_record = nil
                    @type = nil
                    end
        
                    def start_element(name, attributes)
                        super
                        case name
                        when 'QueryResultRecords'
                            @type = extract_attributes(attributes)[:type]
                        when 'EdgeGatewayRecord'
                            @edge_gateway_record = extract_attributes(attributes)
                        end
                    end
        
                    def end_element(name)
                        case name
                        when 'EdgeGatewayRecord'
                            if @edge_gateway_record
                                @edge_gateway[:type] = @type
                                @edge_gateway[:name] = @edge_gateway_record[:name]
                                @edge_gateway[:href] = @edge_gateway_record[:href]
                                @edge_gateway[:is_syslog_server_setting_in_sync] = @edge_gateway_record[:isSyslogServerSettingInSync]
                                @edge_gateway[:gateway_status] = @edge_gateway_record[:gatewayStatus]
                                @edge_gateway[:ha_status] = @edge_gateway_record[:haStatus]
                                @edge_gateway[:is_busy] = @edge_gateway_record[:isBusy]
                                @edge_gateway[:number_of_ext_networks] = @edge_gateway_record[:numberOfExtNetworks].to_i
                                @edge_gateway[:number_of_org_networks] = @edge_gateway_record[:numberOfOrgNetworks].to_i
                                @edge_gateway[:vdc_id] = @edge_gateway_record[:vdc].split('/').last
                            end
                            @response[:edge_gateways] << @edge_gateway
                            @edge_gateway_record = nil
                            @edge_gateway = {}
                        end
                    end
                end
            end
        end
    end
  end
  