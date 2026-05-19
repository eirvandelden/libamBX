#!/usr/bin/env ruby

$stdout.sync = true
$stderr.sync = true

require "yaml"
require_relative "app"
require_relative "boot"
require_relative "brightness_actions"
require_relative "macos_volume"

Menubar::Boot.load_dependencies(__dir__)

config = YAML.safe_load_file(Menubar::Boot.config_path(__dir__))

Menubar::App.new(
  session_factory: -> { Ambx::Session.open },
  colors: config.fetch("colors"),
  fan_speeds: config.fetch("fan_speeds"),
  green_boost: config.fetch("green_boost", 1.0)
).run
