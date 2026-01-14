module Mandelbrot

  module Palette

    class Base

      # Color palatte based on escape time. can be copied and modified to create more color schemes

      def name
        self.class.name.split("::").last.downcase
      end

      def color_for(iter:, max_iter:)
        if iter >= max_iter
          return [0, 0, 0]
        end

        normalized = Math.log(iter + 1) / Math.log(max_iter)

        if normalized < 0
          return [255, 255, 255]
        end

        r = (255 * (0.5 + 0.5 * Math.sin(normalized * 2 * Math::PI))).to_i
        g = (255 * (0.5 + 0.5 * Math.sin(normalized * 2 * Math::PI + 2 * Math::PI / 3))).to_i
        b = (255 * (0.5 + 0.5 * Math.sin(normalized * 2 * Math::PI + 4 * Math::PI / 3))).to_i

        [r, g, b]
      end
    end
  end
end