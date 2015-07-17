require_relative 'spec_helper' 

describe command('sudo /sbin/ifconfig eth0 multicast') do
  its(:exit_status) { should_not eq 0 }
  its(:stdout) { should match /Operation not permitted/ }
end
