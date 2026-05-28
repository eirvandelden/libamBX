class Ambx
  class Packet
    attr_reader :bytes

    def self.set_light(zone:, color:)
      new([
        0xA1,
        Protocol::LIGHT_IDS.fetch(zone),
        Protocol::SET_LIGHT_COLOR,
        *color.to_a
      ])
    end

    def self.set_fan(side:, speed:)
      new([
        0xA1,
        Protocol::FAN_IDS.fetch(side),
        Protocol::SET_LIGHT_COLOR,
        0,
        0,
        clamp(speed)
      ])
    end

    def self.set_rumble(intensity:)
      new([
        0xA1,
        Protocol::RUMBLE_ID,
        Protocol::SET_LIGHT_COLOR,
        0,
        0,
        clamp(intensity)
      ])
    end

    def self.clamp(value)
      value.round.clamp(0, 255)
    end
    private_class_method :clamp

    def initialize(bytes)
      @bytes = bytes.freeze
    end

    def to_a
      bytes.dup
    end
  end
end
