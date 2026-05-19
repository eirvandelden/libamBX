require "open3"
require "tmpdir"
require_relative "../../test_helper"

describe "applications/menubar/build/build-app.sh" do
  let(:build_script) { File.expand_path("../../../applications/menubar/build/build-app.sh", __dir__) }
  let(:source) { File.read(build_script) }

  it "uses the current ruby interpreter rather than /usr/bin/ruby" do
    _(source).must_include 'RUBY_INTERPRETER="$(which ruby)"'
    _(source).wont_include '--interpreter "/usr/bin/ruby"'
  end

  it "vendors a standalone bundle into the app" do
    _(source).must_include "bundle install --standalone --path applications/menubar/build/vendor/bundle"
    _(source).must_include '--bundled-file "./vendor/bundle"'
  end

  it "resolves REPO_ROOT three levels up from the build directory" do
    _(source).must_include 'REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"'
  end

  it "bundles libambx from the repository root" do
    _(source).must_include '--bundled-file "../../../libambx"'
  end

  it "bundles all required support files" do
    %w[app.rb boot.rb brightness_actions.rb macos_volume.rb].each do |file|
      _(source).must_include "--bundled-file \"../#{file}\""
    end
  end

  it "keeps stdout and stderr unbuffered for Platypus status menu updates" do
    script = File.read(File.expand_path("../../../applications/menubar/menubar.rb", __dir__))

    _(script).must_include "$stdout.sync = true"
    _(script).must_include "$stderr.sync = true"
  end

  it "documents every support file required by the manual Platypus build" do
    manual = File.read(File.expand_path("../../../applications/menubar/build/BUILD_MANUAL.md", __dir__))

    %w[app.rb boot.rb brightness_actions.rb macos_volume.rb].each do |file|
      _(manual).must_include "applications/menubar/#{file}"
    end
  end

  it "has executable permissions" do
    _(File.stat(build_script).mode & 0o111).wont_equal 0
  end
end
