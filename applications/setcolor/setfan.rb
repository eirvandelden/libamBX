# cspell:words libambx setfan oceanius
require_relative "../../libambx/libambx"

puts
puts "setfan - a small utility to configure a set of Philips Ambx fans to a specific speed."
puts "See README and docs/ for faq, usage and support.\n\n"
puts "Looking for support ?\nChat: irc.oceanius.com #dev\nMail: combustd@sexybiggetje.nl\n\n"

session = Ambx::Session.open
session.fans.set_all(Integer(ARGV[0]))
session.close
