require_relative "test_helper"

module AmbxBrightnessTestHelpers
  def build_light_session
    writes = []
    transport = Object.new
    transport.define_singleton_method(:write) { |packet| writes << packet.to_a }
    brightness = Ambx::Brightness.new
    lights = Ambx::LightBank.new(transport: transport, brightness: brightness)
    fans = Ambx::FanBank.new(transport: transport)
    brightness.attach(lights)

    [ writes, lights, fans, brightness ]
  end
end

describe "Ambx brightness round-trip acceptance" do
  include AmbxBrightnessTestHelpers

  it "restores the original color after dimming and brightening" do
    writes, lights, _fans, brightness = build_light_session

    lights.set(:left, Ambx::Color.rgb(200, 100, 50))
    writes.clear

    brightness.adjust(-10)
    brightness.adjust(10)

    _(writes.last).must_equal [ 0xA1, Ambx::Lights::LEFT, 0x03, 200, 100, 50 ]
  end
end

describe "Ambx brightness replay acceptance" do
  include AmbxBrightnessTestHelpers

  it "does not replay fan writes when brightness changes" do
    writes, _lights, fans, brightness = build_light_session

    fans.set(:left, 200)
    writes.clear

    brightness.adjust(-10)

    _(writes).must_be_empty
  end
end

describe "Ambx multi-light replay acceptance" do
  include AmbxBrightnessTestHelpers

  it "replays every tracked light at the new brightness level" do
    writes, lights, _fans, brightness = build_light_session

    lights.set(:left, Ambx::Color.rgb(100, 0, 0))
    lights.set(:right, Ambx::Color.rgb(0, 100, 0))
    writes.clear

    brightness.adjust(-10)

    _(writes).must_equal [
      [ 0xA1, Ambx::Lights::LEFT, 0x03, 50, 0, 0 ],
      [ 0xA1, Ambx::Lights::RIGHT, 0x03, 0, 50, 0 ]
    ]
  end
end
