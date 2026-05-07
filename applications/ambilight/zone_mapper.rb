# cspell:words Ambilight
module Ambilight
  class ZoneMapper
    ORDER = %i[left wwleft wwcenter wwright right].freeze

    def initialize(lights:)
      @lights = lights
    end

    def apply(zone_colors)
      ORDER.zip(zone_colors).each do |zone, color|
        @lights.set(zone, Ambx::Color.rgb(*color))
      end
    end
  end
end
