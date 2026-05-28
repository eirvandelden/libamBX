# cspell:words libambx setcolor oceanius
require_relative "../../libambx/libambx"

puts
puts "setcolor - a small utility to configure a set of Philips Ambx lights to a specific color."
puts "See README and docs/ for faq, usage and support.\n\n"
puts "Looking for support ?\nChat: irc.oceanius.com #dev\nMail: combustd@sexybiggetje.nl\n\n"

session = nil

begin
  session = Ambx::Session.open
  color = Ambx::Color.rgb(Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]))

  session.lights.set_all(color)
  session.fans.set_all(0)
rescue Ambx::Error::NoDeviceFound
  warn "Unable to find an ambx device"
  exit 1
rescue Ambx::Error::OpenFailed, Ambx::Error::ClaimFailed
  warn "Unable to open the discovered device"
  exit 1
ensure
  session&.close
end
