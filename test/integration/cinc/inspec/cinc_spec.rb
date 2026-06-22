describe file("/tmp/cinc-converged") do
  it { should exist }
  its(:content) { should eq "ok\n" }
end

describe command("/opt/cinc/bin/cinc-client --version") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Cinc Client/) }
end
