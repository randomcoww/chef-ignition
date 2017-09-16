class ChefIgnition
  class Provider
    class Config < Chef::Provider
      provides :ignition_config, os: "linux"

      def load_current_resource
        @current_resource = ChefIgnition::Resource::Config.new(new_resource.name)

        current_resource.exists(::File.exist?(new_resource.path))

        if current_resource.exists
          current_resource.config(::File.read(new_resource.path))
        else
          current_resource.config('')
        end

        current_resource
      end

      def action_create
        if !current_resource.exists ||
          current_resource.config != new_resource.config

          converge_by("Create ignition config: #{new_resource}") do
            base_directory(:create_if_missing)
            ignition_config.run_action(:create)
          end
        end
      end

      def action_delete
        converge_by("Delete ignition config: #{new_resource}") do
          ignition_config.run_action(:delete)
        end if current_resource.exists
      end

      private

      def base_directory(action)
        Chef::Resource::Directory.new(::File.dirname(new_resource.path), run_context).tap do |r|
          r.recursive true
        end.run_action(action)
      end

      def ignition_config
        @user_data ||= Chef::Resource::File.new(new_resource.path, run_context).tap do |r|
          r.content new_resource.config
        end
      end
    end
  end
end
