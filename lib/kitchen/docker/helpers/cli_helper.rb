#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen'
require 'kitchen/configurable'
require 'kitchen/logging'
require 'kitchen/shell_out'

module Kitchen
  module Docker
    module Helpers
      module CliHelper
        include Configurable
        include Logging
        include ShellOut

        def docker_command(cmd, options={})
          docker = config[:binary].dup
          docker << " -H #{config[:socket]}" if config[:socket]
          docker << ' --tls' if config[:tls]
          docker << ' --tlsverify' if config[:tls_verify]
          docker << " --tlscacert=#{config[:tls_cacert]}" if config[:tls_cacert]
          docker << " --tlscert=#{config[:tls_cert]}" if config[:tls_cert]
          docker << " --tlskey=#{config[:tls_key]}" if config[:tls_key]
          logger.debug("docker_command: #{docker} #{cmd} shell_opts: #{docker_shell_opts(options)}")
          run_command("#{docker} #{cmd}", docker_shell_opts(options))
        end

        def build_run_command(image_id, transport_port = nil)
          cmd = 'run -d'
          cmd << ' -i' if config[:interactive]
          cmd << ' -t' if config[:tty]
          cmd << build_env_variable_args(config[:env_variables]) if config[:env_variables]
          cmd << " -p #{transport_port}" unless transport_port.nil?
          Array(config[:forward]).each { |port| cmd << " -p #{port}" }
          Array(config[:dns]).each { |dns| cmd << " --dns #{dns}" }
          Array(config[:add_host]).each { |host, ip| cmd << " --add-host=#{host}:#{ip}" }
          Array(config[:volume]).each { |volume| cmd << " -v #{volume}" }
          Array(config[:volumes_from]).each { |container| cmd << " --volumes-from #{container}" }
          Array(config[:links]).each { |link| cmd << " --link #{link}" }
          Array(config[:devices]).each { |device| cmd << " --device #{device}" }
          cmd << " --name #{config[:instance_name]}" if config[:instance_name]
          cmd << ' -P' if config[:publish_all]
          cmd << " -h #{config[:hostname]}" if config[:hostname]
          cmd << " -m #{config[:memory]}" if config[:memory]
          cmd << " -c #{config[:cpu]}" if config[:cpu]
          cmd << " --gpus #{config[:gpus]}" if config[:gpus]
          cmd << " -e http_proxy=#{config[:http_proxy]}" if config[:http_proxy]
          cmd << " -e https_proxy=#{config[:https_proxy]}" if config[:https_proxy]
          cmd << ' --privileged' if config[:privileged]
          Array(config[:cap_add]).each { |cap| cmd << " --cap-add=#{cap}"} if config[:cap_add]
          Array(config[:cap_drop]).each { |cap| cmd << " --cap-drop=#{cap}"} if config[:cap_drop]
          Array(config[:security_opt]).each { |opt| cmd << " --security-opt=#{opt}"} if config[:security_opt]
          extra_run_options = config_to_options(config[:run_options])
          cmd << " #{extra_run_options}" unless extra_run_options.empty?
          cmd << " #{image_id} #{config[:run_command]}"
          logger.debug("build_run_command: #{cmd}")
          cmd
        end

        def build_exec_command(state, command)
          cmd = 'exec'
          cmd << ' -d' if config[:detach]
          cmd << build_env_variable_args(config[:env_variables]) if config[:env_variables]
          cmd << ' --privileged' if config[:privileged]
          cmd << ' -t' if config[:tty]
          cmd << ' -i' if config[:interactive]
          cmd << " -u #{config[:username]}" if config[:username]
          cmd << " -w #{config[:working_dir]}" if config[:working_dir]
          cmd << " #{state[:container_id]}"
          cmd << " #{command}"
          logger.debug("build_exec_command: #{cmd}")
          cmd
        end

        def build_copy_command(local_file, remote_file, opts = {})
          cmd = 'cp'
          cmd << ' -a' if opts[:archive]
          cmd << " #{local_file} #{remote_file}"
          cmd
        end

        def build_powershell_command(args)
          cmd = 'powershell -ExecutionPolicy Bypass -NoLogo '
          cmd << args
          logger.debug("build_powershell_command: #{cmd}")
          cmd
        end

        def build_env_variable_args(vars)
          raise ActionFailed, 'Environment variables are not of a Hash type' unless vars.is_a?(Hash)

          args = ''
          vars.each do |k, v|
            args << " -e #{k.to_s.strip}=\"#{v.to_s.strip}\""
          end

          args
        end

        def dev_null
          case RbConfig::CONFIG['host_os']
          when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
            'NUL'
          else
            '/dev/null'
          end
        end

        def docker_shell_opts(options = {})
          options[:live_stream] = nil if options[:suppress_output]
          options.delete(:suppress_output)

          options
        end

        # Convert the config input for `:build_options` or `:run_options` in to a
        # command line string for use with Docker.
        #
        # @since 2.5.0
        # @param config [nil, String, Array, Hash] Config data to convert.
        # @return [String]
        def config_to_options(config)
          case config
          when nil
            ''
          when String
            config
          when Array
            config.map { |c| config_to_options(c) }.join(' ')
          when Hash
            config.map { |k, v| Array(v).map { |c| "--#{k}=#{Shellwords.escape(c)}" }.join(' ') }.join(' ')
          end
        end
      end
    end
  end
end
