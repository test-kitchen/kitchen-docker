user "notroot" do
  home "/home/notroot"
  manage_home true
  action :create
end

package %w{
  gcc-c++
  gcc
  git
  iputils
  libffi
  libffi-devel
  make
  net-tools
  nmap
  procps-ng
  redhat-rpm-config
  ruby
  ruby-devel
  rubygem-bundler
  rubygem-io-console
  rubygem-rake
  telnet
  which
}

docker_service "default" do
  host ["tcp://127.0.0.1"]
  action %i{create start}
end

git "/home/notroot/kitchen-docker" do
  repository "/opt/kitchen-docker/.git"
  revision node["docker_test"]["revision"]
  user "notroot"
  action :sync
end

execute "install gem bundle" do
  command "/usr/bin/bundle install --without development --path vendor/bundle"
  cwd "/home/notroot/kitchen-docker"
  user "notroot"
  live_stream false
  creates "/home/notroot/kitchen-docker/Gemfile.lock"
  environment "HOME" => "/home/notroot"
  action :run
end

execute "Test Kitchen verify hello" do
  command <<-EOH.gsub(/^\s{4}/, "").chomp
    /usr/bin/bundle exec kitchen create hello -l debug
    /usr/bin/bundle exec kitchen converge hello -l debug
    /usr/bin/bundle exec kitchen verify hello -l debug
  EOH
  cwd "/home/notroot/kitchen-docker"
  user "notroot"
  live_stream true
  environment "PATH" => "/usr/bin:/usr/local/bin:/home/notroot/bin",
    "HOME" => "/home/notroot",
    "DOCKER_HOST" => "tcp://127.0.0.1:2375",
    "CHEF_LICENSE" => "accept-no-persist"
  action :run
end

execute "destroy hello again suite" do
  command "/usr/bin/bundle exec kitchen destroy helloagain"
  cwd "/home/notroot/kitchen-docker"
  user "notroot"
  live_stream true
  environment "PATH" => "/usr/bin:/usr/local/bin:/home/notroot/bin",
    "HOME" => "/home/notroot",
    "DOCKER_HOST" => "tcp://127.0.0.1:2375"
  action :run
end

docker_tag "local-example" do
  target_repo "fedora"
  target_tag "latest"
  to_repo "local-example"
  to_tag "latest"
end

execute "Test Kitchen verify without image pull" do
  command "/usr/bin/bundle exec kitchen test local_image -l debug"
  cwd "/home/notroot/kitchen-docker"
  user "notroot"
  live_stream true
  environment "PATH" => "/usr/bin:/usr/local/bin:/home/notroot/bin",
    "HOME" => "/home/notroot",
    "DOCKER_HOST" => "tcp://127.0.0.1:2375",
    "CHEF_LICENSE" => "accept-no-persist"
  action :run
end
