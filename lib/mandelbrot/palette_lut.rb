require 'vips'

module Mandelbrot
  class PaletteLUT

    # Creates a Lookup Table from our color palatte 
    # Used to create a Vips image for effiecient color mapping

    attr_reader :max_iter, :name, :palette_buffer

    def initialize(max_iter:, name: nil)
      @max_iter = max_iter
      @name = name
    end

    def self.from_palette(palette: palette, max_iter: max_iter)
      lut = new(max_iter: max_iter, name: palette.respond_to?(:name) ? palette.name : nil)
      lut.build!(palette)
      lut
    end

    # Creates a memory buffer made of max_iter + 1 sections of 3 bytes (r, g, and b)
    def build!(palette)
      if palette.respond_to?(:color_for)
        palette_array = Array.new(@max_iter + 1) { |i| palette.color_for(iter: i, max_iter: @max_iter)}
        @palette_buffer = palette_array.flatten.pack('C*')
      end

      self
    end

  end
end