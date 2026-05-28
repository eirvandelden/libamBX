class Ambx
  module Error
    class Base < StandardError; end

    class NoDeviceFound < Base; end
    class OpenFailed < Base; end
    class ClaimFailed < Base; end
    class Disconnected < Base; end
    class InputUnavailable < Base; end
  end
end
