class ChefIgnition
  class Resource
    class Config < Chef::Resource
      include SystemdHelper

      resource_name :ignition_config

      default_action :create
      allowed_actions :create, :delete

      property :networkd, Array, default: []
      property :systemd, Array, default: []
      property :files, Array, default: []
      property :directories, Array, default: []
      property :base, Hash, default: {}
      property :version, String, default: '2.1.0'

      property :exists, [TrueClass, FalseClass]
      property :path, String
      property :config, String, default: lazy { JSON.pretty_generate(to_conf) }

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
            },
            "directories" => directories.map { |d|
              {
                "filesystem" => 'root',
                "path" => d['path'],
                "mode" => d['mode']
              }
            }
          },
          "networkd" => {
            "units" => networkd.map { |e|
              {
                "name" => e['name'],
                "contents" => SystemdHelper::ConfigGenerator.generate_from_hash(e['contents'])
              }
            }
          },
          "systemd" => {
            "units" => systemd.map { |e|

              u = {
                "enabled" => true,
                "name" => e['name'],
              }

              if e['contents'].is_a?(Hash)
                u["contents"] = SystemdHelper::ConfigGenerator.generate_from_hash(e['contents'])
              end

              if e['dropins'].is_a?(Array)
                u["dropins"] = e['dropins'].map { |d|
                  {
                    "name" => d['name'],
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
