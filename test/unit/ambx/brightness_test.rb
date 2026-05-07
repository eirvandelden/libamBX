require_relative "../../test_helper"

describe Ambx::Brightness do
  it "clamps the brightness level to the valid range" do
    brightness = Ambx::Brightness.new

    brightness.level = 5.0
    _(brightness.level).must_equal 1.0

    brightness.level = -1.0
    _(brightness.level).must_equal 0.0
  end

  it "replays stored light colors when the level changes" do
    transport = Object.new
    writes = []
    transport.define_singleton_method(:write) { |packet| writes << packet.to_a }
    brightness = Ambx::Brightness.new
    lights = Ambx::LightBank.new(transport: transport, brightness: brightness)
    brightness.attach(lights)

    lights.set(:left, Ambx::Color.rgb(200, 100, 50))
    writes.clear

    brightness.adjust(-10)
    _(writes.last).must_equal [ 0xA1, Ambx::Lights::LEFT, 0x03, 100, 50, 25 ]

    brightness.adjust(10)
    _(writes.last).must_equal [ 0xA1, Ambx::Lights::LEFT, 0x03, 200, 100, 50 ]
  end
end
