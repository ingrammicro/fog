module Fog
  module Generators
    module Compute
      module VcloudDirector
        module ComposeCommon

          def initialize(configuration={})
            @configuration = configuration
          end

          private

          def vapp_attrs
            attrs = {
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
              'xmlns:rasd' => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
              'xmlns:vcloud' => 'http://www.vmware.com/vcloud/v1.5'
            }

            [:deploy, :powerOn, :name].each do |a|
              attrs[a] = @configuration[a] if @configuration.key?(a)
            end
            
            attrs
          end

          def has_source_items?
            (@configuration[:source_vms] && (@configuration[:source_vms].size > 0)) || 
            (@configuration[:source_templates] && (@configuration[:source_templates].size > 0))
          end

          def build_vapp_instantiation_params(xml)
            xml.Description @configuration[:Description] if @configuration[:Description]
            
            vapp = @configuration[:InstantiationParams]
            if vapp 
              xml.InstantiationParams {
                xml.DefaultStorageProfileSection {
                    xml.StorageProfile vapp[:DefaultStorageProfile]
                } if (vapp.key? :DefaultStorageProfile)
                xml.NetworkConfigSection {
                  network = vapp[:network_config]
                  xml['ovf'].Info
                  xml.NetworkConfig(:networkName => network[:network_name]) {
                    xml.Configuration {
                      xml.ParentNetwork(:href => @configuration[:network_uri])
                      xml.FenceMode network[:fence_mode]
                    }
                  }
                } if (vapp.key? :network_config)
              }
            end
          end
          
          def build_source_template(xml)
            xml.Source(:href => @configuration[:Source])
          end

          def build_source_items(xml)
            vms = @configuration[:source_vms]
            vms.each do |vm|
              xml.SourcedItem {
                xml.Source(:name =>vm[:name], :href => vm[:href])
                xml.VmGeneralParams {
                  xml.Name vm[:name]
                  xml.Description vm[:description] if vm[:description]
                  xml.NeedsCustomization vm[:needs_customization] if vm[:needs_customization]
                } if vm[:name]
                xml.InstantiationParams {
                  if vm[:network]
                    xml.NetworkConnectionSection(:href => "#{vm[:href]}/networkConnectionSection/", 
                      :type => "application/vnd.vmware.vcloud.networkConnectionSection+xml", 
                      'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1", 
                      'ovf:required' => "false") {
                      network = vm[:network]
                      xml['ovf'].Info
                      xml.PrimaryNetworkConnectionIndex 0                      
                      xml.NetworkConnection(:network => network[:network_name]) {
                        xml.NetworkConnectionIndex 0
                        xml.IpAddress network[:ip_address] if network[:ip_address]
                        xml.ExternalIpAddress network[:external_ip_address] if network[:external_ip_address]
                        xml.IsConnected (network[:is_connected] || false)
                        xml.MACAddress network[:mac_address] if network[:mac_address]
                        xml.IpAddressAllocationMode (network[:ip_address_allocation_mode] || "NONE")
                      }
                    }
                  end
                  if customization = vm[:guest_customization]
                    xml.GuestCustomizationSection(:xmlns => "http://www.vmware.com/vcloud/v1.5", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1") {
                      xml['ovf'].Info
                      xml.Enabled (customization[:enabled] || false)
                      xml.ChangeSid customization[:change_sid] if (customization.key? :change_sid)
                      xml.JoinDomainEnabled customization[:join_domain_enabled] if (customization.key? :join_domain_enabled)
                      xml.UseOrgSettings customization[:use_org_settings] if (customization.key? :use_org_settings)
                      xml.DomainName customization[:domain_name] if (customization.key? :domain_name)
                      xml.DomainUserName customization[:domain_user_name] if (customization.key? :domain_user_name)
                      xml.DomainUserPassword customization[:domain_user_password] if (customization.key? :domain_user_password)
                      xml.MachineObjectOU customization[:machine_object_ou] if (customization.key? :machine_object_ou)
                      xml.AdminPasswordEnabled customization[:admin_password_enabled] if (customization.key? :admin_password_enabled)
                      xml.AdminPasswordAuto customization[:admin_password_auto] if (customization.key? :admin_password_auto)
                      xml.AdminPassword customization[:admin_password] if (customization.key? :admin_password)
                      xml.ResetPasswordRequired customization[:reset_password_required] if (customization.key? :reset_password_required)
                      xml.CustomizationScript customization[:customization_script] if (customization.key? :customization_script)
                      xml.ComputerName customization[:computer_name] if (customization.key? :computer_name)
                    }
                  end
                  if virtual_hardware = vm[:virtual_hardware]
                    xml['ovf'].VirtualHardwareSection('xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1", 
                      'xmlns:rasd'=>"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData", 
                      'xmlns:vmw'=>"http://www.vmware.com/schema/ovf", 
                      'xmlns:vcloud'=>"http://www.vmware.com/vcloud/v1.5", 
                      'xmlns:vssd'=>"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData", 
                      'ovf:transport'=>"", 
                      'vcloud:href'=>"#{vm[:href]}/virtualHardwareSection/", 
                      'vcloud:type'=>"application/vnd.vmware.vcloud.virtualHardwareSection+xml") do
                      xml['ovf'].Info
                      xml['ovf'].Item do
                        xml['rasd'].AddressOnParent 0
                        xml['rasd'].Description 'Hard disk'
                        xml['rasd'].ElementName 'Hard disk 1'
                        xml['rasd'].HostResource(
                          'vcloud:busSubType' => virtual_hardware[:is_windows] ? 'lsilogicsas' : 'lsilogic',
                          'vcloud:busType' => '6',
                          'vcloud:capacity' => virtual_hardware[:capacity].to_s
                        )
                        xml['rasd'].InstanceID 2000
                        xml['rasd'].ResourceType 17
                      end
                      xml['ovf'].Item do
                        xml['rasd'].AllocationUnits 'hertz * 10 ^ 6'
                        xml['rasd'].InstanceID 5
                        xml['rasd'].ResourceType 3
                        xml['rasd'].VirtualQuantity virtual_hardware[:cpu].to_i
                      end   
                      xml['ovf'].Item do
                        xml['rasd'].AllocationUnits 'byte * 2^20'
                        xml['rasd'].InstanceID 6
                        xml['rasd'].ResourceType 4
                        xml['rasd'].VirtualQuantity virtual_hardware[:memory].to_i
                      end
                    end                               
                  end
                }
              }
            end if vms

            templates = @configuration[:source_templates]
            templates.each do |template|
              xml.SourcedItem { xml.Source(:href => template[:href]) }
            end if templates

            xml.AllEULAsAccepted (@configuration[:AllEULAsAccepted] || true)
          end

        end
      end
    end
  end
end
