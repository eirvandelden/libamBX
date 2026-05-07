class Ambx
  class RumbleDevice
    def initialize(transport:, packet_class: Packet)
      @transport = transport
      @packet_class = packet_class
    end

    def set(intensity)
      @transport.write(@packet_class.set_rumble(intensity: intensity))
    end
  end
end
