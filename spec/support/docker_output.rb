#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Output captured from real `docker` invocations.
#
# The driver's parsers are the part of this gem most exposed to change outside
# it: Docker has rewritten its build output at least three times, and each
# rewrite has broken image-id parsing. Inventing plausible-looking output tests
# nothing, because a parser written against an invented format will happily
# agree with it. These strings are copied from actual runs, and the version that
# produced each one is recorded, so the suite says what it is compatible with.
module DockerOutput
  # `docker build` on Docker 29.7.2 with BuildKit and BUILDKIT_PROGRESS=plain,
  # which is how ImageHelper#build_image invokes it.
  #
  # Note there is no "writing image" line: BuildKit stopped emitting one, and
  # the id now appears only in the "naming to moby-dangling@" line.
  BUILD_29_7_BUILDKIT = <<~OUTPUT.freeze
    #1 [internal] load build definition from Dockerfile-kitchen
    #1 transferring dockerfile: 92B done
    #1 DONE 0.0s

    #2 [internal] load metadata for docker.io/library/alpine:3.20
    #2 DONE 0.0s

    #5 [1/2] FROM docker.io/library/alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
    #5 resolve docker.io/library/alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc done
    #5 DONE 0.3s

    #6 [2/2] RUN echo hello
    #6 0.085 hello
    #6 DONE 0.1s

    #6 exporting to image
    #6 exporting layers 0.0s done
    #6 exporting manifest sha256:11bf8269eec601a760f884a563cf714dd02eacc5f1e6cd598cc49c3a031dab0f done
    #6 exporting config sha256:30ca0fb0b01c490a57ae08f426919a7ca3f69737085b28d47847427dbce4e7c2 done
    #6 exporting attestation manifest sha256:530b259bbff0d8c05488739e6fff58a482596104bd8ca6bdb640f1687fe7e6bf done
    #6 exporting manifest list sha256:aba3aa20a98ea7578c1b41b4e5b17c71e64d1b7eccd5a4242d3f3956c327d8d4 done
    #6 naming to moby-dangling@sha256:aba3aa20a98ea7578c1b41b4e5b17c71e64d1b7eccd5a4242d3f3956c327d8d4 done
    #6 unpacking to moby-dangling@sha256:aba3aa20a98ea7578c1b41b4e5b17c71e64d1b7eccd5a4242d3f3956c327d8d4 done
    #6 DONE 0.0s
  OUTPUT

  # The image id in BUILD_29_7_BUILDKIT. Verified runnable: `docker run` accepts
  # it, so this really is the id the driver should carry into `state[:image_id]`.
  BUILD_29_7_IMAGE_ID = "sha256:aba3aa20a98ea7578c1b41b4e5b17c71e64d1b7eccd5a4242d3f3956c327d8d4".freeze

  # BuildKit as it emitted the id before the "naming to moby-dangling" form.
  BUILD_BUILDKIT_WRITING_IMAGE = <<~OUTPUT.freeze
    #8 exporting to image
    #8 exporting layers 0.4s done
    #8 writing image sha256:9d3a1b2c4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9 0.0s done
    #8 naming to docker.io/library/kitchen-docker done
    #8 DONE 0.5s
  OUTPUT

  BUILD_BUILDKIT_WRITING_IMAGE_ID =
    "sha256:9d3a1b2c4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9".freeze

  # The pre-BuildKit builder, still reachable with DOCKER_BUILDKIT=0.
  BUILD_LEGACY = <<~OUTPUT.freeze
    Step 3/3 : RUN echo hello
     ---> Running in 4f2c1a9b8e7d
    hello
    Removing intermediate container 4f2c1a9b8e7d
     ---> 1a2b3c4d5e6f
    Successfully built 1a2b3c4d5e6f
  OUTPUT

  BUILD_LEGACY_IMAGE_ID = "1a2b3c4d5e6f".freeze

  # `docker run -d`, the ordinary case: the id and nothing else.
  RUN_CONTAINER_ID = "b89e1e8b07664a1ee0bd09decb833146eaf9cc810a152950e3576a56745944db".freeze
  RUN_CLEAN = "#{RUN_CONTAINER_ID}\n".freeze

  # `docker run -d` when the image is not cached locally. Every line after the
  # id went to stderr, and CliHelper#run_command returns stdout + stderr, so
  # this whole string is what the container-id parser is handed.
  #
  # Captured from Docker 29.7.2.
  RUN_WITH_PULL_ON_STDERR = <<~OUTPUT.freeze
    #{RUN_CONTAINER_ID}
    Unable to find image 'alpine:3.20' locally
    3.20: Pulling from library/alpine
    25f1d6b1951a: Pulling fs layer
    25f1d6b1951a: Pull complete
    Digest: sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
    Status: Downloaded newer image for alpine:3.20
  OUTPUT

  # The warning Docker emits on `run` on hosts whose kernel lacks swap
  # accounting -- the default on Ubuntu. It goes to stderr, so it too is
  # concatenated onto the container id.
  RUN_WITH_SWAP_WARNING = "#{RUN_CONTAINER_ID}\nWARNING: No swap limit support\n".freeze

  # `docker port <container> 22/tcp` on a dual-stack daemon. Docker 29.7.2.
  PORT_DUAL_STACK = "0.0.0.0:52239\n[::]:52239\n".freeze

  # The same, on a daemon publishing only on IPv6.
  PORT_IPV6_ONLY = "[::]:52239\n".freeze

  PORT_IPV4_ONLY = "0.0.0.0:52239\n".freeze

  PUBLISHED_PORT = 52_239
end
