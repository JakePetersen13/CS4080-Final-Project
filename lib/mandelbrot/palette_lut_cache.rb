require "mandelbrot/palette_lut"

module Mandelbrot
  class PaletteLUTCache
    def initialize(store: nil)
      @store = store || {}
    end

    # Fetch palette LUT from cache if we already created it, or create it it if we haven't
    # Check name of palette AND max_iter
    def fetch(palette:, max_iter:)
      key = [palette_cache_key(palette), max_iter]
      @store[key] ||= PaletteLUT.from_palette(palette: palette, max_iter: max_iter)
    end

    private

    def palette_cache_key(palette)
      palette.respond_to?(:name) ? palette.name : palette.class.name
    end
  end
end