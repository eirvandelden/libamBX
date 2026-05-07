class Ambx
  module Input
    class Listener
      POLL_TIMEOUT_MS = 100
      BUFFER_SIZE = 32

      def initialize(transport:, decoder:, poll_timeout_ms: POLL_TIMEOUT_MS, buffer_size: BUFFER_SIZE)
        @transport = transport
        @decoder = decoder
        @poll_timeout_ms = poll_timeout_ms
        @buffer_size = buffer_size
        @callbacks = Hash.new { |hash, key| hash[key] = [] }
        @running = false
        @thread = nil
      end

      def on(event_type, &block)
        @callbacks[event_type] << block
        self
      end

      def start
        return self if @running

        @running = true
        @thread = Thread.new { listen }
        self
      end

      def stop
        @running = false
        @thread&.join unless Thread.current == @thread
        @thread = nil
        self
      end

      private

      def listen
        while @running
          packets.each do |bytes|
            event = @decoder.decode(bytes)
            dispatch(event) if event
          end
        end
      rescue Error::Disconnected, Error::InputUnavailable
        @running = false
      end

      def packets
        @transport.read_input_packets(size: @buffer_size, timeout: @poll_timeout_ms)
      end

      def dispatch(event)
        (@callbacks[event.type] + @callbacks[:any]).each do |callback|
          callback.call(event)
        end
      end
    end
  end
end
