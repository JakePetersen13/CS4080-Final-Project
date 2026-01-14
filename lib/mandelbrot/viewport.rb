require "imaging/vips_encoder"
require "mandelbrot/escape_time"
require "mandelbrot/palette_lut_cache"
require 'vips'

module Mandelbrot
  class ViewPort

    attr_reader :width, :height, :min_real, :max_real, :min_imag, :max_imag

    def initialize(width:, height:, center_real:, center_imag:, zoom:)
      @width        = Integer(width)
      @height       = Integer(height)
      @center_real  = Float(center_real)
      @center_imag  = Float(center_imag )
      @zoom         = Float(zoom)

      validate!
      precompute!
    end

    def self.from_params(params)
      new(
        width:  params.fetch("width", 800),
        height: params.fetch("height", 600),
        center_real:     params.fetch("center_re", 0.0),
        center_imag:     params.fetch("center_im", 0.0),
        zoom:   params.fetch("zoom", 1)
      )
    end

    def precompute!
      @range = 3.5 / @zoom
      @min_real = @center_real - @range
      @max_real = @center_real + @range
      @min_imag = @center_imag - @range * @height / @width
      @max_imag = @center_imag + @range * @height / @width
    end

    def validate!
      raise ArgumentError, "Width must be > 0"  if @width <= 0
      raise ArgumentError, "Height must be > 0" if @height <= 0
    end
    
  end
end
