class Ambx
  class FanBank
    SIDES = %i[left right].freeze

    def initialize(transport:, packet_class: Packet)
      @transport = transport
      @packet_class = packet_class
    end

    def set(side, speed)
      @transport.write(@packet_class.set_fan(side: side, speed: speed))
    end

    def set_all(speed)
      SIDES.each do |side|
        set(side, speed)
      end
    end
  end
end
