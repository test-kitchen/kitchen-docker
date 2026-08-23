# Kitchen-Docker Changelog

Future CHANGELOG notes will be in GitHub release notes

## Unreleased

* Docs: document the last four options and split contributor docs ([#463](https://github.com/test-kitchen/kitchen-docker/pull/463)) ([4818bce](https://github.com/test-kitchen/kitchen-docker/commit/4818bce))

## [3.3.3](https://github.com/test-kitchen/kitchen-docker/compare/v3.3.2...v3.3.3) (2026-08-23)


### Bug Fixes

* detect containers that exist but have stopped ([#476](https://github.com/test-kitchen/kitchen-docker/issues/476)) ([c6c7038](https://github.com/test-kitchen/kitchen-docker/commit/c6c70382f9e7be4a4c27f5f225f72465a3b392a6))

## [3.3.2](https://github.com/test-kitchen/kitchen-docker/compare/v3.3.1...v3.3.2) (2026-08-23)


### Bug Fixes

* escape configured values interpolated into docker command lines ([#471](https://github.com/test-kitchen/kitchen-docker/issues/471)) ([994b0ca](https://github.com/test-kitchen/kitchen-docker/commit/994b0ca9d89bab0501b3946ca45fd177b24bf2bd))
* split printenv output on the first equals sign only ([#473](https://github.com/test-kitchen/kitchen-docker/issues/473)) ([9b0d0d7](https://github.com/test-kitchen/kitchen-docker/commit/9b0d0d784efe4f65c1c6585e19440e90e322b3a1))
* tolerate stderr warnings when parsing docker run container id (rebase of [#452](https://github.com/test-kitchen/kitchen-docker/issues/452)) ([#475](https://github.com/test-kitchen/kitchen-docker/issues/475)) ([a8ad6f6](https://github.com/test-kitchen/kitchen-docker/commit/a8ad6f6e05e927f3966a72ee6029b9f135246565))

## [3.3.1](https://github.com/test-kitchen/kitchen-docker/compare/v3.3.0...v3.3.1) (2026-08-23)


### Bug Fixes

* resolve gemspec load path and refactor proxy config method ([#440](https://github.com/test-kitchen/kitchen-docker/issues/440)) ([28a9b79](https://github.com/test-kitchen/kitchen-docker/commit/28a9b79f1722b3eb0e534623c6a00eb8881a93f6))

## [3.3.0](https://github.com/test-kitchen/kitchen-docker/compare/v3.2.4...v3.3.0) (2026-08-22)

### Features

* Support `kitchen login` with the Docker transport ([#462](https://github.com/test-kitchen/kitchen-docker/issues/462)) ([ba9b75e](https://github.com/test-kitchen/kitchen-docker/commit/ba9b75e8187eea72316dc91dbe3aec41221055bf))

### Other Changes

* Fix typos ([#460](https://github.com/test-kitchen/kitchen-docker/pull/460)) ([66986a3](https://github.com/test-kitchen/kitchen-docker/commit/66986a3))
* Require Ruby 3.1+ and modernize CI ([#461](https://github.com/test-kitchen/kitchen-docker/pull/461)) ([b53e4c5](https://github.com/test-kitchen/kitchen-docker/commit/b53e4c5))

## [3.2.4](https://github.com/test-kitchen/kitchen-docker/compare/v3.2.3...v3.2.4) (2026-07-28)

### Bug Fixes

* Avoid curl conflict with RHEL ubi in dockerfile helper ([#458](https://github.com/test-kitchen/kitchen-docker/issues/458)) ([028ce4c](https://github.com/test-kitchen/kitchen-docker/commit/028ce4c6ebdde7727f0e8aea7ae1a998f73f6eb8))

## [3.2.3](https://github.com/test-kitchen/kitchen-docker/compare/v3.2.2...v3.2.3) (2026-06-25)

### Bug Fixes

* release please configs & tests ([#418](https://github.com/test-kitchen/kitchen-docker/issues/418)) ([9be9d75](https://github.com/test-kitchen/kitchen-docker/commit/9be9d754fd025dd721f1863e23e5502744f5bafb))

### Other Changes

* Update workflows ([#410](https://github.com/test-kitchen/kitchen-docker/issues/410)) ([01acb1e](https://github.com/test-kitchen/kitchen-docker/commit/01acb1e00e45d02f71f70f68903c39d320d962df))
* refactor!: Run chefstlye over the codebase ([#408](https://github.com/test-kitchen/kitchen-docker/pull/408)) ([a9995e7](https://github.com/test-kitchen/kitchen-docker/commit/a9995e7))
* chore(deps): update actions/checkout action to v4 ([#411](https://github.com/test-kitchen/kitchen-docker/pull/411)) ([bd3a992](https://github.com/test-kitchen/kitchen-docker/commit/bd3a992))

* Tell the user when we can't remove the image if it's in use ([#406](https://github.com/test-kitchen/kitchen-docker/issues/406)) ([bcb7c2b](https://github.com/test-kitchen/kitchen-docker/commit/bcb7c2bc5144ec63c6bde7b8947de33d5484e718))

* bump tk dep &lt;5 ([#446](https://github.com/test-kitchen/kitchen-docker/issues/446)) ([f27d137](https://github.com/test-kitchen/kitchen-docker/commit/f27d1374c1efd35769563683c5782849162c4f0c))
* Ignore vendor directory ([#439](https://github.com/test-kitchen/kitchen-docker/issues/439)) ([1c1c6a2](https://github.com/test-kitchen/kitchen-docker/commit/1c1c6a282ba52c2bf48b2ae0b181bc2fb3cf8bab))
* Remove obsolete Arch Linux limits.conf workaround ([#438](https://github.com/test-kitchen/kitchen-docker/issues/438)) ([ed14bc6](https://github.com/test-kitchen/kitchen-docker/commit/ed14bc6e1f95a0d444471c5aed837d9a0c1d852b))
* Remove use of DSA keys due to openssh deprecation ([#427](https://github.com/test-kitchen/kitchen-docker/issues/427)) ([f42bd6c](https://github.com/test-kitchen/kitchen-docker/commit/f42bd6c2930becd1524551b8f412ab934a80a326))
* Support docker build output for Docker Desktop v4.31 ([#423](https://github.com/test-kitchen/kitchen-docker/issues/423)) ([511e4ad](https://github.com/test-kitchen/kitchen-docker/commit/511e4ad36856b9e2eccceb56603586e6cebd296a))
* Use newer syntax for ENV variables ([#424](https://github.com/test-kitchen/kitchen-docker/issues/424)) ([2007a0d](https://github.com/test-kitchen/kitchen-docker/commit/2007a0dcc6461537412dd46084144beb89731d1a))
* fix: published package name ([#415](https://github.com/test-kitchen/kitchen-docker/pull/415)) ([f633d49](https://github.com/test-kitchen/kitchen-docker/commit/f633d49))
* chore(deps): update test-kitchen/.github action to v0.1.2 ([#414](https://github.com/test-kitchen/kitchen-docker/pull/414)) ([057465d](https://github.com/test-kitchen/kitchen-docker/commit/057465d))
* chore(deps): replace google-github-actions/release-please-action action with googleapis/release-please-action ([#432](https://github.com/test-kitchen/kitchen-docker/pull/432)) ([c1ba214](https://github.com/test-kitchen/kitchen-docker/commit/c1ba214))
* chore(deps): update actions/checkout action to v5 ([#430](https://github.com/test-kitchen/kitchen-docker/pull/430)) ([e756c47](https://github.com/test-kitchen/kitchen-docker/commit/e756c47))
* chore(deps): update dependency rspec-its to v2 ([#425](https://github.com/test-kitchen/kitchen-docker/pull/425)) ([9b22526](https://github.com/test-kitchen/kitchen-docker/commit/9b22526))
* chore: Remove EOL operating systems from test matrix ([#435](https://github.com/test-kitchen/kitchen-docker/pull/435)) ([06a6ccf](https://github.com/test-kitchen/kitchen-docker/commit/06a6ccf))
* chore(deps): update dependency kitchen-inspec to v3 ([#428](https://github.com/test-kitchen/kitchen-docker/pull/428)) ([0cfbe46](https://github.com/test-kitchen/kitchen-docker/commit/0cfbe46))
* chore(deps): update googleapis/release-please-action action to v4 ([#433](https://github.com/test-kitchen/kitchen-docker/pull/433)) ([60b83e0](https://github.com/test-kitchen/kitchen-docker/commit/60b83e0))
* chore(deps): update actions/checkout action to v6 ([#443](https://github.com/test-kitchen/kitchen-docker/pull/443)) ([8be39d4](https://github.com/test-kitchen/kitchen-docker/commit/8be39d4))
* chore(deps): update test-kitchen/.github action to v0.2.4 ([#442](https://github.com/test-kitchen/kitchen-docker/pull/442)) ([3490106](https://github.com/test-kitchen/kitchen-docker/commit/3490106))

* Fix curl package conflict in Amazon Linux 2022 images ([#436](https://github.com/test-kitchen/kitchen-docker/issues/436)) ([4eccec9](https://github.com/test-kitchen/kitchen-docker/commit/4eccec928556a1c6fc48e7fcf14de83a9ced5afa))
* chore(deps): update actions/checkout action to v7 ([#453](https://github.com/test-kitchen/kitchen-docker/pull/453)) ([8397e75](https://github.com/test-kitchen/kitchen-docker/commit/8397e75))
* chore(deps): update googleapis/release-please-action action to v5 ([#451](https://github.com/test-kitchen/kitchen-docker/pull/451)) ([aa7ba91](https://github.com/test-kitchen/kitchen-docker/commit/aa7ba91))
* chore(deps): update docker/setup-buildx-action action to v4 ([#449](https://github.com/test-kitchen/kitchen-docker/pull/449)) ([5b0a6dc](https://github.com/test-kitchen/kitchen-docker/commit/5b0a6dc))
* chore(deps): update docker/setup-qemu-action action to v4 ([#448](https://github.com/test-kitchen/kitchen-docker/pull/448)) ([803738e](https://github.com/test-kitchen/kitchen-docker/commit/803738e))

## [3.0.0](https://github.com/test-kitchen/kitchen-docker/compare/v2.15.0...v3.0.0) (2023-11-15)

* Add CI workflow ([#404](https://github.com/test-kitchen/kitchen-docker/pull/404)) ([5b350d9](https://github.com/test-kitchen/kitchen-docker/commit/5b350d9))
* Update workflows ([14c3e93](https://github.com/test-kitchen/kitchen-docker/commit/14c3e93))
* Fix: Switch to buildx builder ([#405](https://github.com/test-kitchen/kitchen-docker/pull/405)) ([e6edb34](https://github.com/test-kitchen/kitchen-docker/commit/e6edb34))
* Prep for 3.0.0 release ([d4b08cd](https://github.com/test-kitchen/kitchen-docker/commit/d4b08cd))

## [2.15.0](https://github.com/test-kitchen/kitchen-docker/compare/v.2.14.0...v2.15.0) (2023-11-13)

* Breaking rockylinux platform out ([#399](https://github.com/test-kitchen/kitchen-docker/pull/399)) ([c6f9206](https://github.com/test-kitchen/kitchen-docker/commit/c6f9206))
* Make sure gawk is installed on opensuse. ([#402](https://github.com/test-kitchen/kitchen-docker/pull/402)) ([fa03ee0](https://github.com/test-kitchen/kitchen-docker/commit/fa03ee0))
* Prep for 2.15.0 release ([65b4743](https://github.com/test-kitchen/kitchen-docker/commit/65b4743))

## 2.14.0 - November 13, 2023

- Make sure the /etc/sudoers.d directory exists by @garethgreenaway in [#397](https://github.com/test-kitchen/kitchen-docker/pull/397)
- Breaking almalinux platform out by @garethgreenaway [#398](https://github.com/test-kitchen/kitchen-docker/pull/398)
- fix: parse_image_id: Process "docker build" output in reverse line order by @terminalmage in [#400](https://github.com/test-kitchen/kitchen-docker/pull/400)
- Allow build temporary Dockerfile in configured custom_dir by @Val in [294](https://github.com/test-kitchen/kitchen-docker/pull/294)

* Prep for release ([14d46a9](https://github.com/test-kitchen/kitchen-docker/commit/14d46a9))
* Update CHANGELOG for 2.14.0 ([d646fb2](https://github.com/test-kitchen/kitchen-docker/commit/d646fb2))

## 2.13.0 - June 10, 2022

- Added CentOSStream and PhotonOS - [@garethgreenaway](https://github.com/garethgreenaway)
- Fixed image parser when output includes a duration timestamp - [@RulerOf](https://github.com/RulerOf)
- Updated the test suites - [@RulerOf](https://github.com/RulerOf)

* Adding CentOSStream and PhotonOS ([#392](https://github.com/test-kitchen/kitchen-docker/pull/392)) ([d3467ff](https://github.com/test-kitchen/kitchen-docker/commit/d3467ff))
* Fix image parser when output includes a duration timestamp ([#390](https://github.com/test-kitchen/kitchen-docker/pull/390)) ([0c9a147](https://github.com/test-kitchen/kitchen-docker/commit/0c9a147))
* Update test suites ([#388](https://github.com/test-kitchen/kitchen-docker/pull/388)) ([36c01ab](https://github.com/test-kitchen/kitchen-docker/commit/36c01ab))

## 2.12.0 - December 22, 2021

- Support Docker BuildKit - [@RulerOf](https://github.com/RulerOf)
- Add new `docker_platform` config to allow specifying architectures - [@RulerOf](https://github.com/RulerOf)

* Use Docker BuildKit, support multiple CPU architectures ([#386](https://github.com/test-kitchen/kitchen-docker/pull/386)) ([9c2edd7](https://github.com/test-kitchen/kitchen-docker/commit/9c2edd7))

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

* Add a maintainer wanted status ([9751a14](https://github.com/test-kitchen/kitchen-docker/commit/9751a14))
* Update kitchen-inspec requirement from ~&gt; 1.1 to ~&gt; 2.0 ([#367](https://github.com/test-kitchen/kitchen-docker/pull/367)) ([e8106a4](https://github.com/test-kitchen/kitchen-docker/commit/e8106a4))
* Added driver option for container isolation ([#351](https://github.com/test-kitchen/kitchen-docker/pull/351)) ([7f45feb](https://github.com/test-kitchen/kitchen-docker/commit/7f45feb))
* Support GPU in docker ([#347](https://github.com/test-kitchen/kitchen-docker/pull/347)) ([f0bce9d](https://github.com/test-kitchen/kitchen-docker/commit/f0bce9d))
* Fix CI tests and move Dockerfile configurations to helper file ([#370](https://github.com/test-kitchen/kitchen-docker/pull/370)) ([d9db4f9](https://github.com/test-kitchen/kitchen-docker/commit/d9db4f9))
* Add support for the `--mount` CLI option ([#363](https://github.com/test-kitchen/kitchen-docker/pull/363)) ([5f77c2c](https://github.com/test-kitchen/kitchen-docker/commit/5f77c2c))
* stop editing /etc/sudoers directly ([#334](https://github.com/test-kitchen/kitchen-docker/pull/334)) ([6b4e552](https://github.com/test-kitchen/kitchen-docker/commit/6b4e552))
* disables docker buildkit (fixes #337) ([#379](https://github.com/test-kitchen/kitchen-docker/pull/379)) ([b45c485](https://github.com/test-kitchen/kitchen-docker/commit/b45c485))
* Updates image_helper for additional output line matching ([#382](https://github.com/test-kitchen/kitchen-docker/pull/382)) ([1e58989](https://github.com/test-kitchen/kitchen-docker/commit/1e58989))
* Upgrade to GitHub-native Dependabot ([#381](https://github.com/test-kitchen/kitchen-docker/pull/381)) ([66cedc4](https://github.com/test-kitchen/kitchen-docker/commit/66cedc4))
* README.md: Fix link to getting-started page ([#383](https://github.com/test-kitchen/kitchen-docker/pull/383)) ([1b33572](https://github.com/test-kitchen/kitchen-docker/commit/1b33572))

## 2.10.0 - Mar 28, 2020

- Switched from require to require_relative to slightly improve load time performance
- Allow for train gem 3.x
- Refactor driver to include Windows support (includes new transport for all supported platforms)

* Allow Multiple Platform Names for Windows ([#345](https://github.com/test-kitchen/kitchen-docker/pull/345)) ([c2f715e](https://github.com/test-kitchen/kitchen-docker/commit/c2f715e))
* Allow train 3.x dev dep ([#358](https://github.com/test-kitchen/kitchen-docker/pull/358)) ([73f88e6](https://github.com/test-kitchen/kitchen-docker/commit/73f88e6))
* Use require_relative instead of require ([#359](https://github.com/test-kitchen/kitchen-docker/pull/359)) ([9b66340](https://github.com/test-kitchen/kitchen-docker/commit/9b66340))
* Update to the latest Ruby releases in Travis ([1726dbf](https://github.com/test-kitchen/kitchen-docker/commit/1726dbf))

## 2.9.0 - Mar 15, 2019

- Add automatic OS detection for amazonlinux, opensuse/leap, and opensuse/tumbleweed
- On Fedora containers uses dnf to setup the OS not yum

* Add support for Amazon Linux ([#323](https://github.com/test-kitchen/kitchen-docker/pull/323)) ([bac1803](https://github.com/test-kitchen/kitchen-docker/commit/bac1803))
* On Fedora install the dependencies with dnf not yum ([#333](https://github.com/test-kitchen/kitchen-docker/pull/333)) ([9009e85](https://github.com/test-kitchen/kitchen-docker/commit/9009e85))
* Add support for the opensuse/leap images ([#322](https://github.com/test-kitchen/kitchen-docker/pull/322)) ([8743b45](https://github.com/test-kitchen/kitchen-docker/commit/8743b45))

## 2.8.0 - Jan 18, 2019

- Add new config option `use_internal_docker_network`, which allows running Docker within Docker. See readme for usage details.
- Resolve errors while loading libraries on archlinux
- Fix failures on Ubuntu 18.04
- Check if image exists before attempting to remove it so we don't fail
- Add oraclelinux platform support
- Prevent `uninitialized constant Kitchen::Driver::Docker::Base64` error by requiring `base64`

* Disable docker caching since I think it's breaking things. ([57a8771](https://github.com/test-kitchen/kitchen-docker/commit/57a8771))
* archlinux must be updated when repos are refreshed ([#307](https://github.com/test-kitchen/kitchen-docker/pull/307)) ([6075eb3](https://github.com/test-kitchen/kitchen-docker/commit/6075eb3))
* Update homepage in gemspec ([#321](https://github.com/test-kitchen/kitchen-docker/pull/321)) ([e1d1d7b](https://github.com/test-kitchen/kitchen-docker/commit/e1d1d7b))
* mkdir /run/sshd in container to support ubuntu 18.04 ([#309](https://github.com/test-kitchen/kitchen-docker/pull/309)) ([fe9fa89](https://github.com/test-kitchen/kitchen-docker/commit/fe9fa89))
* Added support for oraclelinux ([#298](https://github.com/test-kitchen/kitchen-docker/pull/298)) ([37eff91](https://github.com/test-kitchen/kitchen-docker/commit/37eff91))
* Fix bug #314 - check if image exists before remove. ([#315](https://github.com/test-kitchen/kitchen-docker/pull/315)) ([7f5e8dc](https://github.com/test-kitchen/kitchen-docker/commit/7f5e8dc))
* require base64 ([#311](https://github.com/test-kitchen/kitchen-docker/pull/311)) ([2831594](https://github.com/test-kitchen/kitchen-docker/commit/2831594))
* feat: added use_internal_docker_network feature ([#304](https://github.com/test-kitchen/kitchen-docker/pull/304)) ([8f6038d](https://github.com/test-kitchen/kitchen-docker/commit/8f6038d))
* Make sure the travis badge is master ([254058c](https://github.com/test-kitchen/kitchen-docker/commit/254058c))

## 2.7.0

- Support for SUSE-based container images.
- Improved support for build context shipping.
- Changed `use_sudo` to default to `false` in keeping with modern Docker usage.

* Fix Gentoo support ([#230](https://github.com/test-kitchen/kitchen-docker/pull/230)) ([668a028](https://github.com/test-kitchen/kitchen-docker/commit/668a028))
* Use relative paths when passing -f Dockerfile ([#245](https://github.com/test-kitchen/kitchen-docker/pull/245)) ([b2b44ba](https://github.com/test-kitchen/kitchen-docker/commit/b2b44ba))
* Fix ssh_host key generation failure if file already exists ([#253](https://github.com/test-kitchen/kitchen-docker/pull/253)) ([350a698](https://github.com/test-kitchen/kitchen-docker/commit/350a698))
* Docker for Windows socket example ([#255](https://github.com/test-kitchen/kitchen-docker/pull/255)) ([08fbc00](https://github.com/test-kitchen/kitchen-docker/commit/08fbc00))
* Add support for sles and opensuse operating systems. ([#262](https://github.com/test-kitchen/kitchen-docker/pull/262)) ([9eabd01](https://github.com/test-kitchen/kitchen-docker/commit/9eabd01))
* Remove gemnasium badge ([#300](https://github.com/test-kitchen/kitchen-docker/pull/300)) ([69be64f](https://github.com/test-kitchen/kitchen-docker/commit/69be64f))
* Change `use_sudo` to default to false. ([fe3734e](https://github.com/test-kitchen/kitchen-docker/commit/fe3734e))
* Changelog for 2.7.0. ([8714f2a](https://github.com/test-kitchen/kitchen-docker/commit/8714f2a))
* Swap 12.04 for 18.04. ([71218f5](https://github.com/test-kitchen/kitchen-docker/commit/71218f5))
* Drop 18.04 for now, weird issues with sshd. ([8b1e0d0](https://github.com/test-kitchen/kitchen-docker/commit/8b1e0d0))
* Use specific versions for tests. ([6b5a561](https://github.com/test-kitchen/kitchen-docker/commit/6b5a561))
* Possible fix for 18.04 or other debianoids that don't actually use upstart. ([56b5aea](https://github.com/test-kitchen/kitchen-docker/commit/56b5aea))
* Test on recent Ruby. ([f914ed9](https://github.com/test-kitchen/kitchen-docker/commit/f914ed9))
* Also remove 18.04 here too. ([ba57e54](https://github.com/test-kitchen/kitchen-docker/commit/ba57e54))
* Disable Arch linux too for now. ([f54d81a](https://github.com/test-kitchen/kitchen-docker/commit/f54d81a))

## 2.6.0

- Set container name with information from the run so you can identify them
  later on.
- Upgrade to new driver base class structure.

## [2.6.0.rc.0](https://github.com/test-kitchen/kitchen-docker/compare/v2.5.0...v2.6.0.rc.0) (2016-08-14)

* Include the actual license text for ApacheV2. ([d64919b](https://github.com/test-kitchen/kitchen-docker/commit/d64919b))
* More specific versions because RVM makes me sad. ([232e5a8](https://github.com/test-kitchen/kitchen-docker/commit/232e5a8))
* Try caching docker stuff? ([03d1104](https://github.com/test-kitchen/kitchen-docker/commit/03d1104))
* Bundle exec all the things dot guife. ([a853861](https://github.com/test-kitchen/kitchen-docker/commit/a853861))
* Update README.md ([b408e94](https://github.com/test-kitchen/kitchen-docker/commit/b408e94))
* Updates for the README. [ci skip] ([4130893](https://github.com/test-kitchen/kitchen-docker/commit/4130893))
* Add coverage reporting. This is going to be sad. ([ab83071](https://github.com/test-kitchen/kitchen-docker/commit/ab83071))
* env container=docker for debians, ext #192 ([#216](https://github.com/test-kitchen/kitchen-docker/pull/216)) ([6f00783](https://github.com/test-kitchen/kitchen-docker/commit/6f00783))
* De-legacy the driver by switching to the Base base class. ([b6d8a47](https://github.com/test-kitchen/kitchen-docker/commit/b6d8a47))
* Set a default container name that includes a bunch of info to track down what launched the container. Shameless borrowed from kitchen-rackspace. ([bbefea6](https://github.com/test-kitchen/kitchen-docker/commit/bbefea6))
* Be a little less reserved about string length because docker seems to accept longer strings. ([deb1d35](https://github.com/test-kitchen/kitchen-docker/commit/deb1d35))
* Make sure we create an unlocked user now that we aren't setting a password. ([ed387b2](https://github.com/test-kitchen/kitchen-docker/commit/ed387b2))
* Prepping an RC release to soak for a bit. ([20eaca1](https://github.com/test-kitchen/kitchen-docker/commit/20eaca1))
* Changelog for 2.6.0. ([62f4894](https://github.com/test-kitchen/kitchen-docker/commit/62f4894))

## 2.5.0

- [#209](https://github.com/portertech/kitchen-docker/pulls/209) Fix usage with Kitchen rake tasks.
- Add `run_options` and `build_options` configuration.
- [#195](https://github.com/portertech/kitchen-docker/pulls/195) Fix Arch Linux support.
- Fix shell escaping for build paths and SSH keys.

* Support tmpfs mounts without requiring privileged mode ([#212](https://github.com/test-kitchen/kitchen-docker/pull/212)) ([f4badb3](https://github.com/test-kitchen/kitchen-docker/commit/f4badb3))
* Remove the tmpfs config option in favor of a more generic run_options config, and build_options in case something is needed there. ([255e5cf](https://github.com/test-kitchen/kitchen-docker/commit/255e5cf))
* Minor cleanups. ([090c2c3](https://github.com/test-kitchen/kitchen-docker/commit/090c2c3))
* Trying to start on getting CI to be a thing. ([5b245c7](https://github.com/test-kitchen/kitchen-docker/commit/5b245c7))
* Clean up the capabilities test suite. ([f58d170](https://github.com/test-kitchen/kitchen-docker/commit/f58d170))
* Some tweaks to the kitchen config based on #195. ([d0afc76](https://github.com/test-kitchen/kitchen-docker/commit/d0afc76))
* Fix copyright year. ([4982231](https://github.com/test-kitchen/kitchen-docker/commit/4982231))
* Bump to a pre-release version number. ([bf1eca8](https://github.com/test-kitchen/kitchen-docker/commit/bf1eca8))
* Escape the temp file path if needed. Fixes #214. ([fd41ceb](https://github.com/test-kitchen/kitchen-docker/commit/fd41ceb))
* Another minor cleanup. ([f93b21b](https://github.com/test-kitchen/kitchen-docker/commit/f93b21b))
* Copy over the rest of #195. Closes #195. ([bc5dd57](https://github.com/test-kitchen/kitchen-docker/commit/bc5dd57))
* Upgrade OpenSSL on Arch to avoid mismatch errors. ([614b65b](https://github.com/test-kitchen/kitchen-docker/commit/614b65b))
* Some tweaks to make sudo work on all platforms. ([c05dbe9](https://github.com/test-kitchen/kitchen-docker/commit/c05dbe9))
* Update the capabilities test. ([8828cab](https://github.com/test-kitchen/kitchen-docker/commit/8828cab))
* Update the dockerfile tests to include the SSH key. ([e41c7a8](https://github.com/test-kitchen/kitchen-docker/commit/e41c7a8))
* I forgot we need Chef installed for busser to work correctly. ([c02fcff](https://github.com/test-kitchen/kitchen-docker/commit/c02fcff))
* Add inspec integration tests. /cc @chris-rock ([45d5a1e](https://github.com/test-kitchen/kitchen-docker/commit/45d5a1e))
* Fully escape the public key when echo'ing it. ([28f1e17](https://github.com/test-kitchen/kitchen-docker/commit/28f1e17))
* Changelog for 2.5.0. ([9f02e4f](https://github.com/test-kitchen/kitchen-docker/commit/9f02e4f))

## 2.4.0

- [#148](https://github.com/portertech/kitchen-docker/issues/148) Restored support for older versions of Ruby.
- [#149](https://github.com/portertech/kitchen-docker/pulls/149) Handle connecting to a container directly as root.
- [#154](https://github.com/portertech/kitchen-docker/pulls/154) Improve container caching by reordering the build steps.
- [#176](https://github.com/portertech/kitchen-docker/pulls/176) Expose proxy environment variables to the container automatically.
- [#192](https://github.com/portertech/kitchen-docker/pulls/192) Set `$container=docker` for CentOS images.
- [#196](https://github.com/portertech/kitchen-docker/pulls/196) Mutex SSH key generation for use with `kitchen -c`.
- [#192](https://github.com/portertech/kitchen-docker/pulls/192) Don't wait when stopping a container.

* Strip the public_key whitespace ([#167](https://github.com/test-kitchen/kitchen-docker/pull/167)) ([2ae315e](https://github.com/test-kitchen/kitchen-docker/commit/2ae315e))
* Remove Tempfile.create. ([727f4d0](https://github.com/test-kitchen/kitchen-docker/commit/727f4d0))
* Note about docker-machine since boot2docker is being deprecated ([#187](https://github.com/test-kitchen/kitchen-docker/pull/187)) ([f7acd0f](https://github.com/test-kitchen/kitchen-docker/commit/f7acd0f))
* Whitespace cleanup. ([6588c2c](https://github.com/test-kitchen/kitchen-docker/commit/6588c2c))
* Don't wait while stopping a container ([#198](https://github.com/test-kitchen/kitchen-docker/pull/198)) ([6b2c855](https://github.com/test-kitchen/kitchen-docker/commit/6b2c855))
* Prepping a 2.4.0 release at long last. ([8a8e40a](https://github.com/test-kitchen/kitchen-docker/commit/8a8e40a))

## 2.3.0

- `build_context` option (boolean) to enable/disable sending the build
context to Docker.

* updated docker version constraint in readme ([a80b3af](https://github.com/test-kitchen/kitchen-docker/commit/a80b3af))
* Allow disabling the build context. ([#143](https://github.com/test-kitchen/kitchen-docker/pull/143)) ([531ecd1](https://github.com/test-kitchen/kitchen-docker/commit/531ecd1))
* minor cleanup and test build_context config ([5d07ae0](https://github.com/test-kitchen/kitchen-docker/commit/5d07ae0))
* Add docs for build_context. ([#144](https://github.com/test-kitchen/kitchen-docker/pull/144)) ([94cf846](https://github.com/test-kitchen/kitchen-docker/commit/94cf846))
* minor version bump, 2.3.0 ([7687efd](https://github.com/test-kitchen/kitchen-docker/commit/7687efd))

## 2.2.0

- Use a temporary file for each suite instance Docker container
Dockerfile, instead of passing their contents via STDIN. This allows for
the use of commands like ADD and COPY. **Users must now use Docker >= 1.5.0**
- Passwordless suite instance Docker container login (SSH), using a
generated key pair.
- Support for sharing a host device with suite instance Docker containers.
- README YAML highlighting.

* updated changelog ([041b48f](https://github.com/test-kitchen/kitchen-docker/commit/041b48f))
* Fix docs for run_command default ([#140](https://github.com/test-kitchen/kitchen-docker/pull/140)) ([b5972dd](https://github.com/test-kitchen/kitchen-docker/commit/b5972dd))
* README.md: Syntax highlight yaml ([#139](https://github.com/test-kitchen/kitchen-docker/pull/139)) ([cbf76ea](https://github.com/test-kitchen/kitchen-docker/commit/cbf76ea))
* Adding passwordless SSH and fixing some of the spec files ([#141](https://github.com/test-kitchen/kitchen-docker/pull/141)) ([2f1dda3](https://github.com/test-kitchen/kitchen-docker/commit/2f1dda3))
* Add support for --devices argument to docker. ([#135](https://github.com/test-kitchen/kitchen-docker/pull/135)) ([159c13d](https://github.com/test-kitchen/kitchen-docker/commit/159c13d))
* Docker - Build Context Support ([#136](https://github.com/test-kitchen/kitchen-docker/pull/136)) ([bf07ff2](https://github.com/test-kitchen/kitchen-docker/commit/bf07ff2))
* Post merge adjustments, release prep ([#142](https://github.com/test-kitchen/kitchen-docker/pull/142)) ([64586e3](https://github.com/test-kitchen/kitchen-docker/commit/64586e3))
* minor version bump, 2.2.0 ([ebe73ba](https://github.com/test-kitchen/kitchen-docker/commit/ebe73ba))

## 2.1.0

- Use `NUL` instead of `/dev/null` on Windows for output redirection

* Use NUL instead of /dev/null to make it work on Windows ([#122](https://github.com/test-kitchen/kitchen-docker/pull/122)) ([88e3944](https://github.com/test-kitchen/kitchen-docker/commit/88e3944))
* minor version bump, windows nul ([6aa98bf](https://github.com/test-kitchen/kitchen-docker/commit/6aa98bf))

## 2.0.0

- Use Docker `top` and `port` instead of `inspect`
- Don't create the kitchen user if it already exists
- Docker container capabilities options: cap_add, cap_drop
- Docker security profile option (SELinux/AppArmor): security_opt
- wait_for_sshd option (boolean)
- Create `/etc/sudoers.d` if missing
- Fixed option deprecation warnings, require Docker >= 1.2

* Move away from `docker inspect` to avoid spurious output ([#100](https://github.com/test-kitchen/kitchen-docker/pull/100)) ([6864c86](https://github.com/test-kitchen/kitchen-docker/commit/6864c86))
* update privileged flag ([#107](https://github.com/test-kitchen/kitchen-docker/pull/107)) ([73b5352](https://github.com/test-kitchen/kitchen-docker/commit/73b5352))
* update capability flags ([#105](https://github.com/test-kitchen/kitchen-docker/pull/105)) ([e25167c](https://github.com/test-kitchen/kitchen-docker/commit/e25167c))
* Add centos 5 /etc/sudoers.d support ([#102](https://github.com/test-kitchen/kitchen-docker/pull/102)) ([a714406](https://github.com/test-kitchen/kitchen-docker/commit/a714406))
* Fix deprecated -dns argument. Add host support ([#94](https://github.com/test-kitchen/kitchen-docker/pull/94)) ([09bcd6e](https://github.com/test-kitchen/kitchen-docker/commit/09bcd6e))
* Do not fail if the user already exists ([#101](https://github.com/test-kitchen/kitchen-docker/pull/101)) ([e9e8b13](https://github.com/test-kitchen/kitchen-docker/commit/e9e8b13))
* removed excess code, cleaned up cap_*, wait_for_sshd conditional ([ca6dedd](https://github.com/test-kitchen/kitchen-docker/commit/ca6dedd))
* updated readme, move cap_* under privileged ([8adcf53](https://github.com/test-kitchen/kitchen-docker/commit/8adcf53))
* fixed cap_* block style ([d96f6c7](https://github.com/test-kitchen/kitchen-docker/commit/d96f6c7))
* Enable security opt (rebased) ([#118](https://github.com/test-kitchen/kitchen-docker/pull/118)) ([831356f](https://github.com/test-kitchen/kitchen-docker/commit/831356f))
* minor readme edits, escape heading underscores, periods. ([879691e](https://github.com/test-kitchen/kitchen-docker/commit/879691e))
* readme edit, docker version requirement ([8f2fae9](https://github.com/test-kitchen/kitchen-docker/commit/8f2fae9))
* readme edit, bold docker version constraint ([fbd4541](https://github.com/test-kitchen/kitchen-docker/commit/fbd4541))
* readme edit, docker installation link update ([389299e](https://github.com/test-kitchen/kitchen-docker/commit/389299e))

## 1.7.0

- Ensure a container id is set before attempting to inspect a container

* use single quotes for centos platform/release adjustments ([b35dbe5](https://github.com/test-kitchen/kitchen-docker/commit/b35dbe5))
* ensure there is a container id before inspecting a container ([6649630](https://github.com/test-kitchen/kitchen-docker/commit/6649630))
* minor version bump ([a2d6501](https://github.com/test-kitchen/kitchen-docker/commit/a2d6501))

## 1.6.0

- `publish_all` option to publish all ports to the host interface
- `instance_name` option to name the Docker container
- `links` option to link suite instance Docker containers
- `socket` option will now default to ENV `DOCKER_HOST` if set
- Fixed verify dependencies output redirection
- Added `fedora` to platform names
- Support for `gentoo` and `gentoo-paludis` platforms
- Adding sudo rule to `/etc/sudoers.d/#{username}` in addition to `/etc/sudoers`

* tell verify_dependencies to be quieter ([#77](https://github.com/test-kitchen/kitchen-docker/pull/77)) ([4869efb](https://github.com/test-kitchen/kitchen-docker/commit/4869efb))
* gentoo support ([#78](https://github.com/test-kitchen/kitchen-docker/pull/78)) ([35447ea](https://github.com/test-kitchen/kitchen-docker/commit/35447ea))
* Added configuration details for use_sudo ([#95](https://github.com/test-kitchen/kitchen-docker/pull/95)) ([a7e3f48](https://github.com/test-kitchen/kitchen-docker/commit/a7e3f48))
* added "fedora" as a supported platform value ([cd4ebfb](https://github.com/test-kitchen/kitchen-docker/commit/cd4ebfb))
* Support --name and --link and -P options to link  between some containers. ([#92](https://github.com/test-kitchen/kitchen-docker/pull/92)) ([0792a15](https://github.com/test-kitchen/kitchen-docker/commit/0792a15))
* Add ENV['DOCKER_HOST'] as default socket and add docs ([#71](https://github.com/test-kitchen/kitchen-docker/pull/71)) ([7e42958](https://github.com/test-kitchen/kitchen-docker/commit/7e42958))
* default run_command string concatenation ([354c537](https://github.com/test-kitchen/kitchen-docker/commit/354c537))
* test instance_name, publish_all, and links. ([4a87141](https://github.com/test-kitchen/kitchen-docker/commit/4a87141))
* redirect stderr & stdout, write out `sudoers.d/#{username}` ([03b2a30](https://github.com/test-kitchen/kitchen-docker/commit/03b2a30))
* minor version bump ([bdc10b4](https://github.com/test-kitchen/kitchen-docker/commit/bdc10b4))

## [1.5.0](https://github.com/test-kitchen/kitchen-docker/compare/v1.4.0...v1.5.0) (2014-07-09)

* Official CentOS image changed how it does tagging ([#70](https://github.com/test-kitchen/kitchen-docker/pull/70)) ([a44b9bc](https://github.com/test-kitchen/kitchen-docker/commit/a44b9bc))
* minor version bump, centos tagging ([d21213a](https://github.com/test-kitchen/kitchen-docker/commit/d21213a))

## [1.4.0](https://github.com/test-kitchen/kitchen-docker/compare/v1.3.1...v1.4.0) (2014-06-27)

* simple patch to add volumes-from support ([#67](https://github.com/test-kitchen/kitchen-docker/pull/67)) ([844eda9](https://github.com/test-kitchen/kitchen-docker/commit/844eda9))
* Add http proxy and https proxy support to suite containers ([#66](https://github.com/test-kitchen/kitchen-docker/pull/66)) ([30d239f](https://github.com/test-kitchen/kitchen-docker/commit/30d239f))
* dockerfile environment component, dried up proxy option ([a225d1b](https://github.com/test-kitchen/kitchen-docker/commit/a225d1b))
* updated license copyright ([226f377](https://github.com/test-kitchen/kitchen-docker/commit/226f377))
* sshd UsePrivilegeSeparation=no to deal w/ tmpfs, http(s)_proxy applied at run ([2ffd6a0](https://github.com/test-kitchen/kitchen-docker/commit/2ffd6a0))

## [1.3.1](https://github.com/test-kitchen/kitchen-docker/compare/v1.2.1...v1.3.1) (2014-06-05)

* Add support for all the authentication options. ([#63](https://github.com/test-kitchen/kitchen-docker/pull/63)) ([aeebcc8](https://github.com/test-kitchen/kitchen-docker/commit/aeebcc8))
* use underscores for tls options, tls_ ([3d68eb3](https://github.com/test-kitchen/kitchen-docker/commit/3d68eb3))
* tls config option default value white space ([ab1a83f](https://github.com/test-kitchen/kitchen-docker/commit/ab1a83f))
* minor version bump, tls support ([3284b2b](https://github.com/test-kitchen/kitchen-docker/commit/3284b2b))

## [1.2.1](https://github.com/test-kitchen/kitchen-docker/compare/v1.2.0...v1.2.1) (2014-04-24)

* Added necessary requirement to parse socket uri ([#55](https://github.com/test-kitchen/kitchen-docker/pull/55)) ([1506316](https://github.com/test-kitchen/kitchen-docker/commit/1506316))
* patch level bump, ensure uri has been required ([ab4828d](https://github.com/test-kitchen/kitchen-docker/commit/ab4828d))

## [1.2.0](https://github.com/test-kitchen/kitchen-docker/compare/v1.1.0.beta...v1.2.0) (2014-04-21)

* Added custom Dockerfile support ([#53](https://github.com/test-kitchen/kitchen-docker/pull/53)) ([0163c88](https://github.com/test-kitchen/kitchen-docker/commit/0163c88))
* Added support for platform arch ([#46](https://github.com/test-kitchen/kitchen-docker/pull/46)) ([3fcaf72](https://github.com/test-kitchen/kitchen-docker/commit/3fcaf72))
* parallel/concurrency can break container rm, check if container exists ([3f89f57](https://github.com/test-kitchen/kitchen-docker/commit/3f89f57))
* docker "binary" config option, ubuntu 14.04 uses `docker.io`, default serverspec ([310a85f](https://github.com/test-kitchen/kitchen-docker/commit/310a85f))
* document "binary" config option ([8fa842a](https://github.com/test-kitchen/kitchen-docker/commit/8fa842a))
* include chef install for test containers/suites ([c8549d7](https://github.com/test-kitchen/kitchen-docker/commit/c8549d7))
* Add -N flag to ssh-keygen commands ([#51](https://github.com/test-kitchen/kitchen-docker/pull/51)) ([566923f](https://github.com/test-kitchen/kitchen-docker/commit/566923f))

## [1.1.0.beta](https://github.com/test-kitchen/kitchen-docker/compare/v1.0.0...v1.1.0.beta) (2014-03-28)

* added "which" package to rhel/centos provisioning ([289c17c](https://github.com/test-kitchen/kitchen-docker/commit/289c17c))

## [1.0.0](https://github.com/test-kitchen/kitchen-docker/compare/v1.0.0.beta...v1.0.0) (2014-03-28)

* added `use_cache` and `remove_intermediate_containers` config options ([1bfb4a0](https://github.com/test-kitchen/kitchen-docker/commit/1bfb4a0))
* README: update example .kitchen.local.yml ([#45](https://github.com/test-kitchen/kitchen-docker/pull/45)) ([de23db2](https://github.com/test-kitchen/kitchen-docker/commit/de23db2))
* removed `remove_intermediate_containers`, little value, we have the cache ([a1fc991](https://github.com/test-kitchen/kitchen-docker/commit/a1fc991))
* documented `use_cache` ([ca775b5](https://github.com/test-kitchen/kitchen-docker/commit/ca775b5))
* cutting 1.0 \o/ ([6b5d21b](https://github.com/test-kitchen/kitchen-docker/commit/6b5d21b))

## [1.0.0.beta](https://github.com/test-kitchen/kitchen-docker/compare/v0.13.0...v1.0.0.beta) (2014-03-20)

* add documentation for run_command config option ([d3e83df](https://github.com/test-kitchen/kitchen-docker/commit/d3e83df))
* use tk for testing ([cf9907d](https://github.com/test-kitchen/kitchen-docker/commit/cf9907d))
* make the default docker socket apparent in kitchen diagnose output ([a3a60af](https://github.com/test-kitchen/kitchen-docker/commit/a3a60af))
* fix documentation styling for run_command ([3688ace](https://github.com/test-kitchen/kitchen-docker/commit/3688ace))
* minor readme edits, run_command ([ef96495](https://github.com/test-kitchen/kitchen-docker/commit/ef96495))
* readme edits, yaml doesn't need quotes ([fe8eba4](https://github.com/test-kitchen/kitchen-docker/commit/fe8eba4))
* readme, updated docs link, not driver specific ([2165fa8](https://github.com/test-kitchen/kitchen-docker/commit/2165fa8))
* base docker image has been deprecated, use ubuntu ([99a373b](https://github.com/test-kitchen/kitchen-docker/commit/99a373b))
* already assuming ubuntu, let's assume platform --&gt; image ([d0e038a](https://github.com/test-kitchen/kitchen-docker/commit/d0e038a))
* make disabling upstart configurable, disable_upstart, set to false for ubuntu-upstart image ([8639669](https://github.com/test-kitchen/kitchen-docker/commit/8639669))
* specify the docker cli tool in the dependency message ([4683c39](https://github.com/test-kitchen/kitchen-docker/commit/4683c39))
* prepare for a 1.0.0.beta \o/ ([713f8d6](https://github.com/test-kitchen/kitchen-docker/commit/713f8d6))
* document disable_upstart, remove the known issue ([d6f480e](https://github.com/test-kitchen/kitchen-docker/commit/d6f480e))
* readme edit, capitalize distros ([6e2df3d](https://github.com/test-kitchen/kitchen-docker/commit/6e2df3d))

## [0.13.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.12.0...v0.13.0) (2013-12-01)

* run init so container remains accessible after sshd restart ([#28](https://github.com/test-kitchen/kitchen-docker/pull/28)) ([5670fb1](https://github.com/test-kitchen/kitchen-docker/commit/5670fb1))

## [0.12.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.11.0...v0.12.0) (2013-11-29)

* compute use_sudo using socket, chef omnibus up to provisioner, socket nil for visability ([e053859](https://github.com/test-kitchen/kitchen-docker/commit/e053859))

## [0.11.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.10.0...v0.11.0) (2013-11-28)

* options is 3rd argument, fixes #24 ([#26](https://github.com/test-kitchen/kitchen-docker/pull/26)) ([a039b14](https://github.com/test-kitchen/kitchen-docker/commit/a039b14))
* depend on tk 1.0.0.rc.1 ([d7e885f](https://github.com/test-kitchen/kitchen-docker/commit/d7e885f))
* new release, wait_for_sshd() fix ([f66f6aa](https://github.com/test-kitchen/kitchen-docker/commit/f66f6aa))

## [0.10.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.9.0...v0.10.0) (2013-11-19)

* no need for sudo in provision_command ([53b98b3](https://github.com/test-kitchen/kitchen-docker/commit/53b98b3))
* Update to support the docker "hostname" command flag ([#22](https://github.com/test-kitchen/kitchen-docker/pull/22)) ([8f630cd](https://github.com/test-kitchen/kitchen-docker/commit/8f630cd))
* Added option privileged which defaults to false ([#23](https://github.com/test-kitchen/kitchen-docker/pull/23)) ([9284832](https://github.com/test-kitchen/kitchen-docker/commit/9284832))
* pre-release cleanup ([16a8caf](https://github.com/test-kitchen/kitchen-docker/commit/16a8caf))

## [0.9.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.8.1...v0.9.0) (2013-11-15)

* Support remote Docker ([#21](https://github.com/test-kitchen/kitchen-docker/pull/21)) ([c948a6e](https://github.com/test-kitchen/kitchen-docker/commit/c948a6e))

## [0.8.1](https://github.com/test-kitchen/kitchen-docker/compare/v0.8.0...v0.8.1) (2013-10-26)

* <https://github.com/portertech/kitchen-docker/graphs/contributors> ([70a2722](https://github.com/test-kitchen/kitchen-docker/commit/70a2722))
* force /sbin/initctl symlink, minor version bump ([8ccd795](https://github.com/test-kitchen/kitchen-docker/commit/8ccd795))

## [0.8.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.8.0.beta...v0.8.0) (2013-10-26)

* version bump, less boiler plate ([12bad52](https://github.com/test-kitchen/kitchen-docker/commit/12bad52))

## [0.8.0.beta](https://github.com/test-kitchen/kitchen-docker/compare/v0.7.1...v0.8.0.beta) (2013-10-26)

* Add a set of computed defaults for a couple of known platform names. ([#19](https://github.com/test-kitchen/kitchen-docker/pull/19)) ([69185c1](https://github.com/test-kitchen/kitchen-docker/commit/69185c1))
* default_image rewrite, version bump (beta) ([e09f5a5](https://github.com/test-kitchen/kitchen-docker/commit/e09f5a5))

## [0.7.1](https://github.com/test-kitchen/kitchen-docker/compare/v0.7.0...v0.7.1) (2013-10-09)

* keep upstart hack lines grouped ([de80bca](https://github.com/test-kitchen/kitchen-docker/commit/de80bca))

## [0.7.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.6.0...v0.7.0) (2013-10-09)

* /etc/hosts is ro ([#18](https://github.com/test-kitchen/kitchen-docker/pull/18)) ([2f6afa5](https://github.com/test-kitchen/kitchen-docker/commit/2f6afa5))
* no longer can nor should ensure the fqdn resolves ([126f730](https://github.com/test-kitchen/kitchen-docker/commit/126f730))

## [0.6.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.5.0...v0.6.0) (2013-10-07)

* readme edit, your -&gt; the suite ([920cc37](https://github.com/test-kitchen/kitchen-docker/commit/920cc37))
* correct forward symbol typo ([#15](https://github.com/test-kitchen/kitchen-docker/pull/15)) ([3ba8cf2](https://github.com/test-kitchen/kitchen-docker/commit/3ba8cf2))
* tweaks to support the latest docker builds ([4e15329](https://github.com/test-kitchen/kitchen-docker/commit/4e15329))

## [0.5.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.4.0...v0.5.0) (2013-07-19)

* custom provision command(s), version bump ([bb0fde2](https://github.com/test-kitchen/kitchen-docker/commit/bb0fde2))

## [0.4.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.3.0...v0.4.0) (2013-07-17)

* Make sure we have lsb-release installed on debian systems. ([#7](https://github.com/test-kitchen/kitchen-docker/pull/7)) ([0cc1836](https://github.com/test-kitchen/kitchen-docker/commit/0cc1836))
* Adds support for using dockers memory limiter. ([#9](https://github.com/test-kitchen/kitchen-docker/pull/9)) ([83bf71a](https://github.com/test-kitchen/kitchen-docker/commit/83bf71a))
* Add options for cpu shares, custom dns, and data volumes. ([#11](https://github.com/test-kitchen/kitchen-docker/pull/11)) ([bc851fd](https://github.com/test-kitchen/kitchen-docker/commit/bc851fd))
* fixed json parsing, now works w/ "the-stretch" branch ([ff32bf2](https://github.com/test-kitchen/kitchen-docker/commit/ff32bf2))
* unnecessary default config options, readme white space ([ab3e0aa](https://github.com/test-kitchen/kitchen-docker/commit/ab3e0aa))

## [0.3.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.2.0...v0.3.0) (2013-06-24)

* Update test-kitchen dependency to 1.0.0.alpha7 ([#6](https://github.com/test-kitchen/kitchen-docker/pull/6)) ([ecc1db3](https://github.com/test-kitchen/kitchen-docker/commit/ecc1db3))
* specify host (public) ports for forward mappings ([a1d5b8f](https://github.com/test-kitchen/kitchen-docker/commit/a1d5b8f))
* driver config option to remove images, default to false, faster builds ([3305c9f](https://github.com/test-kitchen/kitchen-docker/commit/3305c9f))
* driver version bump ([1c806d5](https://github.com/test-kitchen/kitchen-docker/commit/1c806d5))

## [0.2.0](https://github.com/test-kitchen/kitchen-docker/compare/v0.1.3...v0.2.0) (2013-06-23)

* readme, example .kitchen.local.yml ([584e4d1](https://github.com/test-kitchen/kitchen-docker/commit/584e4d1))
* readme, document forward ([be49379](https://github.com/test-kitchen/kitchen-docker/commit/be49379))
* fixed image id parsing, multiple versions of docker ([51f7364](https://github.com/test-kitchen/kitchen-docker/commit/51f7364))
* fixed container ip parsing, inspect returns an array in newer versions ([038fd2e](https://github.com/test-kitchen/kitchen-docker/commit/038fd2e))
* fixed ip address parsing, IpAddress -&gt; IPAddress :/ ([8e2ac8a](https://github.com/test-kitchen/kitchen-docker/commit/8e2ac8a))
* fixed rm container, need to stop a running container first ([142f05b](https://github.com/test-kitchen/kitchen-docker/commit/142f05b))
* driver version bump ([afeaaf8](https://github.com/test-kitchen/kitchen-docker/commit/afeaaf8))

## [0.1.3](https://github.com/test-kitchen/kitchen-docker/compare/v0.1.2...v0.1.3) (2013-05-15)

* rm contaianer instead of kill, #4 ([71c4e0d](https://github.com/test-kitchen/kitchen-docker/commit/71c4e0d))
* port forwarding, forward: - 22, #3 ([084d98e](https://github.com/test-kitchen/kitchen-docker/commit/084d98e))
* default to base image ([1d643be](https://github.com/test-kitchen/kitchen-docker/commit/1d643be))
* mention upstart issue in readme ([55d39fe](https://github.com/test-kitchen/kitchen-docker/commit/55d39fe))
* minor version bump ([a541275](https://github.com/test-kitchen/kitchen-docker/commit/a541275))

## [0.1.2](https://github.com/test-kitchen/kitchen-docker/compare/v0.1.1...v0.1.2) (2013-05-15)

* improved image support ([977174a](https://github.com/test-kitchen/kitchen-docker/commit/977174a))
* minor version bump ([261e569](https://github.com/test-kitchen/kitchen-docker/commit/261e569))

## [0.1.1](https://github.com/test-kitchen/kitchen-docker/compare/v0.1.1.dev...v0.1.1) (2013-05-15)

* readme, updated links ([d189281](https://github.com/test-kitchen/kitchen-docker/commit/d189281))
* verify_dependencies(), check for `docker` ([6551e7c](https://github.com/test-kitchen/kitchen-docker/commit/6551e7c))
* slowly updating the readme ([2b52278](https://github.com/test-kitchen/kitchen-docker/commit/2b52278))
* require_chef_omnibus defaults to `true` ([5dd6416](https://github.com/test-kitchen/kitchen-docker/commit/5dd6416))
* use config username and password in dockerfile ([fbfd29a](https://github.com/test-kitchen/kitchen-docker/commit/fbfd29a))
* readme, document image and platform ([9ac9dbf](https://github.com/test-kitchen/kitchen-docker/commit/9ac9dbf))
* release something ([f9332f8](https://github.com/test-kitchen/kitchen-docker/commit/f9332f8))

## [0.1.1.dev](https://github.com/test-kitchen/kitchen-docker/compare/v0.1.0.dev...v0.1.1.dev) (2013-05-15)

* dynamic dockerfile ([1bac53b](https://github.com/test-kitchen/kitchen-docker/commit/1bac53b))
* multi-platform support, debian & rhel ([cc71750](https://github.com/test-kitchen/kitchen-docker/commit/cc71750))
* UseDNS=no, ubuntu and centos "platform" aliases, ssh-keygen for rhel ([36ecca3](https://github.com/test-kitchen/kitchen-docker/commit/36ecca3))
* rhel openssh-clients (scp) and no pam ([5b24c5e](https://github.com/test-kitchen/kitchen-docker/commit/5b24c5e))
* roll another dev build ([fe33de9](https://github.com/test-kitchen/kitchen-docker/commit/fe33de9))

## 0.1.0.dev (2013-05-15)

* Initial commit ([b6d11af](https://github.com/test-kitchen/kitchen-docker/commit/b6d11af))
* kitchen driver create ([f4c03cd](https://github.com/test-kitchen/kitchen-docker/commit/f4c03cd))
* create an image, create a container, get its ip, let kitchen do its thing ([5597110](https://github.com/test-kitchen/kitchen-docker/commit/5597110))
* Style guideline updates ([#1](https://github.com/test-kitchen/kitchen-docker/pull/1)) ([5528799](https://github.com/test-kitchen/kitchen-docker/commit/5528799))
* sudo, localhost, chef install, destroy ([dc2a965](https://github.com/test-kitchen/kitchen-docker/commit/dc2a965))
* ensure hostname -f works for node.fqdn ([7b4415f](https://github.com/test-kitchen/kitchen-docker/commit/7b4415f))
* updated gemspec, homepage ([c0f410b](https://github.com/test-kitchen/kitchen-docker/commit/c0f410b))
