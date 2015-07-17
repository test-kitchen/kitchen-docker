## 2.2.0

* Use a temporary file for each suite instance docker container
Dockerfile, instead of passing their contents via STDIN. This allows for
the use of commands like ADD and COPY.

* Passwordless container login (SSH), using a generated key pair.

* Support for sharing a host device with suite instance docker containers.

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

* `instance_name` option to name the docker container

* `links` option to link suite instance docker containers

* `socket` option will now default to ENV `DOCKER_HOST` if set

* Fixed verify dependencies output redirection

* Added `fedora` to platform names

* Support for `gentoo` and `gentoo-paludis` platforms

* Adding sudo rule to `/etc/sudoers.d/#{username}` in addition to `/etc/sudoers`
