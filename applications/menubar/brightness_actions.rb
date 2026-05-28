module Menubar
  module BrightnessActions
    module_function

    def bind(listener:, session:, volume_adapter: MacOSVolume)
      listener.on(:volume) { |event| volume_adapter.adjust(event.delta) }
      listener.on(:brightness) { |event| session.brightness.adjust(event.delta) }
      listener
    end
  end
end
