require "spec_helper"
require "logger"

RSpec.describe "inspec_helper patches" do
  # From spec/, one level up reaches the project root
  let(:helper_path) { File.expand_path("../lib/kitchen/docker/helpers/inspec_helper.rb", __dir__) }

  describe "kitchen-inspec patch" do
    context "when kitchen-inspec is available" do
      before do
        stub_const("Kitchen::Verifier::Inspec", Class.new do
          def logger; Logger.new(IO::NULL); end
        end)
        allow(Kernel).to receive(:require).and_call_original
        # No-op: the constant is already stubbed above
        allow(Kernel).to receive(:require).with("kitchen/verifier/inspec").and_return(true)
        # Prevent the cinc_auditor block from having side effects in this context
        allow(Kernel).to receive(:require).with("kitchen/verifier/cinc_auditor").and_raise(LoadError)
        load helper_path
      end

      it "adds runner_options_for_docker to Kitchen::Verifier::Inspec" do
        instance = Kitchen::Verifier::Inspec.new
        state = { container_id: "abc123" }
        opts = instance.runner_options_for_docker(state)
        expect(opts["backend"]).to eq("docker")
        expect(opts["host"]).to eq("abc123")
      end
    end

    context "when kitchen-inspec is not available" do
      before do
        allow(Kernel).to receive(:require).and_call_original
        allow(Kernel).to receive(:require).with("kitchen/verifier/inspec").and_raise(LoadError)
        allow(Kernel).to receive(:require).with("kitchen/verifier/cinc_auditor").and_raise(LoadError)
      end

      it "does not raise when loading the helper" do
        expect { load helper_path }.not_to raise_error
      end
    end
  end

  describe "kitchen-cinc-auditor patch" do
    context "when kitchen-cinc-auditor is available" do
      before do
        transport_opts_class = Class.new do
          def logger; Logger.new(IO::NULL); end
        end
        stub_const("Kitchen::Verifier::CincAuditor", Module.new)
        stub_const("Kitchen::Verifier::CincAuditor::TransportOptions", transport_opts_class)
        allow(Kernel).to receive(:require).and_call_original
        # Prevent the inspec block from having side effects in this context
        allow(Kernel).to receive(:require).with("kitchen/verifier/inspec").and_raise(LoadError)
        # No-op: the constants are already stubbed above
        allow(Kernel).to receive(:require).with("kitchen/verifier/cinc_auditor").and_return(true)
        load helper_path
      end

      it "adds build_docker to Kitchen::Verifier::CincAuditor::TransportOptions" do
        instance = Kitchen::Verifier::CincAuditor::TransportOptions.new
        state = { container_id: "def456" }
        opts = instance.build_docker(state)
        expect(opts["backend"]).to eq("docker")
        expect(opts["host"]).to eq("def456")
      end
    end

    context "when kitchen-cinc-auditor is not available" do
      before do
        allow(Kernel).to receive(:require).and_call_original
        allow(Kernel).to receive(:require).with("kitchen/verifier/inspec").and_raise(LoadError)
        allow(Kernel).to receive(:require).with("kitchen/verifier/cinc_auditor").and_raise(LoadError)
      end

      it "does not raise when loading the helper" do
        expect { load helper_path }.not_to raise_error
      end
    end
  end
end
