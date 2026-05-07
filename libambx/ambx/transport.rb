class Ambx
  class Transport
    attr_reader :handles

    def initialize(context: LIBUSB::Context.new, discovery: nil, protocol: Protocol)
      @context = context
      @protocol = protocol
      @discovery = discovery || DeviceDiscovery.new(context: context, protocol: protocol)
      @handles = []
    end

    def self.open(**options)
      new(**options).tap(&:open!)
    end

    def open!
      devices = @discovery.devices
      raise Error::NoDeviceFound if devices.empty?

      @handles = devices.map(&:open)
      raise_open_failed if @handles.any?(&:nil?)

      claim_interfaces!
      self
    rescue Error::Base
      close
      raise
    end

    def connected?
      @handles.any?
    end

    def close
      @handles.each { |handle| close_handle(handle) }
      @handles = []
    end

    def write(packet_or_bytes)
      raise Error::Disconnected unless connected?

      bytes = packet_or_bytes.respond_to?(:to_a) ? packet_or_bytes.to_a : packet_or_bytes

      @handles.each do |handle|
        write_handle(handle, bytes)
      end
    end

    def read_input_packets(size:, timeout:)
      raise Error::InputUnavailable unless connected?

      @handles.filter_map do |handle|
        read_handle(handle, size: size, timeout: timeout)
      end
    end

    private

    def raise_open_failed
      @handles.compact.each { |handle| close_handle(handle) }
      raise Error::OpenFailed
    end

    def claim_interfaces!
      @handles.each do |handle|
        claim_interface(handle)
      end
    end

    def claim_interface(handle)
      4.times do |attempt|
        error_code = claim_once(handle)
        return true unless error_code.nil?

        handle.auto_detach_kernel_driver = true if attempt < 3
      end

      raise Error::ClaimFailed
    end

    def claim_once(handle)
      handle.claim_interface(0)
    rescue ArgumentError
      nil
    end

    def close_handle(handle)
      return unless handle

      handle.close
    rescue Errno::ENXIO
      nil
    end

    def write_handle(handle, bytes)
      handle.interrupt_transfer(
        endpoint: @protocol::ENDPOINT_OUT,
        dataOut: bytes.pack("C*"),
        timeout: 0
      )
    rescue Errno::ENXIO, LIBUSB::ERROR_NO_DEVICE
      close
      raise Error::Disconnected
    end

    def read_handle(handle, size:, timeout:)
      data = handle.interrupt_transfer(
        endpoint: @protocol::ENDPOINT_IN,
        dataIn: size,
        timeout: timeout
      )
      normalize_bytes(data)
    rescue LIBUSB::ERROR_TIMEOUT
      nil
    rescue Errno::ENXIO, LIBUSB::ERROR_NO_DEVICE
      close
      raise Error::Disconnected
    end

    def normalize_bytes(data)
      return data.unpack("C*") if data.is_a?(String)
      return data.to_a if data.respond_to?(:to_a)

      Array(data)
    end
  end
end
