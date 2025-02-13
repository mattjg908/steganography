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

  Can you tell the difference between hamlet_encoded.bmp and original.jpg?

  "We save the output image as a BMP or TIFF file. These image formats have no
  compression, so we can be sure every pixel will stay exactly how we want it.
  This method can be modified for compressed images like JPG, but this requires
  making changes the compression won’t effect. A BMP/TIFF file is easier to work
  with but much larger."
  Writes decoded message out to file.


  """
  import Bitwise

  def read_bmp(file_path) do
    {:ok, binary} = File.read(file_path)

    # get headers, we will use pixel offset to fetch pixels later
    <<sig::binary-2, file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, width::little-32, height::little-32, _planes::little-16,
      bit_depth::little-16, _rest::binary>> = binary

    # do some validity checks
    if sig != "BM", do: raise("Not a valid BMP file!")

    if bit_depth != 24, do: raise("Only 24-bit BMP files are supported.")

    IO.puts(
      "File Size: #{file_size}, Width: #{width}, Height: #{height}, Bit Depth: #{bit_depth}"
    )

    # we know where the pixels are, lets get them
    <<_::binary-size(pixel_offset), pixel_data::binary>> = binary

    # Convert 24-bit BGR to RGB (ignoring alpha)
    pixels = extract_pixels(pixel_data, width, height)

    pixels
    |> List.flatten()
    |> Stream.flat_map(fn {r, g, b} -> [r &&& 1, g &&& 1, b &&& 1] end)
    |> Stream.chunk_every(8)
    |> Stream.map(fn byte_bits ->
      byte_string = Enum.join(byte_bits, "")
      byte_value = String.to_integer(byte_string, 2)
      <<byte_value::utf8>>
    end)
    |> Stream.reject(&(&1 == <<0>>))
    |> Stream.into(File.stream!("decode.txt", [:write]))
    |> Stream.run()
  end

  defp extract_pixels(pixel_data, width, height) do
    # Account for row padding
    row_size = div(width * 3 + 3, 4) * 4

    for row <- 0..(height - 1) do
      offset = row * row_size

      for col <- 0..(width - 1) do
        pixel_start = offset + col * 3
        <<b, g, r>> = binary_part(pixel_data, pixel_start, 3)
        # Convert BGR to RGB (no alpha)
        {r, g, b}
      end
    end
    # BMP stores pixels bottom-up
    |> Enum.reverse()
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
