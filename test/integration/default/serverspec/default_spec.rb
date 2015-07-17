require_relative 'spec_helper'

describe file('/etc/passwd') do
  it { should be_file }
end
