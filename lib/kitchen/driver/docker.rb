#
# Copyright (C) 2014, Sean Porter
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

require "kitchen"
require "json" unless defined?(JSON)
require "securerandom" unless defined?(SecureRandom)
require "net/ssh" unless defined?(Net::SSH)
require "time" unless defined?(Time)

require "kitchen/driver/base"

require_relative "../docker/container/linux"
require_relative "../docker/container/windows"
require_relative "../docker/docker_version"
require_relative "../docker/helpers/cli_helper"
require_relative "../docker/helpers/container_helper"

module Kitchen
  # Test Kitchen's driver plugins.
  module Driver
    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::Base
      include Kitchen::Docker::Helpers::CliHelper
      include Kitchen::Docker::Helpers::ContainerHelper
      include ShellOut

      # Reported by `kitchen diagnose`, which is what a bug report is asked to
      # include. The version is this gem's own: the transport used to report
      # Kitchen::VERSION, which is Test Kitchen's, so a diagnose said the
      # plugin was at whatever version Test Kitchen happened to be.
      kitchen_driver_api_version 2
      plugin_version Kitchen::Docker::DOCKER_VERSION

      default_config :binary,        "docker"
      default_config :build_options, nil
      default_config :build_tempdir, Dir.pwd
      default_config :cap_add,       nil
      default_config :cap_drop,      nil
      default_config :disable_upstart, true
      default_config :env_variables, nil
      default_config :isolation,     nil
      default_config :interactive,   false
      default_config :private_key,   File.join(Dir.pwd, ".kitchen", "docker_id_rsa")
      default_config :privileged,    false
      default_config :public_key,    File.join(Dir.pwd, ".kitchen", "docker_id_rsa.pub")
      default_config :publish_all,   false
      default_config :remove_images, false
      default_config :run_options,   nil
      default_config :security_opt,  nil
      default_config :sudo_command,  nil
      default_config :tls,           false
      default_config :tls_cacert,    nil
      default_config :tls_cert,      nil
      default_config :tls_key,       nil
      default_config :tls_verify,    false
      default_config :tty,           false
      default_config :use_cache,     true
      default_config :use_internal_docker_network, false
      default_config :use_sudo, false
      default_config :wait_for_transport, true

      default_config :build_context do |driver|
        !driver.remote_socket?
      end

      default_config :image, &:default_image

      default_config :instance_name do |driver|
        # Borrowed from kitchen-rackspace
        [
          driver.instance.name.gsub(/\W/, ""),
          (Etc.getlogin || "nologin").gsub(/\W/, ""),
          Socket.gethostname.gsub(/\W/, "")[0..20],
          Array.new(8) { rand(36).to_s(36) }.join,
        ].join("-").downcase
      end

      # The image `kitchen package` commits to. Derived from the instance name,
      # which is already lowercase and dash-separated, so it is a valid Docker
      # repository name as it stands.
      default_config :package_name do |driver|
        "#{driver.instance.name.downcase.gsub(/[^a-z0-9_.-]/, "-")}:latest"
      end

      default_config :platform, &:default_platform

      default_config :run_command do |driver|
        if driver.windows_os?
          # Launch arbitrary process to keep the Windows container alive
          # If running in interactive mode, launch powershell.exe instead
          if driver[:interactive]
            "powershell.exe"
          else
            "ping -t localhost"
          end
        else
          "/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no -o PasswordAuthentication=yes " \
          "-o UsePrivilegeSeparation=no -o PidFile=/tmp/sshd.pid"
        end
      end

      default_config :socket do |driver|
        socket = "unix:///var/run/docker.sock"
        socket = "npipe:////./pipe/docker_engine" if Gem.win_platform?
        ENV["DOCKER_HOST"] || socket
      end

      default_config :username do |driver|
        # Return nil to prevent username from being added to Docker
        # command line args for Windows if a username was not specified
        if driver.windows_os?
          nil
        else
          "kitchen"
        end
      end

      # Checks that the Docker CLI is installed and runnable.
      #
      # @return [void]
      # @raise [Kitchen::UserError] if the binary cannot be run
      def verify_dependencies
        run_command("#{config[:binary]} >> #{dev_null} 2>&1", quiet: true, use_sudo: config[:use_sudo])
      rescue
        raise UserError, "You must first install the Docker CLI tool https://www.docker.com/get-started"
      end

      # Builds the image and starts the container.
      #
      # @param state [Hash] mutable instance state
      # @return [void]
      def create(state)
        container.create(state)

        wait_for_transport(state)
      end

      # Removes the container, and its image when +remove_images+ is set.
      #
      # @param state [Hash] instance state naming the container
      # @return [void]
      def destroy(state)
        container.destroy(state)
      end

      # Commits the container to a Docker image.
      #
      # `kitchen package` asks a driver to turn a converged instance into
      # something reusable. For Docker that is an image: `docker commit` on the
      # running container, which is the artifact every other docker tool
      # already takes. Run `docker save` against the result for a tarball.
      #
      # @param state [Hash] instance state naming the container
      # @return [void]
      # @raise [Kitchen::ActionFailed] if the instance has not been created
      def package(state)
        unless state[:container_id]
          raise ActionFailed, "Cannot package #{instance.name}: it has not been created."
        end

        # Asked here rather than left to `docker commit`, which reports a
        # container that is gone as a bare "Error response from daemon: No such
        # container: <64 hex characters>" with nothing about the instance or
        # what to do next.
        unless container_exists?(state)
          raise ActionFailed, "Cannot package #{instance.name}: the state file names container " \
                              "#{state[:container_id]}, which the daemon does not have. " \
                              "Run `kitchen destroy` to clear it."
        end

        name = config[:package_name]
        info("[Docker] Committing container #{state[:container_id]} to #{name}")
        output = docker_command("commit #{shell_escape(state[:container_id])} #{shell_escape(name)}",
          suppress_output: !logger.debug?)
        image_id = output.lines.map(&:strip).find { |line| line.match?(/\Asha256:[[:xdigit:]]{64}\z/) }
        info("[Docker] Packaged #{instance.name} as #{name}#{" (#{image_id})" if image_id}")
      end

      # Checks the configuration and the daemon it points at.
      #
      # Run by `kitchen doctor`. A true return is how Test Kitchen decides to
      # exit non-zero, so every check runs and the results are OR-ed together
      # rather than returning at the first problem -- somebody running `doctor`
      # wants the whole list, not the first item on it.
      #
      # @param state [Hash] instance state
      # @return [Boolean] whether a problem was found
      def doctor(state)
        [
          doctor_daemon,
          doctor_files,
          doctor_container(state),
        ].any?
      end

      # Reports whether the container backing this instance is up.
      #
      # Read by `kitchen list --live`, which showed "unknown" for every
      # instance: {Kitchen::Driver::Base} cannot know, and this driver never
      # said. Docker can answer directly, and these are the same two questions
      # create and destroy already ask.
      #
      # @param state [Hash] instance state naming the container
      # @return [Hash] normalized status data
      def status(state)
        common = { source: "driver", checked_at: Time.now.utc.iso8601, resource_id: state[:container_id] }

        if !state[:container_id]
          common.merge(live: false, state: "not created",
            message: "No container is recorded in the state file")
        elsif !container_exists?(state)
          common.merge(live: false, state: "gone",
            message: "The state file names a container the daemon does not have")
        elsif container_running?(state)
          common.merge(live: true, state: "running")
        else
          common.merge(live: false, state: "stopped",
            message: "The container exists but is not running")
        end
      end

      # Waits for the transport to accept a connection, unless disabled.
      #
      # @param state [Hash] instance state describing how to connect
      # @return [void]
      def wait_for_transport(state)
        if config[:wait_for_transport]
          instance.transport.connection(state, &:wait_until_ready)
        end
      end

      # The Docker image implied by the platform name.
      #
      # +ubuntu-22.04+ becomes +ubuntu:22.04+. CentOS is special-cased, since its
      # images are tagged +centos7+ rather than +centos:7+.
      #
      # @return [String] an image reference
      def default_image
        platform, release = instance.platform.name.split("-")
        if platform == "centos" && release
          release = "centos" + release.split(".").first
        end
        release ? [platform, release].join(":") : platform
      end

      # @return [String] the platform family, e.g. +ubuntu+ from +ubuntu-22.04+
      def default_platform
        instance.platform.name.split("-").first
      end

      protected

      # @return [Boolean] whether the daemon could not be reached
      def doctor_daemon
        version = docker_command("version --format '{{.Server.Version}}'", suppress_output: true).strip
        info("Docker daemon at #{config[:socket]} is reachable, running #{version}.")
        false
      rescue => e
        error("Cannot reach the Docker daemon at #{config[:socket]}. #{e}")
        true
      end

      # Checks paths the configuration names.
      #
      # A missing TLS file or Dockerfile is worth catching here because docker
      # reports it far from the cause -- a missing client certificate surfaces
      # as a connection error rather than as a missing file.
      #
      # @return [Boolean] whether any named path is missing
      def doctor_files
        %i{tls_cacert tls_cert tls_key dockerfile}.map do |key|
          path = config[key]
          next false if path.nil? || ::File.exist?(::File.expand_path(path))

          error("#{key} is set to #{path}, which does not exist.")
          true
        end.any?
      end

      # @param state [Hash] instance state naming the container
      # @return [Boolean] whether state names a container that is gone
      def doctor_container(state)
        return false unless state[:container_id]
        return false if container_exists?(state)

        error("The state file names container #{state[:container_id]}, which the daemon does " \
              "not have. Run `kitchen destroy` to clear it.")
        true
      end

      # The container implementation for this platform.
      #
      # @return [Kitchen::Docker::Container] a Windows or Linux container
      def container
        @container ||= if windows_os?
                         Kitchen::Docker::Container::Windows.new(config)
                       else
                         Kitchen::Docker::Container::Linux.new(config)
                       end
        @container
      end
    end
  end
end
