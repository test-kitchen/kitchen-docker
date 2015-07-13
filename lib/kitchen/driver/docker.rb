# -*- encoding: utf-8 -*-
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

require 'kitchen'
require 'json'
require 'uri'
require File.join(File.dirname(__FILE__), 'docker', 'erb')

module Kitchen

  module Driver

    # Docker driver for Kitchen.
    #
    # @author Sean Porter <portertech@gmail.com>
    class Docker < Kitchen::Driver::SSHBase

      default_config :binary,        'docker'
      default_config :socket,        ENV['DOCKER_HOST'] || 'unix:///var/run/docker.sock'
      default_config :privileged,    false
      default_config :cap_add,       nil
      default_config :cap_drop,      nil
      default_config :security_opt,  nil
      default_config :use_cache,     true
      default_config :remove_images, false
      default_config :run_command,   '/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no -o PasswordAuthentication=yes ' +
                                     '-o UsePrivilegeSeparation=no -o PidFile=/tmp/sshd.pid'
      default_config :username,      'kitchen'
      default_config :password,      'kitchen'
      default_config :tls,           false
      default_config :tls_verify,    false
      default_config :tls_cacert,    nil
      default_config :tls_cert,      nil
      default_config :tls_key,       nil
      default_config :publish_all,   false
      default_config :wait_for_sshd, true

      default_config :use_sudo do |driver|
        !driver.remote_socket?
      end

      default_config :image do |driver|
        driver.default_image
      end

      default_config :platform do |driver|
        driver.default_platform
      end

      default_config :disable_upstart, true

      def verify_dependencies
        run_command("#{config[:binary]} >> #{dev_null} 2>&1", :quiet => true)
        rescue
          raise UserError,
          'You must first install the Docker CLI tool http://www.docker.io/gettingstarted/'
      end

      def dev_null
        case RbConfig::CONFIG["host_os"]
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          "NUL"
        else
          "/dev/null"
        end
      end

      def default_image
        platform, release = instance.platform.name.split('-')
        if platform == 'centos' && release
          release = 'centos' + release.split('.').first
        end
        release ? [platform, release].join(':') : platform
      end

      def default_platform
        instance.platform.name.split('-').first
      end

      def create(state)
        state[:ssh_key] = generate_private_key
        state[:image_id] = build_image(state) unless state[:image_id]
        state[:container_id] = run_container(state) unless state[:container_id]
        state[:hostname] = remote_socket? ? socket_uri.host : 'localhost'
        state[:port] = container_ssh_port(state)
        wait_for_sshd(state[:hostname], nil, :port => state[:port]) if config[:wait_for_sshd]
      end

      def destroy(state)
        rm_container(state) if container_exists?(state)
        if config[:remove_images] && state[:image_id]
          rm_image(state)
        end
      end

      def remote_socket?
        config[:socket] ? socket_uri.scheme == 'tcp' : false
      end

      protected

      def socket_uri
        URI.parse(config[:socket])
      end

      def docker_command(cmd, options={})
        docker = config[:binary].dup
        docker << " -H #{config[:socket]}" if config[:socket]
        docker << " --tls" if config[:tls]
        docker << " --tlsverify" if config[:tls_verify]
        docker << " --tlscacert=#{config[:tls_cacert]}" if config[:tls_cacert]
        docker << " --tlscert=#{config[:tls_cert]}" if config[:tls_cert]
        docker << " --tlskey=#{config[:tls_key]}" if config[:tls_key]
        run_command("#{docker} #{cmd}", options.merge(:quiet => !logger.debug?))
      end

      # Return string to be placed in the authorized_keys file in the container
      def public_key
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMhWlMWZXC+y/3LOZYpfH0IpjT+BHZAVc'   +
        'Cy2K8YDc29GERbF//FMkt8J+3g4eLsv+mRhqnBDVhrL7RdxI2ufaZtACHwGf43qqqe0YWqm0'  +
        'PpqhEQDzBufNGsrI2tSFbzUgrJWU1xUjGz48jAwzPVzIGyDPSEAYyPHOSTzLo7sl2ARAlg25'  +
        'eKmQzjtJ0R4+gvT487n6Ow8jHMS2O/AxO+w4KsNVYTo/J6S83Nnt//RuAYSwEPbsJprLjmirn' +
        'HfPtoOJE7NN7O8AaUCscYIHmWz9i7myQRLbUQYtoBnUWCRO1lFfG9n7mU0jmZkDe1cQzIveab' +
        'EVJLChr7558j3WOkMBR kitchen_docker_key'
      end

      # Private key to be generated in File.join(config[:kitchen_root], '.kitchen')
      def private_key
        pk = <<-pk
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAzIVpTFmVwvsv9yzmWKXx9CKY0/gR2QFXAstivGA3NvRhEWxf
/xTJLfCft4OHi7L/pkYapwQ1Yay+0XcSNrn2mbQAh8Bn+N6qqntGFqptD6aoREA8
wbnzRrKyNrUhW81IKyVlNcVIxs+PIwMMz1cyBsgz0hAGMjxzkk8y6O7JdgEQJYNu
XipkM47SdEePoL0+PO5+jsPIxzEtjvwMTvsOCrDVWE6PyekvNzZ7f/0bgGEsBD27
Caay45oq5x3z7aDiROzTezvAGlArHGCB5ls/Yu5skES21EGLaAZ1FgkTtZRXxvZ+
5lNI5mZA3tXEMyL3mmxFSSwoa++efI91jpDAUQIDAQABAoIBAE9+V3Q+qdA0k+st
/4ZbUdUDkYVqOX2wYKKMbR8tAqkQiZ4dEp7x9FQv39STgh7Rfz6gpwFdyGXjn/OI
pYKx+2C4rzAUoBUCbzF+YrqymVto+qQ0l6jw3tcO4+gRtRqair+CdHlW6jekO01v
hQ4eJSqvrDysz8u85Wrr76zMC3Aavcs+nau0F0JsTpieAGxv1+AcZOydWORaRZWf
ZFa2i2LRXibO0Dy4mpBm4F6ejHxpZPCv99wFF69VGdG5ojSSGW8L75r1LkaIbYlr
NtMuHTm9mzUotOvpX4CAw05jzgSTIIrh652CEKNP4A5vJaua0FDeyj63saB1My5l
A23FF2UCgYEA5nyuZCmvuSeqKG7IgbjdVeJiw1L52stGHFmxgYAL3aLWHxBILVwd
ySkcLbF+19VqEkZlKTWJCAKkq/8QUshFNDdkTSVpY2arjJi/5OFPn+/L+dfSQcM7
wsU5HxwFtMyfL2aFJqk0PMQVKQMbr1UcWGdAtQxDjRtw90uvPYdzVYcCgYEA4yju
/97bVo1ZizWZVZOxwWvHU6EmHzYVzMJ4yDEaPd5szp7OSSXrZ5KTVi7m/inV+QIl
TgrbogKwPZqvVRYo4LkHx49UQ6Pob1d4iDZpMWe/8KChOn/wnVUVecM689CdjUwb
dB9v7VuLqPmiGfwzYn3rgSXikDKg2KkPZQiBsWcCgYAVSay9uY/uVPiFVX4VZSKk
PQ2MJszG5YFrOumHIXF3HgQSyGkyL1Dc9HwSyFMD0kVCvNe5D6XBZKUa8arrSm4B
3Z/Y9Dygnqn3iWAn3puBFR/Myp8zzblmStr0wZzRTxjgwuJHaNdXSXD+4beb4QuG
KrsyPZi7nq43WPktgKYpXwKBgG/IYuPyzMiowhmpBI2CIoTl/q5+rH3LZarfQARz
dVBgtfZvW1/PkynijTJp3i3QdIUWszjWSwJMhGGsTv916iO7qcJgG701WVoBF0Ug
UV+IiIFm6jAZaVRi3DCRC9+TFxTDEPdxyOhqli1OuqBC5R5gjJV/CSCgaVp0xyiW
qQudAoGBAKxMCLeT+aMJUXM0epwah1CT182HvBrL0DVOXsKxmooplqqlIjgj1Hu2
jF3T6hAtHtBnz36E/WNpdyO58S8zH/nFczQfU7GIzkGXOEuvhKqna+SXZQK/7X5t
8sMBOAusdkZSVkArMWILQPHyOo2xpByme1cVy7J7OzmlcUKsP0zm
-----END RSA PRIVATE KEY-----
        pk
      end

      # Generate the private key for passwordless kitchen login
      def generate_private_key
        path = File.join(config[:kitchen_root], '.kitchen', 'docker_id_rsa')
        File.open(path, 'w') do |f|
          f.write(private_key)
          f.chmod(0600)
        end
        path
      end

      def build_dockerfile
        from = "FROM #{config[:image]}"
        platform = case config[:platform]
        when 'debian', 'ubuntu'
          disable_upstart = <<-eos
            RUN dpkg-divert --local --rename --add /sbin/initctl
            RUN ln -sf /bin/true /sbin/initctl
          eos
          packages = <<-eos
            ENV DEBIAN_FRONTEND noninteractive
            RUN apt-get update
            RUN apt-get install -y sudo openssh-server curl lsb-release
          eos
          config[:disable_upstart] ? disable_upstart + packages : packages
        when 'rhel', 'centos', 'fedora'
          <<-eos
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients which curl
            RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
            RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
          eos
        when 'arch'
          <<-eos
            RUN pacman -Syu --noconfirm
            RUN pacman -S --noconfirm openssh sudo curl
            RUN ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
            RUN ssh-keygen -A -t dsa -f /etc/ssh/ssh_host_dsa_key
          eos
        when 'gentoo'
          <<-eos
            RUN emerge sync
            RUN emerge net-misc/openssh app-admin/sudo
            RUN ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
            RUN ssh-keygen -A -t dsa -f /etc/ssh/ssh_host_dsa_key
          eos
        when 'gentoo-paludis'
          <<-eos
            RUN cave sync
            RUN cave resolve -zx net-misc/openssh app-admin/sudo
            RUN ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
            RUN ssh-keygen -A -t dsa -f /etc/ssh/ssh_host_dsa_key
          eos
        else
          raise ActionFailed,
          "Unknown platform '#{config[:platform]}'"
        end

        username = config[:username]
        password = config[:password]

        base = <<-eos
          RUN if ! getent passwd #{username}; then useradd -d /home/#{username} -m -s /bin/bash #{username}; fi
          RUN echo #{username}:#{password} | chpasswd
          RUN echo '#{username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
          RUN mkdir -p /etc/sudoers.d
          RUN echo '#{username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/#{username}
          RUN chmod 0440 /etc/sudoers.d/#{username}
          RUN mkdir /home/kitchen/.ssh
          RUN chown -R kitchen:kitchen /home/kitchen/.ssh
          RUN chmod 0700 /home/kitchen/.ssh
          RUN echo '#{public_key}' >> /home/kitchen/.ssh/authorized_keys
          RUN chown kitchen:kitchen /home/kitchen/.ssh/authorized_keys && chmod 0600 /home/kitchen/.ssh/authorized_keys
        eos
        custom = ''
        Array(config[:provision_command]).each do |cmd|
          custom << "RUN #{cmd}\n"
        end
        [from, platform, base, custom].join("\n")
      end

      def dockerfile
        if config[:dockerfile]
          template = IO.read(File.expand_path(config[:dockerfile]))
          context = DockerERBContext.new(config.to_hash)
          ERB.new(template).result(context.get_binding)
        else
          build_dockerfile
        end
      end

      def parse_image_id(output)
        output.each_line do |line|
          if line =~ /image id|build successful|successfully built/i
            return line.split(/\s+/).last
          end
        end
        raise ActionFailed,
        'Could not parse Docker build output for image ID'
      end

      def build_image(state)
        cmd = "build"
        cmd << " --no-cache" unless config[:use_cache]
        output = docker_command("#{cmd} -", :input => dockerfile)
        parse_image_id(output)
      end

      def parse_container_id(output)
        container_id = output.chomp
        unless [12, 64].include?(container_id.size)
          raise ActionFailed,
          'Could not parse Docker run output for container ID'
        end
        container_id
      end

      def build_run_command(image_id)
        cmd = "run -d -p 22"
        Array(config[:forward]).each {|port| cmd << " -p #{port}"}
        Array(config[:dns]).each {|dns| cmd << " --dns #{dns}"}
        Array(config[:add_host]).each {|host, ip| cmd << " --add-host=#{host}:#{ip}"}
        Array(config[:volume]).each {|volume| cmd << " -v #{volume}"}
        Array(config[:volumes_from]).each {|container| cmd << " --volumes-from #{container}"}
        Array(config[:links]).each {|link| cmd << " --link #{link}"}
        cmd << " --name #{config[:instance_name]}" if config[:instance_name]
        cmd << " -P" if config[:publish_all]
        cmd << " -h #{config[:hostname]}" if config[:hostname]
        cmd << " -m #{config[:memory]}" if config[:memory]
        cmd << " -c #{config[:cpu]}" if config[:cpu]
        cmd << " -e http_proxy=#{config[:http_proxy]}" if config[:http_proxy]
        cmd << " -e https_proxy=#{config[:https_proxy]}" if config[:https_proxy]
        cmd << " --privileged" if config[:privileged]
        Array(config[:cap_add]).each {|cap| cmd << " --cap-add=#{cap}"} if config[:cap_add]
        Array(config[:cap_drop]).each {|cap| cmd << " --cap-drop=#{cap}"} if config[:cap_drop]
        Array(config[:security_opt]).each {|opt| cmd << " --security-opt=#{opt}"} if config[:security_opt]
        cmd << " #{image_id} #{config[:run_command]}"
        cmd
      end

      def run_container(state)
        cmd = build_run_command(state[:image_id])
        output = docker_command(cmd)
        parse_container_id(output)
      end

      def container_exists?(state)
        state[:container_id] && !!docker_command("top #{state[:container_id]}") rescue false
      end

      def parse_container_ssh_port(output)
        begin
          host, port = output.split(':')
          port.to_i
        rescue
          raise ActionFailed,
          'Could not parse Docker port output for container SSH port'
        end
      end

      def container_ssh_port(state)
        begin
          output = docker_command("port #{state[:container_id]} 22/tcp")
          parse_container_ssh_port(output)
        rescue
          raise ActionFailed,
          'Docker reports container has no ssh port mapped'
        end
      end

      def rm_container(state)
        container_id = state[:container_id]
        docker_command("stop #{container_id}")
        docker_command("rm #{container_id}")
      end

      def rm_image(state)
        image_id = state[:image_id]
        docker_command("rmi #{image_id}")
      end
    end
  end
end
