defmodule Steganography do
  @moduledoc """
  Taken from Dr. Mark Boady's lesson here:
  https://algorithms.boady.net/content/099_cool/001_steg.html?highlight=steganography

  Usage:
  ```bash
  elixir steganography.exs
  ```

  Dr. Boady wrote the encoder and decoder in Python, this is a naive Elixir
  translation of his Python code.

  """
  import Bitwise

  def read_bmp(file_path) do
    # we will use pixel offset to fetch pixels later
    # signature must = "BM" to be valid
    # only support 24-bit BMP bit depths (no alpha channels)
    <<"BM", _file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, width::little-32, height::little-32, _planes::little-16,
      24::little-16, _rest::binary>> = binary = File.read!(file_path)

    # now that we know where the pixels are, lets get them
    <<_::binary-size(pixel_offset), pixel_data::binary>> = binary

    pixel_data
    |> extract_pixels(width, height)
    |> Stream.flat_map(& &1)
    |> Stream.chunk_every(8)
    |> Stream.map(fn bits ->
      for bit <- bits, reduce: 0 do
        acc -> acc <<< 1 ||| bit
      end
      |> then(&<<&1::8>>)
    end)
    |> Stream.reject(&(&1 == <<0>>))
    |> Stream.into(File.stream!("decode.txt", [:write]))
    |> Stream.run()
  end

  # Convert 24-bit BGR to RGB
  defp extract_pixels(pixel_data, width, height) do
    # row_size:
    #   BMP requires each row to be aligned to a 4-byte boundary.
    #   If the width isn't a multiple of 4, extra bytes (padding) are added at
    #   the end of each row.
    row_size = div(width * 3 + 3, 4) * 4

    for row <- (height - 1)..0//-1, col <- 0..(width - 1), into: [] do
      pixel_start = row * row_size + col * 3

      <<_::binary-size(pixel_start), _b::7, b::1, _g::7, g::1, _r::7, r::1, _::binary>> =
        pixel_data

      [r, g, b]
    end
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
