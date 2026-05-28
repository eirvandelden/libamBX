require "open3"
require_relative "../../test_helper"

describe "application CLI device error handling" do
  DEVICE_REQUIRED_COMMANDS = [
    [ "applications/ambilight/ambilight.rb" ],
    [ "applications/boblight/boblight.rb" ],
    [ "applications/setcolor/setcolor.rb", "1", "2", "3" ],
    [ "applications/setcolor/setfan.rb", "128" ]
  ].freeze

  def run_script(*command)
    env = { "RUBYLIB" => File.expand_path("../../support/no_usb", __dir__) }
    Open3.capture3(env, RbConfig.ruby, *command, chdir: File.expand_path("../../..", __dir__))
  end

  DEVICE_REQUIRED_COMMANDS.each do |command|
    it "prints a friendly message when #{command.first} cannot find a device" do
      _stdout, stderr, status = run_script(*command)

      _(status.success?).must_equal false
      _(stderr).must_include "Unable to find an ambx device"
      _(stderr).wont_include "Traceback"
    end
  end
end
