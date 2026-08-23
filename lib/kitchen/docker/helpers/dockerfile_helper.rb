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
require "kitchen/configurable"

module Kitchen
  module Docker
    # Mixins shared by the driver, transport, and container classes.
    module Helpers
      # Per-distribution Dockerfile fragments that prepare a Linux image for SSH.
      module DockerfileHelper
        include Configurable

        # Dockerfile lines that prepare the configured platform for SSH.
        #
        # Each distribution needs its own package manager invocation to install an
        # SSH server and sudo, and its own host-key generation, which is why there
        # is one method per family rather than a shared one.
        #
        # @return [String] the RUN lines for this platform
        # @raise [Kitchen::ActionFailed] if the platform is not recognised
        def dockerfile_platform
          case config[:platform]
          when "arch"
            arch_platform
          when "debian", "ubuntu"
            debian_platform
          when "fedora"
            fedora_platform
          when "gentoo"
            gentoo_platform
          when "gentoo-paludis"
            gentoo_paludis_platform
          when "opensuse/tumbleweed", "opensuse/leap", "opensuse", "sles"
            opensuse_platform
          when "rhel", "centos", "oraclelinux"
            rhel_platform
          when "amazonlinux"
            amazonlinux_platform
          when "centosstream"
            centosstream_platform
          when "almalinux"
            almalinux_platform
          when "rockylinux"
            rockylinux_platform
          when "photon"
            photonos_platform
          else
            raise ActionFailed, "Unknown platform '#{config[:platform]}'"
          end
        end

        # Dockerfile lines installing an SSH server and sudo on Arch Linux.
        #
        # @return [String] the RUN lines
        def arch_platform
          <<-CODE
            RUN pacman --noconfirm -Sy archlinux-keyring
            RUN pacman-db-upgrade
            RUN pacman --noconfirm -Syu openssl openssh sudo curl
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Debian and Ubuntu.
        #
        # @return [String] the RUN lines
        def debian_platform
          disable_upstart = <<-CODE
            RUN [ ! -f "/sbin/initctl" ] || dpkg-divert --local --rename --add /sbin/initctl \
                && ln -sf /bin/true /sbin/initctl
          CODE
          packages = <<-CODE
            ENV DEBIAN_FRONTEND=noninteractive
            ENV container=docker
            RUN apt-get update
            RUN apt-get install -y sudo openssh-server curl lsb-release
          CODE
          config[:disable_upstart] ? disable_upstart + packages : packages
        end

        # Dockerfile lines installing an SSH server and sudo on Fedora.
        #
        # @return [String] the RUN lines
        def fedora_platform
          <<-CODE
            ENV container=docker
            RUN dnf clean all
            RUN dnf install -y sudo openssh-server openssh-clients which curl
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Gentoo with Portage.
        #
        # @return [String] the RUN lines
        def gentoo_platform
          <<-CODE
            RUN emerge-webrsync
            RUN emerge --quiet --noreplace net-misc/openssh app-admin/sudo
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Gentoo with Paludis.
        #
        # @return [String] the RUN lines
        def gentoo_paludis_platform
          <<-CODE
            RUN cave sync
            RUN cave resolve -zx net-misc/openssh app-admin/sudo
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -A -t rsa -f /etc/ssh/ssh_host_rsa_key
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on openSUSE and SLES.
        #
        # @return [String] the RUN lines
        def opensuse_platform
          <<-CODE
            ENV container=docker
            RUN zypper install -y sudo openssh which curl gawk
            RUN /usr/sbin/sshd-gen-keys-start
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on RHEL, CentOS, and Oracle Linux.
        #
        # @return [String] the RUN lines
        def rhel_platform
          <<-CODE
            ENV container=docker
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients which
            RUN which curl || yum install -y curl
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Amazon Linux.
        #
        # @return [String] the RUN lines
        def amazonlinux_platform
          <<-CODE
            ENV container=docker
            RUN yum clean all
            RUN yum install -y --allowerasing sudo openssh-server openssh-clients which curl
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on CentOS Stream.
        #
        # @return [String] the RUN lines
        def centosstream_platform
          <<-CODE
            ENV container=docker
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients which
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on AlmaLinux.
        #
        # @return [String] the RUN lines
        def almalinux_platform
          <<-CODE
            ENV container=docker
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients which
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Rocky Linux.
        #
        # @return [String] the RUN lines
        def rockylinux_platform
          <<-CODE
            ENV container=docker
            RUN yum clean all
            RUN yum install -y sudo openssh-server openssh-clients which
            RUN [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
          CODE
        end

        # Dockerfile lines installing an SSH server and sudo on Photon OS.
        #
        # @return [String] the RUN lines
        def photonos_platform
          <<-CODE
            ENV container=docker
            RUN tdnf clean all
            RUN tdnf install -y sudo openssh-server openssh-clients which curl
            RUN [ -f "/etc/ssh/ssh_host_ecdsa_key" ] || ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
            RUN [ -f "/etc/ssh/ssh_host_ed25519_key" ] || ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
          CODE
        end

        # Dockerfile lines creating the login user and its SSH directory.
        #
        # The user gets passwordless sudo and +Defaults !requiretty+, because Test
        # Kitchen runs commands non-interactively and sudo would otherwise refuse.
        #
        # @param username [String] the login user to create
        # @param homedir [String] that user's home directory
        # @return [String] the RUN lines
        def dockerfile_base_linux(username, homedir)
          <<-CODE
            RUN if ! getent passwd #{username}; then \
                  useradd -d #{homedir} -m -s /bin/bash -p '*' #{username}; \
                fi
            RUN mkdir -p /etc/sudoers.d
            RUN chmod 0750 /etc/sudoers.d
            RUN echo "#{username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/#{username}
            RUN echo "Defaults !requiretty" >> /etc/sudoers.d/#{username}
            RUN mkdir -p #{homedir}/.ssh
            RUN chown -R #{username} #{homedir}/.ssh
            RUN chmod 0700 #{homedir}/.ssh
            RUN touch #{homedir}/.ssh/authorized_keys
            RUN chown #{username} #{homedir}/.ssh/authorized_keys
            RUN chmod 0600 #{homedir}/.ssh/authorized_keys
            RUN mkdir -p /run/sshd
          CODE
        end
      end
    end
  end
end
