defmodule Steganography do
  import Bitwise

  def read_bmp(file_path) do
    <<"BM", _file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, width::little-32, _height::little-32, _planes::little-16,
      24::little-16, _rest::binary>> = bin = File.read!(file_path)

    <<_::binary-size(pixel_offset), pixel_data::binary>> = bin

    # Row size including padding (row widths must be multiples of 4)
    row_size = div(width * 3 + 3, 4) * 4
    # Pixel data per row (without padding)
    pixel_row_size = width * 3

    # Convert pixel_data into a list of binary rows before reversing
    # Reversing b/c BMP are usually read from bottom to top
    reversed_rows =
      pixel_data
      |> :binary.bin_to_list()
      |> Enum.chunk_every(row_size)
      |> Enum.reverse()
      |> Enum.map(&:binary.list_to_bin/1)

    least_significant_rgb_bits =
      for row <- reversed_rows,
          <<pixels::binary-size(pixel_row_size) <- row>>,
          <<_b::7, b::1, _g::7, g::1, _r::7, r::1 <- pixels>> do
        [r, g, b]
      end
      |> List.flatten()

    least_significant_rgb_bits
    |> Stream.chunk_every(8)
    |> Stream.map(fn bits ->
      Enum.reduce(bits, 0, fn bit, acc -> acc <<< 1 ||| bit end)
      |> then(&<<&1::8>>)
    end)
    |> Stream.reject(&(&1 == <<0>>))
    |> Stream.into(File.stream!("decode.txt", [:write]))
    |> Stream.run()
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
