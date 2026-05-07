class Ambx
  class Brightness
    STEP = 0.05

    attr_reader :level

    def initialize(level: 1.0, step: STEP)
      @step = step
      @level = clamp(level)
      @light_bank = nil
    end

    def attach(light_bank)
      @light_bank = light_bank
    end

    def level=(value)
      new_level = clamp(value)
      return @level if new_level == @level

      @level = new_level
      @light_bank&.replay!
      @level
    end

    def adjust(delta)
      self.level = @level + (delta * @step)
    end

    def apply(color)
      color.scale(@level)
    end

    private

    def clamp(value)
      value.clamp(0.0, 1.0)
    end
  end
end
