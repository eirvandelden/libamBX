class Ambx
  module Protocol
    USB_VENDOR_ID = 0x0471
    USB_PRODUCT_ID = 0x083F
    DEFAULT_USB_DEVICE_IDS = [ [ USB_VENDOR_ID, USB_PRODUCT_ID ] ].freeze
    USB_DEVICE_IDS_ENV = "AMBX_USB_DEVICE_IDS"

    ENDPOINT_IN = 0x81
    ENDPOINT_OUT = 0x02
    ENDPOINT_PNP = 0x83

    SET_LIGHT_COLOR = 0x03
    SET_TIMED_COLOR_SEQUENCE = 0x72

    LIGHT_IDS = {
      left: 0x0B,
      right: 0x1B,
      wwleft: 0x2B,
      wwcenter: 0x3B,
      wwright: 0x4B
    }.freeze

    FAN_IDS = {
      left: 0x5B,
      right: 0x6B
    }.freeze

    RUMBLE_ID = 0x7B

    def self.supported_usb_device_ids
      (DEFAULT_USB_DEVICE_IDS + usb_device_ids_from_env).uniq
    end

    def self.supported_usb_device?(vendor_id, product_id)
      supported_usb_device_ids.include?([ vendor_id, product_id ])
    end

    def self.usb_device_ids_from_env
      raw_value = ENV.fetch(USB_DEVICE_IDS_ENV, "").strip
      return [] if raw_value.empty?

      raw_value.split(",").filter_map { |entry| parse_usb_device_id(entry) }
    end
    private_class_method :usb_device_ids_from_env

    def self.parse_usb_device_id(entry)
      match = entry.strip.match(/\A(?:0[xX])?([0-9A-Fa-f]{1,4}):(?:0[xX])?([0-9A-Fa-f]{1,4})\z/)
      return nil unless match

      [ match[1].to_i(16), match[2].to_i(16) ]
    end
    private_class_method :parse_usb_device_id
  end

  module Lights
    LEFT = Protocol::LIGHT_IDS[:left]
    RIGHT = Protocol::LIGHT_IDS[:right]
    WWLEFT = Protocol::LIGHT_IDS[:wwleft]
    WWCENTER = Protocol::LIGHT_IDS[:wwcenter]
    WWRIGHT = Protocol::LIGHT_IDS[:wwright]
  end

  module Fans
    LEFT = Protocol::FAN_IDS[:left]
    RIGHT = Protocol::FAN_IDS[:right]
  end

  module Rumbler
    DEVICE = Protocol::RUMBLE_ID
    KEYBOARD = DEVICE
  end
end
