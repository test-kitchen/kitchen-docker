# Kitchen-Docker

[![Build Status](https://travis-ci.org/test-kitchen/kitchen-docker.svg?branch=master)](https://travis-ci.org/test-kitchen/kitchen-docker)
[![Gem Version](https://img.shields.io/gem/v/kitchen-docker.svg)](https://rubygems.org/gems/kitchen-docker)
[![Coverage](https://img.shields.io/codecov/c/github/test-kitchen/kitchen-docker.svg)](https://codecov.io/github/test-kitchen/kitchen-docker)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A Test Kitchen Driver and Transport for Docker.

***MAINTAINERS WANTED***: This Test-Kitchen driver is currently without a maintainer and has many known issues. If you're interested in maintaining this driver for the long run including expanding the CI testing please reach out on [Chef Community Slack: #test-kitchen](https://chefcommunity.slack.com/archives/C2B6G1WCQ). Until such a time that this driver is maintained we highly recommend the [kitchen-dokken](https://github.com/test-kitchen/kitchen-dokken) for Chef Infra testing with Docker containers.

## Requirements

* [Docker][docker_installation] **(>= 1.5)**

## Installation and Setup

Please read the Test Kitchen [docs][test_kitchen_docs] for more details.

Example (Linux) `.kitchen.local.yml`:

```yaml
---
driver:
  name: docker
  env_variables:
    TEST_KEY: TEST_VALUE

platforms:
- name: ubuntu
  run_list:
  - recipe[apt]
- name: centos
  driver_config:
    image: centos
    platform: rhel
  run_list:
  - recipe[yum]

transport:
  name: docker
```

Example (Windows) `.kitchen.local.yml`:

```yaml
---
driver:
  name: docker

platforms:
- name: windows
  driver_config:
    image: mcr.microsoft.com/windows/servercore:1607
    platform: windows
  run_list:
  - recipe[chef_client]

transport:
  name: docker
  env_variables:
    TEST_KEY: TEST_VALUE
```

## Default Configuration

This driver can determine an image and platform type for a select number of
platforms.

Examples:

```yaml
---
platforms:
- name: ubuntu-18.04
- name: centos-7
```

This will effectively generate a configuration similar to:

```yaml
---
platforms:
- name: ubuntu-18.04
  driver_config:
    image: ubuntu:18.04
    platform: ubuntu
- name: centos-7
  driver_config:
    image: centos:7
    platform: centos
```

## Configuration

### binary

The Docker binary to use.

The default value is `docker`.

Examples:

```yaml
  binary: docker.io
```

```yaml
  binary: /opt/docker
```

### socket

The Docker daemon socket to use. By default, Docker will listen on `unix:///var/run/docker.sock` (On Windows, `npipe:////./pipe/docker_engine`),
and no configuration here is required. If Docker is binding to another host/port or Unix socket, you will need to set this option.
If a TCP socket is set, its host will be used for SSH access to suite containers.

Examples:

```yaml
  socket: unix:///tmp/docker.sock
```

```yaml
  socket: tcp://docker.example.com:4242
```

If you are using the InSpec verifier on Windows, using named pipes for the Docker engine will not work with the Docker transport.
Set the socket option with the TCP socket address of the Docker engine as shown below:

```yaml
socket: tcp://localhost:2375
```

The Docker engine must be configured to listen on a TCP port (default port is 2375). This can be configured by editing the configuration file
(usually located in `C:\ProgramData\docker\config\daemon.json`) and adding the hosts value:

```json
"hosts": ["tcp://0.0.0.0:2375"]
```

Example configuration is shown below:

```json
{
  "registry-mirrors": [],
  "insecure-registries": [],
  "debug": true,
  "experimental": false,
  "hosts": ["tcp://0.0.0.0:2375"]
}
```

If you use [Boot2Docker](https://github.com/boot2docker/boot2docker)
or [docker-machine](https://docs.docker.com/machine/get-started/) set
your `DOCKER_HOST` environment variable properly with `export
DOCKER_HOST=tcp://192.168.59.103:2375` or `eval "$(docker-machine env
$MACHINE)"` then use the following:

```yaml
socket: tcp://192.168.59.103:2375
```

### image

The Docker image to use as the base for the suite containers. You can find
images using the [Docker Index][docker_index].

The default will be computed, using the platform name (see the Default
Configuration section for more details).

### isolation

The isolation technology for the container. This is not set by default and will use the default container isolation settings.

For example, the following driver configuration options can be used to specify the container isolation technology for Windows containers:

```yaml
# Hyper-V
isolation: hyperv

# Process
isolation: process
```

### platform

The platform of the chosen image. This is used to properly bootstrap the
suite container for Test Kitchen. Kitchen Docker currently supports:

* `arch`
* `debian` or `ubuntu`
* `amazonlinux`, `rhel`, `centos`, `fedora`, `oraclelinux`, `almalinux` or `rockylinux`
* `gentoo` or `gentoo-paludis`
* `opensuse/tumbleweed`, `opensuse/leap`, `opensuse` or `sles`
* `windows`

The default will be computed, using the platform name (see the Default
Configuration section for more details).

### require\_chef\_omnibus

Determines whether or not a Chef [Omnibus package][chef_omnibus_dl] will be
installed. There are several different behaviors available:

* `true` - the latest release will be installed. Subsequent converges
  will skip re-installing if chef is present.
* `latest` - the latest release will be installed. Subsequent converges
  will always re-install even if chef is present.
* `<VERSION_STRING>` (ex: `10.24.0`) - the desired version string will
  be passed the the install.sh script. Subsequent converges will skip if
  the installed version and the desired version match.
* `false` or `nil` - no chef is installed.

The default value is `true`.

### disable\_upstart

Disables upstart on Debian/Ubuntu containers, as many images do not support a
working upstart.

The default value is `true`.

### provision\_command

Custom command(s) to be run when provisioning the base for the suite containers.

Examples:

```yaml
  provision_command: curl -L https://www.opscode.com/chef/install.sh | bash
```

```yaml
  provision_command:
    - apt-get install dnsutils
    - apt-get install telnet
```

```yaml
driver_config:
  provision_command: curl -L https://www.opscode.com/chef/install.sh | bash
  require_chef_omnibus: false
```

### env_variables

Adds environment variables to Docker container

Examples:

```yaml
  env_variables:
    TEST_KEY_1: TEST_VALUE
    SOME_VAR: SOME_VALUE
```

### use\_cache

This determines if the Docker cache is used when provisioning the base for suite
containers.

The default value is `true`.

### use\_sudo

This determines if Docker commands are run with `sudo`.

The default value depends on the type of socket being used. For local sockets, the default value is `true`. For remote sockets, the default value is `false`.

This should be set to `false` if you're using boot2docker, as every command passed into the VM runs as root by default.

### remove\_images

This determines if images are automatically removed when the suite container is
destroyed.

The default value is `false`.

### run\_command

Sets the command used to run the suite container.

The default value is `/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no -o PasswordAuthentication=yes -o UsePrivilegeSeparation=no -o PidFile=/tmp/sshd.pid`.

Examples:

```yaml
  run_command: /sbin/init
```

### memory

Sets the memory limit for the suite container in bytes. Otherwise use Dockers
default. You can read more about `memory.limit_in_bytes` [here][memory_limit].

### cpu

Sets the CPU shares (relative weight) for the suite container. Otherwise use
Dockers defaults. You can read more about cpu.shares [here][cpu_shares].

### volume

Adds a data volume(s) to the suite container.

Examples:

```yaml
  volume: /ftp
```

```yaml
  volume:
  - /ftp
  - /srv
```

### volumes\_from

Mount volumes managed by other containers.

Examples:

```yaml
  volumes_from: repos
```

```yaml
  volumes_from:
  - repos
  - logging
  - rvm
```

### mount

Attach a filesystem mount to the container (**NOTE:** supported only in docker
17.05 and newer).

Examples:

```yaml
  mount: type=volume,source=my-volume,destination=/path/in/container
```

```yaml
  mount:
  - type=volume,source=my-volume,destination=/path/in/container
  - type=tmpfs,tmpfs-size=512M,destination=/path/to/tmpdir
```

### tmpfs

Adds a tmpfs volume(s) to the suite container.

Examples:

```yaml
  tmpfs: /tmp
```

```yaml
  tmpfs:
  - /tmp:exec
  - /run
```

### dns

Adjusts `resolv.conf` to use the dns servers specified. Otherwise use
Dockers defaults.

Examples:

```yaml
  dns: 8.8.8.8
```

```yaml
  dns:
  - 8.8.8.8
  - 8.8.4.4
```

### http\_proxy

Sets an http proxy for the suite container using the `http_proxy` environment variable.

Examples:

```yaml
  http_proxy: http://proxy.host.com:8080
```

### https\_proxy

Sets an https proxy for the suite container using the `https_proxy` environment variable.

Examples:

```yaml
  https_proxy: http://proxy.host.com:8080
```

### forward

Set suite container port(s) to forward to the host machine. You may specify
the host (public) port in the mappings, if not, Docker chooses for you.

Examples:

```yaml
  forward: 80
```

```yaml
  forward:
  - 22:2222
  - 80:8080
```

### hostname

Set the suite container hostname. Otherwise use Dockers default.

Examples:

```yaml
  hostname: foobar.local
```

### privileged

Run the suite container in privileged mode. This allows certain functionality
inside the Docker container which is not otherwise permitted.

The default value is `false`.

Examples:

```yaml
  privileged: true
```

### cap\_add

Adds a capability to the running container.

Examples:

```yaml
cap_add:
- SYS_PTRACE

```

### cap\_drop

Drops a capability from the running container.

Examples:

```yaml
cap_drop:
- CHOWN
```

### security\_opt

Apply a security profile to the Docker container. Allowing finer granularity of
access control than privileged mode, through leveraging SELinux/AppArmor
profiles to grant access to specific resources.

Examples:

```yaml
security_opt:
  - apparmor:my_profile
```

### dockerfile

Use a custom Dockerfile, instead of having Kitchen-Docker build one for you.

Examples:

```yaml
  dockerfile: test/Dockerfile
```

### instance\_name

Set the name of container to link to other container(s).

Examples:

```yaml
  instance_name: web
```

### links

Set ```instance_name```(and alias) of other container(s) that connect from the suite container.

Examples:

```yaml
 links: db:db
```

```yaml
  links:
  - db:db
  - kvs:kvs
```

### publish\_all

Publish all exposed ports to the host interfaces.
This option used to communicate between some containers.

The default value is `false`.

Examples:

```yaml
  publish_all: true
```

### devices

Share a host device with the container. Host device must be an absolute path.

Examples:

```yaml
devices: /dev/vboxdrv
```

```yaml
devices:
  - /dev/vboxdrv
  - /dev/vboxnetctl
```

### build_context

Transfer the cookbook directory (cwd) as build context. This is required for
Dockerfile commands like ADD and COPY. When using a remote Docker server, the
whole directory has to be copied, which can be slow.

The default value is `true` for local Docker and `false` for remote Docker.

Examples:

```yaml
  build_context: true
```

### build_options

Extra command-line options to pass to `docker build` when creating the image.

Examples:

```yaml
  build_options: --rm=false
```

```yaml
  build_options:
    rm: false
    build-arg: something
```

### run_options

Extra command-line options to pass to `docker run` when starting the container.

Examples:

```yaml
  run_options: --ip=1.2.3.4
```

```yaml
  run_options:
    tmpfs:
    - /run/lock
    - /tmp
    net: br3
```

### build_tempdir

Relative (to `build_context`) temporary directory path for built Dockerfile.

Example:

```yaml
  build_tempdir: .kitchen
```

### use_internal_docker_network

If you want to use kitchen-docker from within another Docker container you'll
need to set this to true. When set to true uses port 22 as the SSH port and
the IP of the container that chef is going to run in as the hostname so that
you can connect to it over SSH from within another Docker container.

Examples:

```yaml
  use_internal_docker_network: true
```

### docker_platform

Configure the CPU platform (architecture) used by docker to build the image.

Examples:

```yaml
  docker_platform: linux/arm64
```

```yaml
  docker_platform: linux/amd64
```

## Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

```text
Copyright 2013-2016, [Sean Porter](https://github.com/portertech)
Copyright 2015-2016, [Noah Kantrowitz](https://github.com/coderanger)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

[issues]:                 https://github.com/test-kitchen/kitchen-docker/issues
[repo]:                   https://github.com/test-kitchen/kitchen-docker
[docker_installation]:    https://docs.docker.com/installation/#installation
[docker_index]:           https://index.docker.io/
[test_kitchen_docs]:      https://kitchen.ci/docs/getting-started/introduction/
[chef_omnibus_dl]:        https://downloads.chef.io/chef-client/
[cpu_shares]:             https://docs.fedoraproject.org/en-US/Fedora/17/html/Resource_Management_Guide/sec-cpu.html
[memory_limit]:           https://docs.fedoraproject.org/en-US/Fedora/17/html/Resource_Management_Guide/sec-memory.html
