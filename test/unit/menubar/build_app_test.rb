require "open3"
require "tmpdir"
require_relative "../../test_helper"

describe "applications/menubar/build/build-app.sh" do
  let(:build_script) { File.expand_path("../../../applications/menubar/build/build-app.sh", __dir__) }

  it "uses the current ruby interpreter rather than /usr/bin/ruby" do
    source = File.read(build_script)

    _(source).must_include 'RUBY_INTERPRETER="$(which ruby)"'
    _(source).wont_include '--interpreter "/usr/bin/ruby"'
  end

  it "vendors a standalone bundle into the app" do
    source = File.read(build_script)

    _(source).must_include 'bundle install --standalone --path applications/menubar/build/vendor/bundle'
    _(source).must_include '--bundled-file "./vendor/bundle"'
  end
end
