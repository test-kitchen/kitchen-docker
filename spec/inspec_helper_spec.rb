require "spec_helper"
require "logger"

RSpec.describe "inspec_helper patches" do
  let(:helper_path) { File.expand_path("../lib/kitchen/docker/helpers/inspec_helper.rb", __dir__) }

  describe "kitchen-inspec patch" do
    # Test actual post-load state rather than trying to stub Kernel.require,
    # which does not intercept require calls made inside a load'd file in Ruby 3.4.
    # The availability check has to happen inside the example: RSpec loads every
    # spec file before running any example, so a load-time `defined?` would be
    # decided by whichever spec file happened to require the verifier first.
    it "patches Kitchen::Verifier::Inspec when the gem is available" do
      load helper_path

      if defined?(Kitchen::Verifier::Inspec)
        expect(Kitchen::Verifier::Inspec.method_defined?(:runner_options_for_docker)).to be true
      else
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
    # Checked inside the example for the same load-order reason as above.
    it "patches Kitchen::Verifier::CincAuditor::TransportOptions when the gem is available" do
      load helper_path

      if defined?(Kitchen::Verifier::CincAuditor::TransportOptions)
        expect(Kitchen::Verifier::CincAuditor::TransportOptions.method_defined?(:build_docker)).to be true
      else
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
