require 'serverspec'

set :backend, :exec
set :backend, :exec

describe file('/etc/passwd') do
  it { should be_file }
end
