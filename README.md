# Kitchen::Docker

A Test Kitchen Driver for Docker.

## Requirements

* [Docker][docker_getting_started]

## Known Issues

* Upstart is neutered due to [this issue][docker_upstart_issue].

## Installation and Setup

Please read the [Driver usage][driver_usage] page for more details.

Example `.kitchen.local.yml`:

```
---
driver_plugin: docker

platforms:
- name: ubuntu
  run_list:
  - recipe[apt]
- name: centos
  driver_config:
    image: "centos"
    platform: "rhel"
  run_list:
  - recipe[yum]
```

## Default Configuration

This driver can determine an image and platform type for a select number of
platforms. Currently, the following platform names are supported:

```
---
platforms:
- name: ubuntu-12.04
- name: centos-6.4
```

This will effectively generate a configuration similar to:

```
---
platforms:
- name: ubuntu-12.04
  driver_config:
    image: ubuntu:12.04
    platform: ubuntu
- name: centos-6.4
  driver_config:
    image: centos:6.4
    platform: centos
```

## Configuration

### socket

The Docker daemon socket to use. By default, Docker it will listen on
`unix:///var/run/docker.sock`, and no configuration here is required. If
Docker is binding to another host/port or Unix socket, you will need to set
this option. If a TCP socket is set, its host will be used for SSH access
to containers.

Examples:

```
  socket: unix:///tmp/docker.sock
```

```
  socket: tcp://docker.example.com:4242
```

### image

The Docker image to use as the base for the suite containers. You can find
images using the [Docker Index][docker_index].

The default will be determined by the Platform name, if a default exists
(see the Default Configuration section for more details). If a default
cannot be computed, then the default value is `base`, an official Ubuntu
[image][docker_default_image].

### platform

The platform of the chosen image. This is used to properly bootstrap the
suite container for Test Kitchen. Kitchen Docker currently supports:

* `debian` or `ubuntu`
* `rhel` or `centos`

The default will be determined by the Platform name, if a default exists
(see the Default Configuration section for more details). If a default
cannot be computed, then the default value is `ubuntu`.

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

### provision\_command

Custom command(s) to be run when provisioning the base for the suite containers.

Examples:

```
  provision_command: "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
```

```
  provision_command:
    - "apt-get install dnsutils"
    - "apt-get install telnet"
```

```
driver_config:
  provision_command: "curl -L https://www.opscode.com/chef/install.sh | sudo bash"
  require_chef_omnibus: false
```

### remove\_images

This determines if images are automatically removed when the suite container is
destroyed.

The default value is `false`.

### memory

Sets the memory limit for the container. The value must be set in bytes.
If not, set it defaults to dockers default settings. You can read more about
`memory.limit_in_bytes` [here][memory_limit_in_bytes].

### cpu

Sets the cpu shares (relative weight). If not set, it defaults to dockers
default settings. You can read more about cpu.shares [here][cpu_shares].

### volume

Adds a data volume(s) to the suite container.

Examples:

```
  volume: /ftp
```

```
  volume:
  - /ftp
  - /srv
```

## dns

Adjusts `resolv.conf` to use the dns servers specified. Otherwise use
dockers defaults.

Examples:

```
  dns: 8.8.8.8
```

```
  dns:
  - 8.8.8.8
  - 8.8.4.4
```

### forward

Suite container port(s) to forward to the host machine. You may specify
the host (public) port in the mappings, if not, Docker chooses for you.

Examples:

```
  forward: 80
```

```
  forward:
  - 22:2222
  - 80:8080
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

## Authors

Created and maintained by [Sean Porter][author] (<portertech@gmail.com>)

## License

Apache 2.0 (see [LICENSE][license])


[author]:                 https://github.com/portertech
[issues]:                 https://github.com/portertech/kitchen-docker/issues
[license]:                https://github.com/portertech/kitchen-docker/blob/master/LICENSE
[repo]:                   https://github.com/portertech/kitchen-docker
[docker_getting_started]: http://www.docker.io/gettingstarted/
[docker_upstart_issue]:   https://github.com/dotcloud/docker/issues/223
[docker_index]:           https://index.docker.io/
[docker_default_image]:   https://index.docker.io/_/base/
[driver_usage]:           http://docs.kitchen-ci.org/drivers/usage
[chef_omnibus_dl]:        http://www.opscode.com/chef/install/
[cpu_shares]:             https://docs.fedoraproject.org/en-US/Fedora/17/html/Resource_Management_Guide/sec-cpu.html
[memory_limit_in_bytes]:  https://docs.fedoraproject.org/en-US/Fedora/17/html/Resource_Management_Guide/sec-memory.html
