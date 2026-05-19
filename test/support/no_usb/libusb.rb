module LIBUSB
  class ERROR_TIMEOUT < StandardError; end
  class ERROR_NO_DEVICE < StandardError; end

  class Context
    def devices
      []
    end
  end
end
