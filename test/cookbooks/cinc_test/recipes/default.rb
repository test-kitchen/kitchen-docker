file_path = if windows?
              "C:/cinc-converged"
            else
              "/tmp/cinc-converged"
            end

file file_path do
  content "ok\n"
  mode "0644"
end
