class ChefIgnition
  class Resource
    class Config < Chef::Resource
      include SystemdHelper

      resource_name :qemu_ignition_config

      default_action :create
      allowed_actions :create, :delete

      property :networkd, Array, default: []
      property :systemd, Array, default: []
      property :files, Array, default: []
      property :base, Hash, default: {}
      property :version, String, default: '2.1.0'

      property :exists, [TrueClass, FalseClass]
      property :path, String
      property :config, String, default: lazy { to_conf.to_json }

      private

      def to_conf
        base.to_hash.merge({
          "ignition" => {
            "version" => version,
            "config" => {}
          },
          "storage" => {
            "files" => files.map { |f|
              {
                "filesystem" => 'root',
                "path" => f['path'],
                "mode" => f['mode'],
                "contents" => {
                  "source" => f['contents']
                }
              }
            }
          },
          "networkd" => {
            "units" => networkd.map { |e|
              {
                "name" => "#{e['name']}.network",
                "contents" => SystemdHelper::ConfigGenerator.generate_from_hash(e['contents'])
              }
            }
          },
          "systemd" => {
            "units" => systemd.map { |e|

              u = {
                "enabled" => true,
                "name" => "#{e['name']}.service",
              }

              if e['contents'].is_a?(Hash)
                u["contents"] = SystemdHelper::ConfigGenerator.generate_from_hash(e['contents'])
              end

              if e['dropins'].is_a?(Array)
                u["dropins"] = e['dropins'].map { |d|
                  {
                    "name" => "#{d['name']}.conf",
                    "contents" => SystemdHelper::ConfigGenerator.generate_from_hash(d['contents'])
                  }
                }
              end

              u
            }
          }
        })
      end
    end
  end
end
