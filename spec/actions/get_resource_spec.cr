require "../spec_helper"
require "random/secure"

include Station

describe Station::Actions::GetResource do
  resource = Resource.new(
    name: "echo",
    type: "echo",
    source: {"key" => "value"}
  )
  base_dir = File.expand_path(File.join(__DIR__, "..", "..", "tmp"))

  it "uses a destination directory" do
    get = Actions::GetResource.new(
      resource: resource,
      destionation_dir: File.join(base_dir, Random::Secure.hex),
      params: {} of String => String
    )
    get.perform!(
      version: {
        "ref" => "abcd123"
      } of String => String
    )
    contents = File.read(File.join(get.destionation_dir, "version"))
    contents.chomp.should eq %q[{ "ref": "abcd123" }].chomp
  end

  it "uses the params" do

  end
  it "uses the version provided" do

  end
  it "uses source" do

  end
end
