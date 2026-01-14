module Mandelbrot
  class RenderService
    def initialize(renderer:, encoder:, lut_cache:)
      @renderer  = renderer
      @encoder   = encoder
      @lut_cache = lut_cache
    end

    def render_png(viewport:, palette:, max_iter:)
      iter_buffer = @renderer.render_iterations(viewport: viewport, max_iter: max_iter)

      palette_lut = @lut_cache.fetch(palette: palette, max_iter: max_iter)

      @encoder.encode_iterations(
        iter_buffer: iter_buffer,
        width: viewport.width,
        height: viewport.height,
        max_iter: max_iter,
        palette_lut: palette_lut,
      )
    end
  end
end