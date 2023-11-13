# Kitchen-Docker Changelog

## 2.14.0 - November 13, 2023

- Make sure the /etc/sudoers.d directory exists by @garethgreenaway in [#397](https://github.com/test-kitchen/kitchen-docker/pull/397)
- Breaking almalinux platform out by @garethgreenaway [#398](https://github.com/test-kitchen/kitchen-docker/pull/398)
- fix: parse_image_id: Process "docker build" output in reverse line order by @terminalmage in [#400](https://github.com/test-kitchen/kitchen-docker/pull/400)
- Allow build temporary Dockerfile in configured custom_dir by @Val in [294](https://github.com/test-kitchen/kitchen-docker/pull/294)

## 2.13.0 - June 10, 2022

- Added CentOSStream and PhotonOS - [@garethgreenaway](https://github.com/garethgreenaway)
- Fixed image parser when output includes a duration timestamp - [@RulerOf](https://github.com/RulerOf)
- Updated the test suites - [@RulerOf](https://github.com/RulerOf)

## 2.12.0 - December 22, 2021

- Support Docker BuildKit - [@RulerOf](https://github.com/RulerOf)
- Add new `docker_platform` config to allow specifying architectures - [@RulerOf](https://github.com/RulerOf)

## 2.11.0 - July 2, 2021

- Update the development dependency on kitchen-inspec to 2.x
- Retrieve hostname state data after container is launched to avoid failures when `use_internal_docker_network` is set
- Add a new option for setting container isolation. See the readme for additional details
- Support GPUs in containers with a new `gpus` option that takes the same arguments that would be passed to `docker run --gpus`
- suse platform: use system script for ssh key initialization
- Add support for the `--mount` docker CLI option. See the readme for additional details
- Use sudo.d files instead of directly editing the sudoers file
- Allow passing `--tmpfs` entries to the docker run command. See the readme for additional details
- Use less verbose and quicker setup on Gentoo
- Lowercase the instance-name to avoid issues since docker does not allow instance with capital cases
- Fix the error "Could not parse Docker build output for image ID" by improving the output line matching
- Add support for `almalinux` & `rockylinux`

## 2.10.0 - Mar 28, 2020

- Switched from require to require_relative to slightly improve load time performance
- Allow for train gem 3.x
- Refactor driver to include Windows support (includes new transport for all supported platforms)

## 2.9.0 - Mar 15, 2019

- Add automatic OS detection for amazonlinux, opensuse/leap, and opensuse/tumbleweed
- On Fedora containers uses dnf to setup the OS not yum

## 2.8.0 - Jan 18, 2019

- Add new config option `use_internal_docker_network`, which allows running Docker within Docker. See readme for usage details.
- Resolve errors while loading libraries on archlinux
- Fix failures on Ubuntu 18.04
- Check if image exists before attempting to remove it so we don't fail
- Add oraclelinux platform support
- Prevent `uninitialized constant Kitchen::Driver::Docker::Base64` error by requiring `base64`

## 2.7.0

- Support for SUSE-based container images.
- Improved support for build context shipping.
- Changed `use_sudo` to default to `false` in keeping with modern Docker usage.

## 2.6.0

- Set container name with information from the run so you can identify them
  later on.
- Upgrade to new driver base class structure.

## 2.5.0

- [#209](https://github.com/portertech/kitchen-docker/pulls/209) Fix usage with Kitchen rake tasks.
- Add `run_options` and `build_options` configuration.
- [#195](https://github.com/portertech/kitchen-docker/pulls/195) Fix Arch Linux support.
- Fix shell escaping for build paths and SSH keys.

## 2.4.0

- [#148](https://github.com/portertech/kitchen-docker/issues/148) Restored support for older versions of Ruby.
- [#149](https://github.com/portertech/kitchen-docker/pulls/149) Handle connecting to a container directly as root.
- [#154](https://github.com/portertech/kitchen-docker/pulls/154) Improve container caching by reordering the build steps.
- [#176](https://github.com/portertech/kitchen-docker/pulls/176) Expose proxy environment variables to the container automatically.
- [#192](https://github.com/portertech/kitchen-docker/pulls/192) Set `$container=docker` for CentOS images.
- [#196](https://github.com/portertech/kitchen-docker/pulls/196) Mutex SSH key generation for use with `kitchen -c`.
- [#192](https://github.com/portertech/kitchen-docker/pulls/192) Don't wait when stopping a container.

## 2.3.0

- `build_context` option (boolean) to enable/disable sending the build
context to Docker.

## 2.2.0

- Use a temporary file for each suite instance Docker container
Dockerfile, instead of passing their contents via STDIN. This allows for
the use of commands like ADD and COPY. **Users must now use Docker >= 1.5.0**
- Passwordless suite instance Docker container login (SSH), using a
generated key pair.
- Support for sharing a host device with suite instance Docker containers.
- README YAML highlighting.

## 2.1.0

- Use `NUL` instead of `/dev/null` on Windows for output redirection

## 2.0.0

- Use Docker `top` and `port` instead of `inspect`
- Don't create the kitchen user if it already exists
- Docker container capabilities options: cap_add, cap_drop
- Docker security profile option (SELinux/AppArmor): security_opt
- wait_for_sshd option (boolean)
- Create `/etc/sudoers.d` if missing
- Fixed option deprecation warnings, require Docker >= 1.2

## 1.7.0

- Ensure a container id is set before attempting to inspect a container

## 1.6.0

- `publish_all` option to publish all ports to the host interface
- `instance_name` option to name the Docker container
- `links` option to link suite instance Docker containers
- `socket` option will now default to ENV `DOCKER_HOST` if set
- Fixed verify dependencies output redirection
- Added `fedora` to platform names
- Support for `gentoo` and `gentoo-paludis` platforms
- Adding sudo rule to `/etc/sudoers.d/#{username}` in addition to `/etc/sudoers`
