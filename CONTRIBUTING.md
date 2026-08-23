# Contributing to kitchen-docker

Thanks for your interest in improving kitchen-docker. Bug reports, feature
requests, and pull requests are all welcome.

## Contents

* [Reporting issues](#reporting-issues)
* [Development setup](#development-setup)
* [Running the unit tests](#running-the-unit-tests)
* [Running the integration tests](#running-the-integration-tests)
* [Manual testing](#manual-testing)
* [Code style](#code-style)
* [Documentation](#documentation)
* [Commit messages](#commit-messages)
* [Submitting changes](#submitting-changes)
* [Release process](#release-process)

## Reporting issues

Source is hosted on [GitHub](https://github.com/test-kitchen/kitchen-docker).
Report issues, questions, and feature requests on
[GitHub Issues](https://github.com/test-kitchen/kitchen-docker/issues).

For bugs, please include:

* the version of kitchen-docker and Test Kitchen you are using
* your Docker version and host platform (Linux, macOS, Windows, or a remote
  daemon)
* your `kitchen.yml`
* the output of the failing command, ideally with `-l debug`

The driver builds an image and then runs a container, so the generated
Dockerfile and the `docker run` command line from a debug run are usually the
most useful things to attach.

## Development setup

```sh
git clone https://github.com/test-kitchen/kitchen-docker.git
cd kitchen-docker
bundle install
```

Docker is not needed for the unit tests, only for the integration tests.

## Running the unit tests

```sh
bundle exec rake          # style and unit tests — what CI runs
bundle exec rake test     # unit tests only (alias: rake unit)
bundle exec rake style    # Cookstyle / RuboCop only
```

To run a single spec file, or a single example:

```sh
bundle exec rspec spec/docker_spec.rb
bundle exec rspec spec/docker_spec.rb:42
```

Specs live in `spec/`, in a flat directory rather than mirroring `lib/`.

The unit tests assert on the Dockerfiles and command lines the driver
generates. They do not talk to a Docker daemon, so they run anywhere and take
well under a second. Anything that shells out to `docker` belongs in the
integration tests instead.

Examples run in a random order, and the seed is printed at the end of each run.
If you hit an order-dependent failure, reproduce it with that seed:

```sh
bundle exec rspec --seed 12345
```

## Running the integration tests

The integration tests use Test Kitchen to drive this driver against real
containers, using the `kitchen.yml` in the repository root. They need a working
Docker daemon.

```sh
bundle exec kitchen list                      # every suite/platform combination
bundle exec kitchen test default-ubuntu-2404  # one of them, end to end
bundle exec kitchen converge default-ubuntu-2404   # leave it running to poke at
bundle exec kitchen login default-ubuntu-2404
bundle exec kitchen destroy default-ubuntu-2404
```

The suites each exercise a different path through the driver:

| Suite | What it covers |
| --- | --- |
| `default` | The ordinary path: generated Dockerfile, build, run, converge, verify. |
| `no-build-context` | `build_context: false`, the path taken against a remote daemon. |
| `capabilities` | `cap_drop`, and privilege handling generally. |
| `arm64`, `amd64` | `docker_platform`, i.e. cross-architecture builds under emulation. |
| `inspec` | The InSpec/Cinc Auditor verifier against the Docker transport. |
| `docker-test` | The driver used from within a cookbook, via `test/cookbooks/docker_test`. |

The `dockerfile` platform covers a user-supplied `dockerfile:`, rendered
through ERB — see [`test/Dockerfile`](test/Dockerfile).

Windows containers use a separate configuration and a Windows host:

```sh
KITCHEN_YAML=kitchen.windows.yml bundle exec kitchen test
```

CI runs the full matrix — every suite across roughly eighteen Linux platforms,
plus Windows — on each pull request, after the lint and unit job passes. See
[`.github/workflows/lint.yml`](.github/workflows/lint.yml). Running one or two
suites locally before pushing is usually enough; let CI cover the rest.

## Manual testing

The unit tests only check generated commands, so changes affecting the image
build or container run should also be exercised against a real daemon. These
take meaningfully different paths through the driver and are worth checking
separately:

* **Linux and Windows containers**, which use different container classes and
  generate different Dockerfiles
* **a remote daemon**, via `socket`, as well as the local default — this also
  flips the `build_context` default
* **privileged options** such as `cap_add`, `security_opt`, and `devices`

## Code style

The project uses [Cookstyle](https://github.com/chef/cookstyle), a RuboCop
distribution with Chef's defaults.

```sh
bundle exec rake style
bundle exec rake style:autocorrect      # safe corrections only
bundle exec rake style:autocorrect_all  # includes unsafe corrections
```

## Documentation

Public API documentation is written as [YARD](https://yardoc.org) comments in
`lib/`, and options are documented for users in `README.md`.

```sh
bundle exec rake doc           # generate HTML into doc/
bundle exec rake doc_coverage  # list anything in lib/ still undocumented
```

`rake doc` should complete with no errors and no warnings. Options and the file
list live in `.yardopts`, so a bare `yard` produces exactly what `rake doc`
does.

When you add or change a configuration option, update the relevant table in
`README.md` in the same pull request. If the option needs more than a one-line
explanation, add a worked example to the README's Examples section.

## Commit messages

This project releases with
[release-please](https://github.com/googleapis/release-please), which builds
the changelog and picks the next version from commit messages. They must follow
[Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: support the --gpus flag
fix: quote environment variable values containing spaces
docs: document the transport's TLS options
chore: bump rubocop
```

* `feat:` — a new feature; bumps the minor version.
* `fix:` — a bug fix; bumps the patch version.
* `docs:`, `chore:`, `test:`, `refactor:` — no release on their own.
* `feat!:`, or a `BREAKING CHANGE:` footer — bumps the major version.

Pull request titles matter too: squash-merged commits take the PR title, so it
needs the same prefix.

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster.

## Release process

Releases are automated; maintainers do not bump versions or edit the changelog
by hand.

1. release-please opens and maintains a release pull request against `main`,
   with the next version and the generated changelog entries.
2. Merging that pull request tags the release and updates
   `lib/kitchen/docker/docker_version.rb` and `CHANGELOG.md`.
3. [`.github/workflows/publish.yaml`](.github/workflows/publish.yaml) then
   builds the gem and pushes it to RubyGems.

Configuration lives in `release-please-config.json` and
`.release-please-manifest.json`.
