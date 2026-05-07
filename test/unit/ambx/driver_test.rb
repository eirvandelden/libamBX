require_relative "../../test_helper"

describe Ambx::Transport, "#open!" do
  include AmbxTestHelpers

  it "opens and claims all discovered devices" do
    handle = fake_handle
    transport = Ambx::Transport.new(discovery: fake_discovery([ fake_device(handle: handle) ]))

    transport.open!

    _(transport.handles).must_equal [ handle ]
  end

  it "raises when no supported devices are discovered" do
    transport = Ambx::Transport.new(discovery: fake_discovery([]))

    _ { transport.open! }.must_raise Ambx::Error::NoDeviceFound
  end

  it "raises when interface claiming fails" do
    handle = fake_handle(claim_value: nil)
    transport = Ambx::Transport.new(discovery: fake_discovery([ fake_device(handle: handle) ]))

    _ { transport.open! }.must_raise Ambx::Error::ClaimFailed
  end
end

describe Ambx::Transport, "#write" do
  include AmbxTestHelpers

  it "writes packets to every open handle" do
    first = fake_handle
    second = fake_handle
    transport = Ambx::Transport.new(discovery: fake_discovery([]))
    transport.instance_variable_set(:@handles, [ first, second ])

    transport.write(Ambx::Packet.set_light(zone: :left, color: Ambx::Color.rgb(10, 20, 30)))

    _(first.transfers.length).must_equal 1
    _(second.transfers.length).must_equal 1
  end

  it "closes and raises disconnected when a write loses the device" do
    handle = fake_handle(transfer: ->(_options) { raise Errno::ENXIO })
    transport = Ambx::Transport.new(discovery: fake_discovery([]))
    transport.instance_variable_set(:@handles, [ handle ])

    _ { transport.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ]) }.must_raise Ambx::Error::Disconnected
    _(transport.handles).must_be_empty
  end
end

describe Ambx::Session, ".open" do
  include AmbxTestHelpers

  it "opens a transport and exposes the banks" do
    handle = fake_handle
    session = Ambx::Session.open(
      transport: Ambx::Transport.new(discovery: fake_discovery([ fake_device(handle: handle) ]))
    )

    _(session.lights).must_be_instance_of Ambx::LightBank
    _(session.fans).must_be_instance_of Ambx::FanBank
    _(session.brightness).must_be_instance_of Ambx::Brightness
  ensure
    session&.close
  end
end
