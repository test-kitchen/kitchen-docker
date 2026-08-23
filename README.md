# kitchen-docker

[![Gem Version](https://img.shields.io/gem/v/kitchen-docker.svg)](https://rubygems.org/gems/kitchen-docker)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Test Kitchen][test_kitchen_docs] **driver** and **transport** for Docker.

The driver builds an image for each platform and runs a container from it. The
transport runs your commands inside that container with `docker exec`, so no
SSH or WinRM server is needed. Together they let you converge and verify a
cookbook against a dozen distributions in about the time it takes one virtual
machine to boot.

> **Maintainers wanted.** This driver is currently without a maintainer and has
> known issues. If you would like to take it on — including expanding the CI
> coverage — please reach out in
> [#test-kitchen on Chef Community Slack](https://chefcommunity.slack.com/archives/C2B6G1WCQ).
> Until then, we recommend [kitchen-dokken][dokken] for Chef Infra testing with
> Docker containers.

## Contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Quick start](#quick-start)
* [How it works](#how-it-works)
* [Choosing an image and platform](#choosing-an-image-and-platform)
* [Driver configuration](#driver-configuration)
* [Transport configuration](#transport-configuration)
* [Logging into a container](#logging-into-a-container)
* [Examples](#examples)
* [Using with Chef](#using-with-chef)
* [Troubleshooting](#troubleshooting)
* [Contributing](#contributing)
* [License](#license)

## Requirements

* [Docker][docker_installation] 1.5 or newer, running locally or reachable over
  the network.
* Ruby 3.1 or newer.

## Installation

This driver ships as part of [Cinc Workstation][cinc_workstation] and
[Chef Workstation][chef_workstation]. If you have either installed, there is
nothing else to do.

To install it into a standalone Ruby:

```sh
gem install kitchen-docker
```

Or add it to your cookbook's `Gemfile`:

```ruby
gem "kitchen-docker"
```

## Quick start

Create a `kitchen.yml` in your cookbook:

```yaml
---
driver:
  name: docker

transport:
  name: docker

provisioner:
  name: cinc_infra

verifier:
  name: cinc_auditor

platforms:
  - name: ubuntu-24.04
  - name: almalinux-9

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

That is a complete configuration — no `image`, no `platform`, no
`run_command`. The driver derives them from each platform name.

Run it:

```sh
kitchen test
```

Test Kitchen will, for each platform, build an image, start a container,
converge your cookbook, run the verifier, and destroy the container. To work
interactively instead:

```sh
kitchen converge default-ubuntu-2404   # build, start, and converge
kitchen login default-ubuntu-2404      # get a shell inside the container
kitchen verify default-ubuntu-2404     # run the tests
kitchen destroy default-ubuntu-2404    # clean up
```

The examples above use the `cinc_infra` provisioner and `cinc_auditor`
verifier. If you use Chef Workstation, substitute `chef_infra` and `inspec` —
see [Using with Chef](#using-with-chef). No driver changes are needed.

## How it works

Knowing the sequence makes the configuration options below much easier to
place:

1. **Generate a Dockerfile.** The driver writes one based on `image` and
   `platform`: it installs an SSH server and `sudo`, creates the `username`
   account, and authorises the generated `public_key`. Anything in
   `provision_command` is appended. Supply your own with
   [`dockerfile`](#images-and-building) to skip all of this.
2. **Build the image**, sending `build_context` (your cookbook directory) to
   the daemon if the daemon needs it.
3. **Run a container** from the image with `run_command` as PID 1 — by default
   `sshd`, which keeps the container alive and gives Test Kitchen something to
   connect to.
4. **Run commands in it.** With `transport: docker` this is `docker exec`. With
   the default SSH transport, it is SSH to the forwarded port using the
   generated key.

Because the image is rebuilt from a Dockerfile, most driver options are
*image*-level (`build_options`, `provision_command`) or *container*-level
(`volume`, `privileged`, `forward`). The tables below are grouped that way.

## Choosing an image and platform

For most platforms, the name is all you need. The driver splits it on the first
`-` into an image and a platform family:

```yaml
platforms:
  - name: ubuntu-24.04     # image: ubuntu:24.04,    platform: ubuntu
  - name: almalinux-9      # image: almalinux:9,     platform: almalinux
  - name: fedora-latest    # image: fedora:latest,   platform: fedora
```

`centos` is special-cased, because its images are tagged `centos7` rather than
`centos:7`.

Set `image` and `platform` explicitly when the image name does not match the
distribution, which is common for vendor or mirror images:

```yaml
platforms:
  - name: centos-stream-9
    driver:
      image: dokken/centos-stream-9
      platform: centosstream
```

`platform` selects how the Dockerfile bootstraps the container, so it must be
one the driver recognises:

| `platform` | Notes |
| --- | --- |
| `debian`, `ubuntu` | Also honours [`disable_upstart`](#provisioning-the-image). |
| `rhel`, `centos`, `oraclelinux` | Shared RHEL package set. |
| `almalinux`, `rockylinux`, `centosstream` | RHEL rebuilds, each with its own package set. |
| `amazonlinux` | Adds `--allowerasing` to `dnf install`. |
| `fedora` | |
| `arch` | |
| `gentoo`, `gentoo-paludis` | |
| `opensuse`, `opensuse/leap`, `opensuse/tumbleweed`, `sles` | |
| `photon` | |
| `windows` | Uses Windows containers; see [Windows containers](#windows-containers). |

Anything else raises `Unknown platform '<name>'`. If your distribution is not
listed, supply your own [`dockerfile`](#images-and-building) instead.

## Driver configuration

Everything in this section goes under `driver:` — either at the top level, or
per-platform and per-suite:

```yaml
driver:
  name: docker
  privileged: true          # applies everywhere

platforms:
  - name: ubuntu-24.04
    driver:
      forward:              # applies to this platform only
        - 8080:80
```

### Images and building

| Option | Default | Description |
| --- | --- | --- |
| `image` | derived from the platform name | Base image for the container. |
| `platform` | derived from the platform name | Distribution family, used to bootstrap the image. See [above](#choosing-an-image-and-platform). |
| `dockerfile` | *(none)* | Path to your own Dockerfile, used instead of the generated one. Rendered as [ERB](#using-a-custom-dockerfile). |
| `build_context` | `true` locally, `false` for a remote daemon | Send the working directory to the daemon as build context. Required for `ADD` and `COPY`; slow against a remote daemon. |
| `build_options` | *(none)* | Extra flags for `docker build`, as a string or a map. |
| `build_tempdir` | working directory | Where the generated Dockerfile is written, relative to `build_context`. |
| `use_cache` | `true` | Use Docker's build cache. `false` adds `--no-cache`. |
| `remove_images` | `false` | Remove the built image on `kitchen destroy`. |
| `docker_platform` | *(none)* | Target architecture, passed as `--platform` to both build and run — e.g. `linux/arm64`. |

### Provisioning the image

| Option | Default | Description |
| --- | --- | --- |
| `provision_command` | *(none)* | Command, or list of commands, to run while building the image. Each becomes a `RUN` line. |
| `disable_upstart` | `true` | Neutralise upstart on Debian and Ubuntu images that ship a broken copy. Ignored on other platforms. |
| `username` | `kitchen` on Linux, unset on Windows | Account created in the image and used for the connection. |
| `private_key` | `.kitchen/docker_id_rsa` | SSH key used to reach the container. Generated on first use if absent. |
| `public_key` | `.kitchen/docker_id_rsa.pub` | Matching public key, authorised in the image. |

### Running the container

| Option | Default | Description |
| --- | --- | --- |
| `run_command` | `sshd -D …` on Linux, `ping -t localhost` on Windows | Process run as PID 1. It must stay in the foreground, or the container will exit immediately. |
| `run_options` | *(none)* | Extra flags for `docker run`, as a string or a map. |
| `instance_name` | generated, unique | `--name` for the container. Set it to give other containers a stable name to `link` to. |
| `hostname` | Docker's default | Container hostname. |
| `memory` | Docker's default | Memory limit in bytes. |
| `cpu` | Docker's default | CPU shares (relative weight). |
| `gpus` | *(none)* | Passed as `--gpus`. Requires a GPU-enabled Docker installation. |
| `isolation` | Docker's default | Isolation technology — `hyperv` or `process` for Windows containers. |
| `interactive` | `false` | Pass `-i`, keeping stdin open. |
| `tty` | `false` | Pass `-t`, allocating a pseudo-TTY. |
| `env_variables` | *(none)* | Environment variables set in the container, as a map. |
| `wait_for_transport` | `true` | Wait for the transport to answer before converging. Set `false` for containers that do not stay up. |
| `detach` | `false` | Run provisioner commands with `docker exec -d`, returning immediately instead of waiting for them. The container itself is always started detached, regardless of this setting, and `kitchen login` ignores it so the shell stays usable. |

### Networking

| Option | Default | Description |
| --- | --- | --- |
| `forward` | *(none)* | Ports to publish, as `container` or `host:container`. Docker picks the host port if you omit it. |
| `publish_all` | `false` | Publish every exposed port to a random host port (`-P`). |
| `dns` | Docker's default | DNS servers for the container. |
| `add_host` | *(none)* | Extra `/etc/hosts` entries, as a map of hostname to IP. |
| `links` | *(none)* | Other containers to link, as `name:alias`. |
| `use_internal_docker_network` | `false` | Connect over the container's own IP on port 22 instead of a forwarded host port. Needed when Test Kitchen itself runs inside a container. |

### Storage

| Option | Default | Description |
| --- | --- | --- |
| `volume` | *(none)* | Volumes to add, in `docker run -v` syntax. |
| `volumes_from` | *(none)* | Containers whose volumes to mount. |
| `mount` | *(none)* | Mounts in `--mount` syntax. Requires Docker 17.05 or newer. |
| `tmpfs` | *(none)* | tmpfs mounts, e.g. `/tmp` or `/tmp:exec`. |
| `devices` | *(none)* | Host devices to share. Must be absolute paths. |

Each of these accepts a single value or a list.

### Security and privileges

| Option | Default | Description |
| --- | --- | --- |
| `privileged` | `false` | Run the container privileged. Needed for systemd, Docker-in-Docker, and some kernel-level tests. |
| `cap_add` | *(none)* | Capabilities to add, e.g. `SYS_PTRACE`. |
| `cap_drop` | *(none)* | Capabilities to drop. |
| `security_opt` | *(none)* | SELinux or AppArmor profiles — finer-grained than `privileged`. |

### Proxies

| Option | Default | Description |
| --- | --- | --- |
| `http_proxy` | *(none)* | Set as `http_proxy` and `HTTP_PROXY`, both in the image and in the running container. |
| `https_proxy` | *(none)* | Set as `https_proxy` and `HTTPS_PROXY`, in the image and the container. |
| `no_proxy` | *(none)* | Set as `no_proxy` and `NO_PROXY` **in the image only**, for use during the build. |

### Connecting to the Docker daemon

| Option | Default | Description |
| --- | --- | --- |
| `binary` | `docker` | Docker CLI to invoke — e.g. `docker.io`, or an absolute path. |
| `socket` | `$DOCKER_HOST`, else `unix:///var/run/docker.sock` (`npipe:////./pipe/docker_engine` on Windows) | Daemon to talk to. A `tcp://` value also supplies the host used for SSH to the container. |
| `use_sudo` | `false` | Run every `docker` command through `sudo`. |
| `sudo_command` | `sudo -E` | The command `use_sudo` prefixes, for hosts that use something else (`doas`, say). |
| `tls` | `false` | Use TLS when connecting. |
| `tls_verify` | `false` | Verify the daemon's certificate. |
| `tls_cacert` | *(none)* | Path to the CA certificate. |
| `tls_cert` | *(none)* | Path to the client certificate. |
| `tls_key` | *(none)* | Path to the client key. |

## Transport configuration

The `docker` transport runs commands with `docker exec` rather than over SSH or
WinRM. It is the recommended pairing with this driver, and is required for
Windows containers, which have no WinRM service:

```yaml
transport:
  name: docker
```

These options go under `transport:`, not `driver:`.

| Option | Default | Description |
| --- | --- | --- |
| `binary` | `docker` | Docker CLI to invoke. |
| `socket` | `$DOCKER_HOST`, else the platform default | Daemon to talk to. |
| `username` | `kitchen` on Linux, unset on Windows | User that commands run as (`-u`). |
| `working_dir` | *(none)* | Working directory inside the container (`-w`). |
| `temp_dir` | `/tmp`, or `$env:TEMP` on Windows | Directory used to stage uploaded files. |
| `env_variables` | *(none)* | Environment variables for each command. |
| `privileged` | `false` | Run commands with `--privileged`. |
| `interactive` | `false` | Pass `-i`. |
| `tty` | `false` | Pass `-t`. |
| `use_sudo` | `false` | Run every `docker` command through `sudo`. |
| `sudo_command` | `sudo -E` | The command `use_sudo` prefixes. |
| `tls`, `tls_verify`, `tls_cacert`, `tls_cert`, `tls_key` | as for the driver | TLS settings for the daemon connection. |

The driver and transport each read their own copy of `binary`, `socket`,
`username`, `use_sudo`, and the TLS settings. If you point one at a non-default
daemon, or need `sudo` to reach it, configure the other the same way.

## Logging into a container

`kitchen login` opens an interactive shell inside a running container, so you
do not have to look up the container ID and run `docker exec` yourself:

```sh
kitchen login default-ubuntu-2404
```

On Linux platforms this starts `/bin/bash --login -i`; on Windows platforms it
starts `powershell`. The transport's `username`, `working_dir`,
`env_variables`, and `privileged` settings are honoured, so the shell matches
the environment the provisioner ran in.

## Examples

### Testing a systemd service

systemd needs to run as PID 1 with enough privileges to manage cgroups:

```yaml
platforms:
  - name: almalinux-9
    driver:
      run_command: /usr/sbin/init
      privileged: true
      volume: /sys/fs/cgroup:/sys/fs/cgroup:ro
```

Because `run_command` is no longer `sshd`, pair this with `transport: docker`
so Test Kitchen does not try to connect over SSH.

### Using a custom Dockerfile

Point `dockerfile` at your own file to bypass the generated one entirely:

```yaml
platforms:
  - name: custom
    driver:
      dockerfile: test/Dockerfile
      username: dockerfile
      password: dockerfile
```

The file is rendered as an **ERB template**, and every driver configuration key
is available as an instance variable of the same name — `@username`, `@image`,
`@public_key`, and so on, including keys you invent yourself (`@password`
above). That is how a custom Dockerfile authorises the key Test Kitchen will
connect with:

```erb
FROM almalinux:latest
RUN dnf install -y sudo openssh-server openssh-clients which curl
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN useradd -d /home/<%= @username %> -m -s /bin/bash <%= @username %>
RUN echo '<%= @username %> ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir -p /home/<%= @username %>/.ssh && chmod 0700 /home/<%= @username %>/.ssh
RUN echo '<%= IO.read(@public_key).strip %>' >> /home/<%= @username %>/.ssh/authorized_keys
```

A working copy lives in [`test/Dockerfile`](test/Dockerfile). Your Dockerfile
is responsible for the SSH server and the `authorized_keys` entry — the driver
adds nothing to it.

### Building for another architecture

```yaml
platforms:
  - name: ubuntu-24.04
    driver:
      docker_platform: linux/arm64
```

This requires emulation — install QEMU binfmt handlers (`docker run --privileged
--rm tonistiigi/binfmt --install all`) or use a Buildx builder that can reach a
native node.

### Using a remote daemon over TLS

```yaml
driver:
  name: docker
  socket: tcp://docker.example.com:2376
  tls: true
  tls_verify: true
  tls_cacert: ~/.docker/ca.pem
  tls_cert: ~/.docker/cert.pem
  tls_key: ~/.docker/key.pem

transport:
  name: docker
  socket: tcp://docker.example.com:2376
  tls: true
  tls_verify: true
  tls_cacert: ~/.docker/ca.pem
  tls_cert: ~/.docker/cert.pem
  tls_key: ~/.docker/key.pem
```

`build_context` defaults to `false` against a remote daemon, since sending the
whole working directory over the network is slow. Set it to `true` if your
Dockerfile uses `ADD` or `COPY`.

### Windows containers

```yaml
driver:
  name: docker

transport:
  name: docker
  socket: tcp://localhost:2375

platforms:
  - name: windows-2022
    driver:
      image: mcr.microsoft.com/windows/servercore:ltsc2022
      platform: windows
      isolation: hyperv
```

Windows containers have no WinRM service, so `transport: docker` is required
rather than optional. If you use the InSpec verifier on Windows, the named-pipe
socket will not work — the daemon must listen on TCP. Add `hosts` to
`C:\ProgramData\docker\config\daemon.json`:

```json
{
  "hosts": ["tcp://0.0.0.0:2375"]
}
```

### Building behind a proxy

```yaml
driver:
  name: docker
  http_proxy: http://proxy.example.com:8080
  https_proxy: http://proxy.example.com:8080
  no_proxy: localhost,127.0.0.1,.internal.example.com
```

### Linking containers together

Give the container a stable name, then link to it from another suite:

```yaml
suites:
  - name: database
    driver:
      instance_name: db

  - name: web
    driver:
      links:
        - db:db
```

### Running Test Kitchen inside a container

When Test Kitchen itself runs in a container, forwarded host ports are not
reachable. Connect over the Docker network instead:

```yaml
driver:
  name: docker
  use_internal_docker_network: true
```

### Passing flags the driver has no option for

`build_options` and `run_options` are escape hatches, accepting either a raw
string or a map that is expanded into flags:

```yaml
driver:
  build_options:
    rm: false
    build-arg: VERSION=1.2.3
  run_options: --ip=1.2.3.4
```

## Using with Chef

This driver is not tied to Cinc. It builds images and runs containers; it does
not install either distribution — that is the provisioner's job. If you use
[Chef Workstation][chef_workstation] rather than
[Cinc Workstation][cinc_workstation], use `chef_infra` and `inspec`:

```yaml
provisioner:
  name: chef_infra

verifier:
  name: inspec
```

No driver configuration changes are needed.

## Troubleshooting

**The container exits immediately.** `run_command` must stay in the
foreground. A command that forks and returns leaves the container with nothing
running, and Docker stops it.

**`Unknown platform '<name>'`.** The `platform` value is not one the driver can
bootstrap. Set it to a supported family, or supply your own
[`dockerfile`](#using-a-custom-dockerfile).

**`ADD` or `COPY` cannot find a file.** Set `build_context: true`. It defaults
to `false` against a remote daemon.

**Permission denied talking to the daemon.** Either add your user to the
`docker` group, or set `use_sudo: true` under **both** `driver:` and
`transport:` -- the transport runs its own `docker exec` and `docker cp`.

**Anything else.** Run with `-l debug`:

```sh
kitchen converge default-ubuntu-2404 -l debug
```

The debug log contains the generated Dockerfile and the exact `docker build`
and `docker run` command lines, which is usually enough to see what went wrong.

## Contributing

Bug reports and pull requests are welcome on [GitHub][repo]; please report
issues on [GitHub Issues][issues].

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, how to run the
unit and integration tests, and the release process.

## License

Copyright 2013-2016, [Sean Porter](https://github.com/portertech)
Copyright 2015-2016, [Noah Kantrowitz](https://github.com/coderanger)

Licensed under the Apache License, Version 2.0. You may obtain a copy of the
License at <https://www.apache.org/licenses/LICENSE-2.0>. See
[LICENSE](LICENSE) for the full text.

[issues]:              https://github.com/test-kitchen/kitchen-docker/issues
[repo]:                https://github.com/test-kitchen/kitchen-docker
[dokken]:              https://github.com/test-kitchen/kitchen-dokken
[docker_installation]: https://docs.docker.com/engine/install/
[test_kitchen_docs]:   https://kitchen.ci/docs/getting-started/introduction/
[cinc_workstation]:    https://cinc.sh/start/workstation/
[chef_workstation]:    https://www.chef.io/downloads/tools/workstation
