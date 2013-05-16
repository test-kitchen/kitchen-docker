# <a name="title"></a> Kitchen::Docker

A Test Kitchen Driver for Docker.

## <a name="requirements"></a> Requirements

* [Docker][docker_getting_started]

## <a name="issues"></a> Known Issues

* Upstart is neutered due to [this issue][docker_upstart_issue].

## <a name="installation"></a> Installation and Setup

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

## <a name="config"></a> Configuration

### <a name="config-image"></a> image

The Docker image to use as the base for the suite containers. You can find
images using the [Docker Index][docker_index].

The default value is `base`, an official Ubuntu [image][docker_default_image].

### <a name="config-platform"></a> platform

The platform of the chosen image. This is used to properly bootstrap the
suite container for Test Kitchen. Kitchen Docker currently supports:

* `debian` or `ubuntu`
* `rhel` or `centos`

The default value is `ubuntu`.

### <a name="config-require-chef-omnibus"></a> require\_chef\_omnibus

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

## <a name="development"></a> Development

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

## <a name="authors"></a> Authors

Created and maintained by [Sean Porter][author] (<portertech@gmail.com>)

## <a name="license"></a> License

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
