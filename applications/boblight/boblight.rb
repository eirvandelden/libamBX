# cspell:words libambx boblight oceanius
require_relative "../../libambx/libambx"

puts
puts "boblight - a small tool to listen to the output of boblight popen to control a set of Philips Ambx lights."
puts "See README and docs/ for faq, usage and support.\n\n"
puts "Looking for support ?\nChat: irc.oceanius.com #dev\nMail: combustd@sexybiggetje.nl\n\n"
puts "Format: ruby boblight.rb r1 g1 b1 r2 g2 b2 r3 g3 b3 r4 g4 b4 r5 g5 b5\n\n"

session = nil

begin
  session = Ambx::Session.open

  while (line = gets)
    values = line.split(" ", 15).map { |value| (Float(value) * 255).round }
    colors = values.each_slice(3).map { |rgb| Ambx::Color.rgb(*rgb) }

    session.lights.set(:left, colors[0])
    session.lights.set(:right, colors[1])
    session.lights.set(:wwleft, colors[2])
    session.lights.set(:wwright, colors[3])
    session.lights.set(:wwcenter, colors[4])
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
