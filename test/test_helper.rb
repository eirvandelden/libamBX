# cspell:words LIBPATH libambx
require "minitest/autorun"
require "minitest/spec"

begin
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  nil
end

module LIBUSB
  class Error < StandardError; end
  class ERROR_ACCESS < Error; end
  class ERROR_TIMEOUT < Error; end
  class ERROR_NO_DEVICE < Error; end

  class Context
    def initialize; end

    def devices
      []
    end
  end
end

LIBPATH = File.expand_path("../libambx", __dir__)

require "#{LIBPATH}/version"
require "#{LIBPATH}/ambx/error"
require "#{LIBPATH}/ambx/color"
require "#{LIBPATH}/ambx/protocol"
require "#{LIBPATH}/ambx/device_discovery"
require "#{LIBPATH}/ambx/transport"
require "#{LIBPATH}/ambx/packet"
require "#{LIBPATH}/ambx/brightness"
require "#{LIBPATH}/ambx/light_bank"
require "#{LIBPATH}/ambx/fan_bank"
require "#{LIBPATH}/ambx/rumble_device"
require "#{LIBPATH}/ambx/input/event"
require "#{LIBPATH}/ambx/input/rotary_decoder"
require "#{LIBPATH}/ambx/input/listener"
require "#{LIBPATH}/ambx/session"

module AmbxTestHelpers
  def fake_handle(transfer: nil, close_error: nil, claim_value: 0)
    handle = Object.new
    handle.define_singleton_method(:transfers) { @transfers ||= [] }
    handle.define_singleton_method(:close_count) { @close_count ||= 0 }
    handle.define_singleton_method(:auto_detach_values) { @auto_detach_values ||= [] }
    handle.define_singleton_method(:interrupt_transfer) do |**options|
      transfers << options
      transfer.respond_to?(:call) ? transfer.call(options) : transfer
    end
    handle.define_singleton_method(:claim_interface) { |_interface| claim_value }
    handle.define_singleton_method(:auto_detach_kernel_driver=) { |value| auto_detach_values << value }
    handle.define_singleton_method(:close) do
      raise close_error if close_error

      @close_count = close_count + 1
    end
    handle
  end

  def fake_device(vendor: Ambx::Protocol::USB_VENDOR_ID, product: Ambx::Protocol::USB_PRODUCT_ID, handle: nil, open_error: nil)
    device = Object.new
    device.define_singleton_method(:idVendor) { vendor }
    device.define_singleton_method(:idProduct) { product }
    device.define_singleton_method(:open) do
      raise open_error if open_error

      handle
    end
    device
  end

  def fake_discovery(devices)
    Object.new.tap do |discovery|
      discovery.define_singleton_method(:devices) { devices }
    end
  end
end
