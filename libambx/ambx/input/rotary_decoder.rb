class Ambx
  module Input
    class RotaryDecoder
      def initialize(mappings: [])
        @mappings = mappings
      end

      def decode(bytes)
        return nil if bytes.nil? || bytes.empty?

        mapping = @mappings.find { |entry| entry.fetch(:match) == bytes }
        return nil unless mapping

        Event.new(type: mapping.fetch(:type), delta: mapping.fetch(:delta))
      end
    end
  end
end
