module Menubar
  module MacOSVolume
    STEP = 5

    module_function

    def adjust(delta)
      current_volume = `osascript -e 'output volume of (get volume settings)'`.strip.to_i
      new_volume = (current_volume + (delta * STEP)).clamp(0, 100)
      system("osascript", "-e", "set volume output volume #{new_volume}")
    end
  end
end
