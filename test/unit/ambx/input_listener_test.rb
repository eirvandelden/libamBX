require_relative "../../test_helper"

describe Ambx::Input::RotaryDecoder do
  it "returns nil by default when no mappings are configured" do
    _(Ambx::Input::RotaryDecoder.new.decode([ 1, 2, 3 ])).must_be_nil
  end

  it "returns a typed event when bytes match a mapping" do
    decoder = Ambx::Input::RotaryDecoder.new(
      mappings: [ { match: [ 1, 2, 3 ], type: :brightness, delta: 1 } ]
    )

    event = decoder.decode([ 1, 2, 3 ])
    _(event.type).must_equal :brightness
    _(event.delta).must_equal 1
  end
end

describe Ambx::Input::Listener do
  it "dispatches decoded packets to subscribers" do
    transport = Object.new
    packets = Queue.new
    packets << [ 1, 2, 3 ]
    packets << nil
    transport.define_singleton_method(:read_input_packets) do |**_options|
      value = packets.pop
      raise Ambx::Error::Disconnected if value.nil?

      [ value ]
    end

    decoder = Ambx::Input::RotaryDecoder.new(
      mappings: [ { match: [ 1, 2, 3 ], type: :volume, delta: -1 } ]
    )
    received = []
    listener = Ambx::Input::Listener.new(transport: transport, decoder: decoder)
    listener.on(:volume) { |event| received << event.delta }

    listener.start
    sleep(0.01) until received.any?
    listener.stop

    _(received).must_equal [ -1 ]
  end
end
