module Mandelbrot

  class EscapeTime

    # Actual Mandelbrot Calculations

    Result = Struct.new(
      :iterations,
      :z_real,
      :z_imag,
      :c_real,
      :c_imag
    )

    DEFAULT_MAX_ITER = 100

    attr_reader :max_iter

    def initialize(max_iter: DEFAULT_MAX_ITER)
      @max_iter = max_iter
    end

    def call(c_real, c_imag)
      zr = 0.0
      zi = 0.0
      i  = 0
      max = @max_iter

      while i < max
        zr2 = zr * zr
        zi2 = zi * zi
        return i if zr2 + zi2 > 4.0

        zi = 2.0 * zr * zi + c_imag
        zr = (zr2 - zi2) + c_real

        i += 1
      end

      max
    end

    private


  end
end