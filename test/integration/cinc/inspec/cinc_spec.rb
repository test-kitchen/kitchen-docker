file_path = if os.windows?
              "C:/cinc-converged"
            else
              "/tmp/cinc-converged"
            end

describe file(file_path) do
  it { should exist }
  its(:content) { should eq "ok\n" }
end

cinc_cmd = if os.windows?
             'C:\cinc-project\cinc\bin\cinc-client --version'
           else
             "/opt/cinc/bin/cinc-client --version"
           end

describe command(cinc_cmd) do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Cinc Client/) }
end
