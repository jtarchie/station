require "./spec_helper"

include Station

describe Station::ResourceTypes do
  it "supports the standard concourse types" do
    types = ResourceTypes.new
    types.repository("time").should eq "concourse/time-resource:latest"
    types.repository("git").should eq "concourse/git-resource:latest"
  end

  it "allows custom resource type" do
    types = ResourceTypes.new
    types.add(
      name: "pull-request",
      type: "docker-image",
      source: {
        "repository" => "jtarchie/pr",
      }
    )
    types.repository("time").should eq "concourse/time-resource:latest"
    types.repository("git").should eq "concourse/git-resource:latest"
    types.repository("pull-request").should eq "jtarchie/pr:latest"
  end

  it "allows custom resource type and tag" do
    types = ResourceTypes.new
    types.add(
      name: "pull-request",
      type: "docker-image",
      source: {
        "repository" => "jtarchie/pr",
        "tag"        => "testing",
      }
    )
    types.repository("time").should eq "concourse/time-resource:latest"
    types.repository("git").should eq "concourse/git-resource:latest"
    types.repository("pull-request").should eq "jtarchie/pr:testing"
  end

  it "allows custom resource types to override defaults" do
    types = ResourceTypes.new
    types.add(
      name: "time",
      type: "docker-image",
      source: {
        "repository" => "jtarchie/time",
        "tag"        => "testing",
      }
    )
    types.repository("time").should eq "jtarchie/time:testing"
    types.repository("git").should eq "concourse/git-resource:latest"
  end
end
