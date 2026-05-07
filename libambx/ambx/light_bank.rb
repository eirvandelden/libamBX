class Ambx
  class LightBank
    ORDER = %i[left wwleft wwcenter wwright right].freeze

    def initialize(transport:, brightness:, packet_class: Packet)
      @transport = transport
      @brightness = brightness
      @packet_class = packet_class
      @source_colors = {}
    end

    def set(zone, color, green_boost: 1.0)
      source_color = color.with_green_multiplier(green_boost)
      @source_colors[zone] = source_color
      write(zone, source_color)
    end

    def set_all(color, green_boost: 1.0)
      ORDER.each do |zone|
        set(zone, color, green_boost: green_boost)
      end
    end

    def off
      set_all(Color.rgb(0, 0, 0))
    end

    def replay!
      ORDER.each do |zone|
        color = @source_colors[zone]
        next unless color

        write(zone, color)
      end
    end

    def source_colors
      @source_colors.dup
    end

    private

    def write(zone, source_color)
      scaled_color = @brightness.apply(source_color)
      @transport.write(@packet_class.set_light(zone: zone, color: scaled_color))
    end
  end
end
