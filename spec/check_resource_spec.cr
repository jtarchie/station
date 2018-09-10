require "./spec_helper"

include Station

describe Station::CheckResource do
  context "when given a brand new resource" do
    it "returns the most recent version" do
      resource = Resource.new(
        name: "1ms",
        type: "time",
        source: {"interval" => "1ms"}
      )
      checker = CheckResource.new(resource)
      checker.perform!
      checker.versions.size.should eq 1
    end
  end

  context "when given a previous version" do
  end
end
