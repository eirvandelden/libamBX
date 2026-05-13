module Menubar
  STRINGS = {
    title: "Ambx Lights",
    connected: "✓ Connected",
    disconnected: "⚠️ Disconnected",
    turn_off: "Turn Off Lights",
    quit: "QUIT"
  }.freeze

  class App
    def initialize(session_factory:, colors:, fan_speeds:, green_boost: 1.0, input: $stdin, output: $stdout, listener_factory: nil)
      @session_factory = session_factory
      @colors = colors
      @fan_speeds = fan_speeds
      @green_boost = green_boost
      @input = input
      @output = output
      @listener_factory = listener_factory
    end

    def run
      connected = connection_available?
      listener = start_listener
      print_menu(connected)

      while (selection = @input.gets&.chomp)
        outcome = handle_selection(selection, connected: connected)
        break if outcome == :quit

        connected = outcome
        print_menu(connected)
      end
    ensure
      listener&.stop
    end

    def connection_available?
      with_session { true }
    end

    def handle_selection(selection, connected:)
      return :quit if selection == STRINGS[:quit]
      return perform { |session| session.lights.off } if selection == STRINGS[:turn_off]

      fan = @fan_speeds.find { |entry| entry["name"] == selection }
      return perform { |session| session.fans.set_all(fan["speed"]) } if fan

      color = @colors.find { |entry| entry["name"] == selection }
      return perform { |session| session.lights.set_all(Ambx::Color.rgb(*color["rgb"]), green_boost: @green_boost) } if color

      connected
    end

    private

    def perform
      with_session do |session|
        yield(session)
        true
      end
    end

    def with_session
      session = @session_factory.call
      yield(session)
    rescue Ambx::Error::Base
      false
    ensure
      session&.close
    end

    def start_listener
      return unless @listener_factory

      @listener_factory.call.tap(&:start)
    rescue Ambx::Error::Base
      nil
    end

    def print_menu(connected)
      status = connected ? STRINGS[:connected] : STRINGS[:disconnected]

      @output.puts "#{STRINGS[:title]} (#{status})"
      @output.puts "---"
      @output.puts STRINGS[:turn_off] if connected
      @output.puts "---" if connected
      @colors.each { |color| @output.puts color["name"] }

      if connected
        @output.puts "---"
        @fan_speeds.each { |fan| @output.puts fan["name"] }
      end

      @output.puts "---"
      @output.puts STRINGS[:quit]
    end
  end
end
