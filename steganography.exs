defmodule Steganography do
  import Bitwise

  def read_bmp(file_path) do
    <<"BM", _file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, width::little-32, height::little-32, _planes::little-16,
      24::little-16, _rest::binary>> = binary = File.read!(file_path)

    <<_::binary-size(pixel_offset), pixel_data::binary>> = binary

    row_size = div(width * 3 + 3, 4) * 4

    Stream.flat_map((height - 1)..0//-1, fn row ->
      Stream.flat_map(0..(width - 1), fn col ->
        pixel_start = row * row_size + col * 3

        <<_::binary-size(pixel_start), _b::7, b::1, _g::7, g::1, _r::7, r::1, _::binary>> =
          pixel_data

        [r, g, b]
      end)
    end)
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
end

Steganography.read_bmp("hamlet_encoded.bmp")
