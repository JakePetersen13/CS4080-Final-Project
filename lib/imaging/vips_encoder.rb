require "vips"

module Imaging
 
  class VipsEncoder
    DEFAULT_FORMAT = :png

    def initialize(format: DEFAULT_FORMAT)
      @format = format
    end

    def encode_iterations(iter_buffer:, width:, height:, max_iter:, palette_lut:, encode_options: {})
      validate_inputs!(iter_buffer, width, height, max_iter)

      iter_img = iterations_image(iter_buffer, width, height)
      lut_img = palette_lut_image(palette_lut)

      rgb_img = apply_palette(iter_img, lut_img)

      encode_image(rgb_img, encode_options)
    end

    private

    def validate_inputs!(iter_buffer, width, height, max_iter)
      if width <= 0 or height <= 0
        raise ArgumentError, "Invalid dimensions: width = #{width}, height = #{height}"
      end
      if iter_buffer.length != width * height * 2
        raise ArgumentError, "Iter_buffer does not match dimensions: buffer length = #{iter_buffer.length}, width = #{width}, height = #{height}, desired length = #{width * height * 2}"
      end
    end

    # Create a 1-band UInt16 image from the packed iteration buffer.
    def iterations_image(iter_buffer, width, height)
      iter_img = Vips::Image.new_from_memory(
        iter_buffer,
        width,
        height,
        1,        # bands
        :ushort   # format
      )
      iter_img
    end

    # Create a 3-band UInt8 image from the packed pallete lookup table buffer.
    def palette_lut_image(palette_lut)
      lut_img = Vips::Image.new_from_memory(
        palette_lut.palette_buffer,
        1,                            # width
        palette_lut.max_iter + 1,     # height
        3,                            # bands
        :uchar                        # format
      )
      return lut_img
    end

    # Apply LUT mapping in libvips.
    def apply_palette(iter_img, lut_img)
      rgb_img = iter_img.maplut(lut_img)
      rgb_img
    end

    def encode_image(img, encode_options)
      case @format
      when :png
        encode_png(img, encode_options)
      when :webp
        encode_webp(img, encode_options)
      else
        raise ArgumentError, "Unsupported format: #{@format.inspect}"
      end
    end

    def encode_png(img, encode_options)
      img.pngsave_buffer(**encode_options)
    end

    def encode_webp(img, encode_options)
      img.webpsave_buffer(**encode_options)
    end
  end
end
