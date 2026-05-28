require_relative "../../test_helper"

describe Ambx::Packet do
  it "builds a light packet from a zone and color" do
    packet = Ambx::Packet.set_light(zone: :left, color: Ambx::Color.rgb(100, 150, 200))

    _(packet.to_a).must_equal [ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 100, 150, 200 ]
  end

  it "builds a fan packet with speed in the blue channel" do
    packet = Ambx::Packet.set_fan(side: :right, speed: 128)

    _(packet.to_a).must_equal [ 0xA1, Ambx::Fans::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0, 0, 128 ]
  end

  it "builds a rumble packet" do
    packet = Ambx::Packet.set_rumble(intensity: 64)

    _(packet.to_a).must_equal [ 0xA1, Ambx::Rumbler::KEYBOARD, Ambx::Protocol::SET_LIGHT_COLOR, 0, 0, 64 ]
  end

  it "returns a copy from to_a" do
    packet = Ambx::Packet.set_light(zone: :left, color: Ambx::Color.rgb(1, 2, 3))
    bytes = packet.to_a
    bytes[0] = 0

    _(packet.to_a[0]).must_equal 0xA1
  end
end
