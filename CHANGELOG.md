# Kitchen-Docker Changelog

## 2.6.0

* Set container name with information from the run so you can identify them
  later on.
* Upgrade to new driver base class structure.

## 2.5.0

* [#209](https://github.com/portertech/kitchen-docker/pulls/209) Fix usage with Kitchen rake tasks.
* Add `run_options` and `build_options` configuration.
* [#195](https://github.com/portertech/kitchen-docker/pulls/195) Fix Arch Linux support.
* Fix shell escaping for build paths and SSH keys.

## 2.4.0

* [#148](https://github.com/portertech/kitchen-docker/issues/148) Restored support for older versions of Ruby.
* [#149](https://github.com/portertech/kitchen-docker/pulls/149) Handle connecting to a container directly as root.
* [#154](https://github.com/portertech/kitchen-docker/pulls/154) Improve container caching by reordering the build steps.
* [#176](https://github.com/portertech/kitchen-docker/pulls/176) Expose proxy environment variables to the container automatically.
* [#192](https://github.com/portertech/kitchen-docker/pulls/192) Set `$container=docker` for CentOS images.
* [#196](https://github.com/portertech/kitchen-docker/pulls/196) Mutex SSH key generation for use with `kitchen -c`.
* [#192](https://github.com/portertech/kitchen-docker/pulls/192) Don't wait when stopping a container.

## 2.3.0

* `build_context` option (boolean) to enable/disable sending the build
context to Docker.

## 2.2.0

* Use a temporary file for each suite instance Docker container
Dockerfile, instead of passing their contents via STDIN. This allows for
the use of commands like ADD and COPY. **Users must now use Docker >= 1.5.0**

* Passwordless suite instance Docker container login (SSH), using a
generated key pair.

* Support for sharing a host device with suite instance Docker containers.

* README YAML highlighting.

## 2.1.0

* Use `NUL` instead of `/dev/null` on Windows for output redirection

## 2.0.0

* Use Docker `top` and `port` instead of `inspect`

* Don't create the kitchen user if it already exists

* Docker container capabilities options: cap_add, cap_drop

* Docker security profile option (SELinux/AppArmor): security_opt

* wait_for_sshd option (boolean)

* Create `/etc/sudoers.d` if missing

* Fixed option deprecation warnings, require Docker >= 1.2

## 1.7.0

* Ensure a container id is set before attempting to inspect a container

## 1.6.0

* `publish_all` option to publish all ports to the host interface

* `instance_name` option to name the Docker container

* `links` option to link suite instance Docker containers

* `socket` option will now default to ENV `DOCKER_HOST` if set

* Fixed verify dependencies output redirection

* Added `fedora` to platform names

* Support for `gentoo` and `gentoo-paludis` platforms

* Adding sudo rule to `/etc/sudoers.d/#{username}` in addition to `/etc/sudoers`
