name "kitchen-docker"

default_source "https://supermarket.chef.io"

run_list "cinc_test::default"

named_run_list :docker_test, "docker_test::default"

cookbook "docker_test", path: "test/cookbooks/docker_test"
cookbook "cinc_test", path: "test/cookbooks/cinc_test"
