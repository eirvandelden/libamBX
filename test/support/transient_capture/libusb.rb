module LIBUSB
  class ERROR_TIMEOUT < StandardError; end
  class ERROR_NO_DEVICE < StandardError; end

  class Context
    def devices
      [ Device.new ]
    end
  end

  class Device
    def idVendor
      0x0471
    end

    def idProduct
      0x083F
    end

    def open
      Handle.new
    end
  end

  class Handle
    def claim_interface(_interface)
      self
    end

    def auto_detach_kernel_driver=(_value); end

    def interrupt_transfer(**options)
      File.open(ENV.fetch("AMBX_WRITES_FILE"), "a") { |file| file.puts(options.fetch(:dataOut).bytes.join(",")) }
    end

    def close; end
  end
end
