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
