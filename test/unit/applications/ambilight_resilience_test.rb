# cspell:words screencapture
require "open3"
require "fileutils"
require "timeout"
require "tmpdir"
require_relative "../../test_helper"

describe "applications/ambilight/ambilight.rb" do
  def repository_root
    File.expand_path("../../..", __dir__)
  end

  def support_path
    File.expand_path("../../support/transient_capture", __dir__)
  end

  it "continues after a transient screenshot failure" do
    Dir.mktmpdir do |dir|
      writes_path = File.join(dir, "writes.log")
      bin_path = File.join(dir, "bin")
      FileUtils.mkdir_p(bin_path)
      File.write(File.join(bin_path, "screencapture"), "#!/bin/sh\nexit 0\n")
      FileUtils.chmod(0o755, File.join(bin_path, "screencapture"))
      env = {
        "AMBX_WRITES_FILE" => writes_path,
        "PATH" => "#{bin_path}:#{ENV.fetch("PATH")}",
        "RUBYLIB" => support_path
      }

      Open3.popen3(env, RbConfig.ruby, "applications/ambilight/ambilight.rb", chdir: repository_root) do |_stdin, _stdout, stderr, wait_thread|
        wait_for_light_writes(writes_path, wait_thread)
        Process.kill("TERM", wait_thread.pid)
        wait_thread.value

        _(File.readlines(writes_path).length).must_be :>=, 5
        _(stderr.read).must_include "Error: transient capture failure"
      ensure
        Process.kill("TERM", wait_thread.pid) if wait_thread&.alive?
      end
    end
  end

  def wait_for_light_writes(writes_path, wait_thread)
    Timeout.timeout(2) do
      loop do
        return if File.exist?(writes_path) && File.readlines(writes_path).length >= 5

        raise "ambilight exited before writing lights" unless wait_thread.alive?

        sleep 0.05
      end
    end
  end
end
