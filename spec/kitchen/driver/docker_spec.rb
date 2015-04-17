require 'kitchen/driver/docker'
#require 'kitchen/provisioner/dummy'

describe Kitchen::Driver::Docker do
  let(:driver_object) { Kitchen::Driver::Docker.new(config) }

  let(:driver) do
    d = driver_object
    instance
    d
  end
    let(:instance) do
      Kitchen::Instance.new(
        :platform => double(:name => "centos-6.4"),
        :suite => double(:name => "default"),
        :driver => driver,
        :provisioner => Kitchen::Provisioner::Dummy.new({}),
        :busser => double("busser"),
        :state_file => double("state_file")
      )
    end
  describe "configuration" do
    it "dummy" do
      expect(instance[:platform]).to eq("ubuntu:12.04")
    end
  end
end
