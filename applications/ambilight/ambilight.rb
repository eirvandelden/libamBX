# cspell:words libambx screencapture getpoint Ambilight
require "vips"
require "thread"
require_relative "../../libambx/libambx"
require_relative "zone_mapper"

ZONE_COUNT = 5
PIXEL_SAMPLING_RATE = 20

def capture_screenshot
  screenshot_path = "screenshot.png"
  system("screencapture", "-x", screenshot_path)
  Vips::Image.new_from_file(screenshot_path).resize(0.5)
end

def average_color(image, x_start, y_start, width, height)
  pixels = []

  (y_start...y_start + height).step(PIXEL_SAMPLING_RATE).each do |y|
    (x_start...x_start + width).step(PIXEL_SAMPLING_RATE).each do |x|
      pixels << image.getpoint(x, y).first(3)
    end
  end

  totals = pixels.transpose.map { |channel| channel.sum / pixels.length.to_f }
  totals.map(&:round)
end

def calculate_zone_colors(image)
  zone_width = image.width / ZONE_COUNT

  (0...ZONE_COUNT).map do |index|
    average_color(image, index * zone_width, 0, zone_width, image.height)
  end
end

running = true

Signal.trap("INT") { running = false }
Signal.trap("TERM") { running = false }

session = nil

begin
  session = Ambx::Session.open
  mapper = Ambilight::ZoneMapper.new(lights: session.lights)

  while running
    begin
      image = capture_screenshot
      mapper.apply(calculate_zone_colors(image))
    rescue Ambx::Error::Base
      raise
    rescue StandardError => e
      warn "Error: #{e.message}"
    end

    sleep(0.5)
  end

rescue Ambx::Error::NoDeviceFound
  warn "Unable to find an ambx device"
  exit 1
rescue Ambx::Error::OpenFailed, Ambx::Error::ClaimFailed
  warn "Unable to open the discovered device"
  exit 1
ensure
  session&.close
end
