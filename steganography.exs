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
  Writes decoded message out to file, prints raw binary.


  """
  import Bitwise

  def read_bmp(file_path) do
    {:ok, binary} = File.read(file_path)

    # Extract signature
    signature = binary_part(binary, 0, 2)
    if signature != "BM", do: raise "Not a valid BMP file!"

    # Extract header values safely
    file_size = :binary.decode_unsigned(binary_part(binary, 2, 4), :little)
    pixel_offset = :binary.decode_unsigned(binary_part(binary, 10, 4), :little)
    _header_size = :binary.decode_unsigned(binary_part(binary, 14, 4), :little)
    width = :binary.decode_unsigned(binary_part(binary, 18, 4), :little)
    height = :binary.decode_unsigned(binary_part(binary, 22, 4), :little)
    bit_depth = :binary.decode_unsigned(binary_part(binary, 28, 2), :little)

    IO.puts("File Size: #{file_size}, Width: #{width}, Height: #{height}, Bit Depth: #{bit_depth}")

    if bit_depth != 24 do
      raise "Only 24-bit BMP files are supported."
    end

    # Extract pixel data
    pixel_data = binary_part(binary, pixel_offset, byte_size(binary) - pixel_offset)

    # Convert 24-bit BGR to RGB (ignoring alpha)
    pixels = extract_pixels(pixel_data, width, height)

    #%{width: width, height: height, pixels: pixels}
    pixels
    |> List.flatten()
    |> Enum.flat_map(fn {r, g, b} -> [r &&& 000000001, g &&& 000000001, b &&& 000000001] end)
    |> Enum.chunk_every(8)  # Group into 8-bit chunks
    |> Enum.map(fn byte_bits ->
      byte_string = Enum.join(byte_bits, "")
      byte_value = String.to_integer(byte_string, 2)
      <<byte_value::utf8>>
    end)
    |> Enum.reject(& &1 == <<0>>)
    |> Enum.join("") 
    |> tap(& File.write("decode.txt", &1))
  end

  defp extract_pixels(pixel_data, width, height) do
    row_size = div(width * 3 + 3, 4) * 4  # Account for row padding

    for row <- 0..(height - 1) do
      offset = row * row_size
      for col <- 0..(width - 1) do
        pixel_start = offset + col * 3
        <<b, g, r>> = binary_part(pixel_data, pixel_start, 3)
        {r, g, b}  # Convert BGR to RGB (no alpha)
      end
    end
    |> Enum.reverse()  # BMP stores pixels bottom-up
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
|> IO.inspect()
