require "mandelbrot/escape_time"

module Mandelbrot
  class Renderer

    def initialize
      @escape_time_by_iter = {}
    end


    def render_iterations(viewport:, max_iter:)
      width = viewport.width
      height = viewport.height
      min_real = viewport.min_real
      max_real = viewport.max_real
      min_imag = viewport.min_imag
      max_imag = viewport.max_imag

      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      escape = (@escape_time_by_iter[max_iter] ||= EscapeTime.new(max_iter: max_iter))

      iter_buffer = String.new(capacity: width * height * 2)
      dx = (max_real - min_real) / width.to_f
      dy = (max_imag - min_imag) / height.to_f

      c_im = min_imag
      y = 0
      while y < height
        c_re = min_real
        x = 0
        while x < width
          iter = escape.call(c_re, c_im)

          iter_buffer << (iter & 0xFF).chr << ((iter >> 8) & 0xFF).chr

          c_re += dx
          x += 1
        end
        c_im += dy
        y += 1
      end

      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = ending - starting
      puts elapsed 

      iter_buffer
    end

  end
end