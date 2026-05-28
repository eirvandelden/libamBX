# cspell:words getpoint
module Vips
  class Image
    def self.new_from_file(_path)
      @calls = @calls.to_i + 1
      raise "transient capture failure" if @calls == 1

      FakeImage.new
    end
  end

  class FakeImage
    def width
      100
    end

    def height
      100
    end

    def resize(_scale)
      self
    end

    def getpoint(_x, _y)
      [ 1, 2, 3 ]
    end
  end
end
