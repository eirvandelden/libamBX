class Ambx
  class Color
    attr_reader :red, :green, :blue

    def self.rgb(red, green, blue)
      new(red: red, green: green, blue: blue)
    end

    def initialize(red:, green:, blue:)
      @red = clamp(red)
      @green = clamp(green)
      @blue = clamp(blue)
    end

    def to_a
      [ red, green, blue ]
    end

    def scale(multiplier)
      self.class.rgb(red * multiplier, green * multiplier, blue * multiplier)
    end

    def with_green_multiplier(multiplier)
      self.class.rgb(red, green * multiplier, blue)
    end

    private

    def clamp(value)
      value.round.clamp(0, 255)
    end
  end
end
