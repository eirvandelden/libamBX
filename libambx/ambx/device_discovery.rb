class Ambx
  class DeviceDiscovery
    def initialize(context: LIBUSB::Context.new, protocol: Protocol)
      @context = context
      @protocol = protocol
    end

    def devices
      @context.devices.select do |device|
        @protocol.supported_usb_device?(device.idVendor, device.idProduct)
      end
    end
  end
end
