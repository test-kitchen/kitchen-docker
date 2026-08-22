# Contributing to kitchen-docker

Thanks for your interest in improving kitchen-docker. Bug reports, feature requests, and pull requests are all welcome.

## Reporting issues

* Source is hosted on [GitHub](https://github.com/test-kitchen/kitchen-docker).
* Report issues, questions, and feature requests on
  [GitHub Issues](https://github.com/test-kitchen/kitchen-docker/issues).

For bugs, please include:

- the version of kitchen-docker and Test Kitchen you are using
- your Docker version and host platform (Linux, macOS, Windows, or a remote
  daemon)
- your `kitchen.yml`
- the output of the failing command, ideally with `-l debug`

The driver builds an image and then runs a container, so the generated
Dockerfile and the `docker run` command line from a debug run are usually the
most useful things to attach.

## Development setup

```sh
git clone https://github.com/test-kitchen/kitchen-docker.git
cd kitchen-docker
bundle install
```

## Running the tests

```sh
bundle exec rake          # unit tests and linting
bundle exec rake spec     # unit tests only
bundle exec rake style    # Cookstyle / RuboCop only
```

To run a single spec file:

```sh
bundle exec rspec spec/kitchen/driver/docker_spec.rb
```

Many style offenses can be corrected automatically:

```sh
bundle exec cookstyle -a
```

The unit tests assert on the Dockerfile and command lines the driver generates.
They do not talk to a Docker daemon, so they run without Docker installed.

## Manual testing

Because the unit tests only check generated commands, changes that affect image
build or container run should also be exercised against a real daemon.

Worth exercising separately, since they take different paths through the driver:

- **Linux and Windows containers**, which generate different Dockerfiles
- **a remote daemon**, via `socket`, as well as the local default
- **`build_context`**, which changes what is sent to the daemon
- **privileged options** such as `cap_add`, `security_opt`, and `devices`

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster. Update the documentation in `README.md` when you add or change a
configuration option.

## Release process

Releases are handled by the maintainers.

1. Update `lib/kitchen/docker/docker_version.rb` with the new version.
2. Update `CHANGELOG.md`.
3. Merge to `main`; the publish workflow builds the gem and pushes it to
   RubyGems.
