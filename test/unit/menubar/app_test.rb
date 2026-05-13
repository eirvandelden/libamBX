require_relative "../../test_helper"
require_relative "../../../applications/menubar/app"

MENUBAR_TEST_COLORS = [ { "name" => "Warm White", "rgb" => [ 255, 200, 150 ] } ].freeze
MENUBAR_TEST_FAN_SPEEDS = [ { "name" => "Fan: Medium", "speed" => 170 } ].freeze

class MenubarLightSpy
  attr_reader :calls

  def initialize
    @calls = []
  end

  def off
    @calls << [ :off ]
  end

  def set_all(color, green_boost: 1.0)
    @calls << [ :set_all, color.to_a, green_boost ]
  end
end

class MenubarFanSpy
  attr_reader :calls

  def initialize
    @calls = []
  end

  def set_all(speed)
    @calls << [ :set_all, speed ]
  end
end

class MenubarSessionSpy
  attr_reader :lights, :fans, :close_count

  def initialize
    @lights = MenubarLightSpy.new
    @fans = MenubarFanSpy.new
    @close_count = 0
  end

  def close
    @close_count += 1
  end
end

def build_menubar_app(session, green_boost: 1.0)
  Menubar::App.new(
    session_factory: -> { session },
    colors: MENUBAR_TEST_COLORS,
    fan_speeds: MENUBAR_TEST_FAN_SPEEDS,
    green_boost: green_boost
  )
end

describe Menubar::App, "#connection_available?" do
  it "opens and closes a session while probing connection status" do
    session = MenubarSessionSpy.new
    app = build_menubar_app(session)

    _(app.connection_available?).must_equal true
    _(session.close_count).must_equal 1
  end
end

describe Menubar::App, "#handle_selection" do
  it "turns all lights off" do
    session = MenubarSessionSpy.new
    app = build_menubar_app(session)

    connected = app.handle_selection(Menubar::STRINGS[:turn_off], connected: false)

    _(connected).must_equal true
    _(session.lights.calls).must_equal [ [ :off ] ]
    _(session.close_count).must_equal 1
  end

  it "sends a color selection through the session light bank" do
    session = MenubarSessionSpy.new
    app = build_menubar_app(session)

    connected = app.handle_selection("Warm White", connected: false)

    _(connected).must_equal true
    _(session.lights.calls).must_equal [ [ :set_all, [ 255, 200, 150 ], 1.0 ] ]
  end

  it "passes the configured green boost to the light bank on color selection" do
    session = MenubarSessionSpy.new
    app = build_menubar_app(session, green_boost: 2.2)

    app.handle_selection("Warm White", connected: false)

    _(session.lights.calls).must_equal [ [ :set_all, [ 255, 200, 150 ], 2.2 ] ]
  end

  it "sends a fan selection through the session fan bank" do
    session = MenubarSessionSpy.new
    app = build_menubar_app(session)

    connected = app.handle_selection("Fan: Medium", connected: false)

    _(connected).must_equal true
    _(session.fans.calls).must_equal [ [ :set_all, 170 ] ]
  end
end
