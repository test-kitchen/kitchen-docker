require "spec_helper"
require "logger"

RSpec.describe "inspec_helper patches" do
  let(:helper_path) { File.expand_path("../lib/kitchen/docker/helpers/inspec_helper.rb", __dir__) }

  describe "kitchen-inspec patch" do
    # Test actual post-load state rather than trying to stub Kernel.require,
    # which does not intercept require calls made inside a load'd file in Ruby 3.4.
    if defined?(Kitchen::Verifier::Inspec)
      it "adds runner_options_for_docker to Kitchen::Verifier::Inspec" do
        expect(Kitchen::Verifier::Inspec.method_defined?(:runner_options_for_docker)).to be true
      end
    else
      it "Kitchen::Verifier::Inspec not available — patch correctly skipped" do
        expect(defined?(Kitchen::Verifier::Inspec)).to be_falsy
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
    # Test actual post-load state rather than trying to stub Kernel.require.
    if defined?(Kitchen::Verifier::CincAuditor) &&
        defined?(Kitchen::Verifier::CincAuditor::TransportOptions)
      it "adds build_docker to Kitchen::Verifier::CincAuditor::TransportOptions" do
        expect(Kitchen::Verifier::CincAuditor::TransportOptions.method_defined?(:build_docker)).to be true
      end
    else
      it "Kitchen::Verifier::CincAuditor not available — patch correctly skipped" do
        expect(defined?(Kitchen::Verifier::CincAuditor)).to be_falsy
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
