class Ambx
  class Session
    attr_reader :brightness, :lights, :fans, :rumble

    def self.open(transport: Transport.new, brightness: Brightness.new)
      transport.open!
      new(transport: transport, brightness: brightness)
    end

    def initialize(transport:, brightness: Brightness.new)
      @transport = transport
      @brightness = brightness
      @lights = LightBank.new(transport: @transport, brightness: @brightness)
      @fans = FanBank.new(transport: @transport)
      @rumble = RumbleDevice.new(transport: @transport)
      @brightness.attach(@lights)
    end

    def close
      @transport.close
    end

    def input_listener(decoder: Input::RotaryDecoder.new)
      Input::Listener.new(transport: @transport, decoder: decoder)
    end
  end
end
