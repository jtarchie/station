require "../spec_helper"
require "random/secure"

include Station

describe Station::Actions::GetResource do
  resource = Resource.new(
    name: "echo",
    type: "echo",
    source: {"key" => "value"}
  )
  resource_types = ResourceTypes.new
  resource_types.add("echo", "docker-image", {"repository" => "jtarchie/echo-resource"})
  base_dir = File.expand_path(File.join(__DIR__, "..", "..", "tmp"))

  it "uses the params, source, and version by sticking them in the destination dir" do
    get = Actions::GetResource.new(
      resource: resource,
      destionation_dir: File.join(base_dir, Random::Secure.hex),
      resource_types: resource_types,
      params: {
        "some"    => "value",
        "another" => "important value",
      }
    )
    get.perform!(
      version: {
        "ref" => "abcd123",
      } of String => String
    )
    contents = File.read(File.join(get.destionation_dir, "echo-request"))
    payload = JSON.parse(contents)
    payload.should eq({
      "source" => {
        "key" => "value",
      },
      "version" => {
        "ref" => "abcd123",
      },
      "params" => {
        "some"    => "value",
        "another" => "important value",
      },
    })

    get.version.should eq ({"ref" => "abcd123"})
    get.metadata.size.should eq 1
    get.metadata.first["name"].should eq "timestamp"
    get.metadata.first["value"].to_f.should be <= Time.now.epoch_f
  end

  # TODO: write a test for build params
  #       they haven't been added as that concept does not exist yet
end
