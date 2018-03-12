module Fog
  module Compute
    class VcloudDirector
      class Real
        
        # Updates VM configuration.
        #
        # This operation is asynchronous and returns a task that you can
        # monitor to track the progress of the request.
        #
        # @param [String] id Object identifier of the VM.
        # @param [Hash] options
        #
        # @option options [String]  :name                                 Change the VM's name [required].
        # @option options [String]  :description                          VM description
        # @option options [Hash]    :hardware                             Hardware Section
        # @option options [Integer]   :cpu                                  Number of CPUs
        # @option options [Integer]   :memory                               Memory in MB
        # @option options [Hash]    :network                              Network Section
        # @option options [String]    :network_name                         Network name
        # @option options [Boolean]   :needs_customization                  If network needs customization
        # @option options [Integer]   :primary_network_connection_index     Number of primary network connection
        # @option options [Integer]   :network_connection_index             Number of network connection
        # @option options [Boolean]   :is_connected                         If network is connected
        # @option options [String]    :mac_address                          Mac address
        # @option options [String]    :ip_address_allocation_mode           Ip Address allocation mode
        # @option options [Hash]    :guest_customization                  Guest Customization Section
        # @option options [Hash]    :operating_system                     Operating System Section
        #
        # @return [Excon::Response]
        #   * body<~Hash>:
        #     * :Tasks<~Hash>:
        #       * :Task<~Hash>:
        #
        # @see http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.api.reference.doc_51/doc/operations/POST-ReconfigureVm.html
        # @since vCloud API version 5.1
        def post_reconfigure_vm(id, options={})
          
          body = Nokogiri::XML::Builder.new do |xml|
            attrs = {
              :xmlns => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
              'xmlns:rasd' => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
              'xmlns:vcloud' => 'http://www.vmware.com/vcloud/v1.5',
              :name => options[:name]
            }
            xml.Vm(attrs) do
              xml.Description options[:description] if options[:description]
              virtual_hardware_section(xml, options)
              operating_system_section(xml, options)
              network_connection_section(xml, options)
              guest_customization_section(xml, options)
            end
          end.to_xml
          
          request(
            :body    => body,
            :expects => 202,
            :headers => {'Content-Type' => 'application/vnd.vmware.vcloud.vm+xml'},
            :method  => 'POST',
            :parser  => Fog::ToHashDocument.new,
            :path    => "vApp/#{id}/action/reconfigureVm"
          )
        end
        
        private
        
        def virtual_hardware_section(xml, options)
          return unless options[:cpu] or options[:memory]
          xml['ovf'].VirtualHardwareSection do
            xml['ovf'].Info 'Virtual Hardware Requirements'
            cpu_section(xml, options[:cpu]) if options[:cpu]
            memory_section(xml, options[:memory]) if options[:memory]
            disk_section(xml, options[:capacity]) if options[:capacity]
          end
        end

        def cpu_section(xml, cpu)
          xml['ovf'].Item do
            xml['rasd'].AllocationUnits 'hertz * 10 ^ 6'
            xml['rasd'].InstanceID 5
            xml['rasd'].ResourceType 3
            xml['rasd'].VirtualQuantity cpu.to_i
          end
        end
        
        def memory_section(xml, memory)
          xml['ovf'].Item do
            xml['rasd'].AllocationUnits 'byte * 2^20'
            xml['rasd'].InstanceID 6
            xml['rasd'].ResourceType 4
            xml['rasd'].VirtualQuantity memory.to_i
          end
        end

        def disk_section(xml, capacity)
          xml['ovf'].Item do
            xml['rasd'].Address 0
            xml['rasd'].Description 'SCSI Controller'
            xml['rasd'].ElementName 'SCSI Controller'
            xml['rasd'].InstanceID 2
            xml['rasd'].ResourceSubType 'lsilogicsas'
            xml['rasd'].ResourceType 6
          end
          xml['ovf'].Item do
            xml['rasd'].AddressOnParent 0
            xml['rasd'].Description 'Hard disk'
            xml['rasd'].ElementName 'Hard disk 1'
            xml['rasd'].HostResource(
              'vcloud:busSubType' => 'lsilogicsas',
              'vcloud:busType' => '6',
              'vcloud:capacity' => capacity.to_s
            )
            xml['rasd'].InstanceID 2000
            xml['rasd'].Parent 2
            xml['rasd'].ResourceType 17
          end
          xml['ovf'].Item do
            xml['rasd'].Address 0
            xml['rasd'].Description 'IDE Controller'
            xml['rasd'].ElementName 'IDE Controller'
            xml['rasd'].InstanceID 3
            xml['rasd'].ResourceType 5
          end
        end

        def operating_system_section(xml, options)
          if os = options[:operating_system]
            xml.OperatingSystemSection("ovf:id" => os[:id], :href => os[:href], :type => "application/vnd.vmware.vcloud.operatingSystemSection+xml", "wms:osType" => os[:osType] ) do
              xml['ovf'].Info 'Specifies the operating system installed'
              xml['ovf'].Description os[:description]
            end
          end
        end

        def network_connection_section(xml, options)
          if network = options[:network]
            xml.NetworkConnectionSection do
              xml['ovf'].Info 'Specifies the available VM network connections'
              xml.PrimaryNetworkConnectionIndex (network[:primary_network_connection_index] || 0)
              xml.NetworkConnection(needsCustomization: (network[:needs_customization] || false), network: network[:network_name]) do
                xml.NetworkConnectionIndex (network[:network_connection_index] || 0)
                xml.IpAddress (network[:ip_address] || nil)
                xml.ExternalIpAddress (network[:external_ip_address] || nil)
                xml.IsConnected (network[:is_connected] || false)
                xml.MACAddress (network[:mac_address] || nil)
                xml.IpAddressAllocationMode (network[:ip_address_allocation_mode] || "NONE")
              end
            end
          end
        end

        def guest_customization_section(xml, options)
          if customization = options[:guest_customization]
            xml.GuestCustomizationSection(:xmlns => "http://www.vmware.com/vcloud/v1.5", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1") {
              xml['ovf'].Info 'Specifies Guest OS Customization Settings'
              xml.Enabled (customization[:enabled] || false)
              xml.ChangeSid customization[:changed_sid] if (customization.key? :changed_sid)
              xml.VirtualMachineId customization[:virtual_machine_id] if (customization.key? :virtual_machine_id)
              xml.JoinDomainEnabled customization[:join_domain_enabled] if (customization.key? :join_domain_enabled)
              xml.UseOrgSettings customization[:use_org_settings] if (customization.key? :use_org_settings)
              xml.DomainName customization[:domain_name] if (customization.key? :domain_name)
              xml.DomainUserName customization[:domain_user_name] if (customization.key? :domain_user_name)
              xml.DomainUserPassword customization[:domain_user_password] if (customization.key? :domain_user_password)
              xml.MachineObjectOU customization[:machine_object_ou] if (customization.key? :machine_object_ou)
              xml.AdminPasswordEnabled customization[:admin_password_enabled] if (customization.key? :admin_password_enabled)
              xml.AdminPasswordAuto customization[:admin_password_auto] if (customization.key? :admin_password_auto)
              xml.AdminPassword customization[:admin_password] if (customization.key? :admin_password)
              xml.AdminAutoLogonEnabled customization[:admin_auto_logon_enabled] if (customization.key? :admin_auto_logon_enabled)
              xml.AdminAutoLogonCount customization[:admin_auto_logon_count] if (customization.key? :admin_auto_logon_count)
              xml.ResetPasswordRequired customization[:reset_password_required] if (customization.key? :reset_password_required)
              xml.CustomizationScript customization[:customization_script] if (customization.key? :customization_script)
              xml.ComputerName customization[:computer_name]
            }
          end
        end
      end
      
      class Mock
        def post_reconfigure_vm(id, options={})
          unless vm = data[:vms][id]
            raise Fog::Compute::VcloudDirector::Forbidden.new(
              'This operation is denied.'
            )
          end
          
          owner = {
            :href => make_href("vApp/#{id}"),
            :type => 'application/vnd.vmware.vcloud.vApp+xml'
          }
          task_id = enqueue_task(
            "Updating Virtual Machine #{data[:vms][id][:name]}(#{id})", 'vappUpdateVm', owner,
            :on_success => lambda do
              data[:vms][id][:name] = options[:name]
              data[:vms][id][:description] = options[:description] if options[:description]
              data[:vms][id][:cpu_count] = options[:cpu] if options[:cpu]
              data[:vms][id][:memory_in_mb] = options[:memory] if options[:memory]
            end
          )
          body = {
            :xmlns => xmlns,
            :xmlns_xsi => xmlns_xsi,
            :xsi_schemaLocation => xsi_schema_location,
          }.merge(task_body(task_id))

          Excon::Response.new(
            :status => 202,
            :headers => {'Content-Type' => "#{body[:type]};version=#{api_version}"},
            :body => body
          )
        end
      end
    end
  end
end
