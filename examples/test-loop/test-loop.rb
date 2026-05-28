# cspell:words libambx
require "../../libambx/libambx"

ZONE_SEQUENCE = %i[left wwleft wwcenter wwright right].freeze
BASE_COLOR = Ambx::Color.rgb(204, 0, 0)
GREEN = Ambx::Color.rgb(0, 255, 0)
BLUE = Ambx::Color.rgb(0, 0, 255)

def write_frame(session, active_zone:, active_color:)
  ZONE_SEQUENCE.each do |zone|
    color = zone == active_zone ? active_color : BASE_COLOR
    session.lights.set(zone, color)
  end
end

session = Ambx::Session.open

puts "\nRunning test-loop\n"

begin
  loop do
    ZONE_SEQUENCE.each do |zone|
      write_frame(session, active_zone: zone, active_color: GREEN)
      sleep 1
    end

    session.lights.set_all(BASE_COLOR)
    sleep 1

    ZONE_SEQUENCE.reverse_each do |zone|
      write_frame(session, active_zone: zone, active_color: BLUE)
      sleep 1
    end

    session.lights.set_all(BASE_COLOR)
    sleep 1
    session.lights.off
    sleep 1
  end
ensure
  session&.close
end
