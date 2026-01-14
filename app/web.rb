require_relative "config/boot"

require "imaging/vips_encoder"
require "mandelbrot/renderer"
require "mandelbrot/render_service"
require "mandelbrot/viewport"
require "mandelbrot/palette_lut_cache"
require "mandelbrot/palette/base"

class Web < Sinatra::Base
  configure do
    renderer  = Mandelbrot::Renderer.new
    encoder   = Imaging::VipsEncoder.new(format: :png)
    lut_cache = Mandelbrot::PaletteLUTCache.new

    set :render_service, Mandelbrot::RenderService.new(
      renderer: renderer,
      encoder: encoder,
      lut_cache: lut_cache
    )
  end

  get "/render.png" do
    viewport = Mandelbrot::Viewport.from_params(params)
    palette  = Mandelbrot::Palette::Base.new # however you choose it

    png = settings.render_service.render_png(
      viewport: viewport,
      palette: palette,
      max_iter: 1000,
    )

    content_type "image/png"
    body png
  end
end