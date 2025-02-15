defmodule Steganography do
  @bytes_per_pixel 3

  def read_bmp(file_path) do
    <<"BM", _file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, img_width_in_pixels::little-32, _height::little-32,
      _planes::little-16, 24::little-16, _rest::binary>> = bin = File.read!(file_path)

    <<_::binary-size(pixel_offset), pixel_data::binary>> = bin

    img_width_in_bytes = img_width_in_pixels * @bytes_per_pixel
    # BMP row width must be a multiple of 4, below adds padding to width if needed
    row_width = div(img_width_in_bytes + @bytes_per_pixel, 4) * 4

    # BMP rows are stored bottom-up, so reverse them
    Enum.reverse(for <<row::binary-size(row_width) <- pixel_data>>, do: row)
    |> Enum.map(fn row ->
      for <<pixels::binary-size(img_width_in_bytes) <- row>>,
          <<_b::7, b::1, _g::7, g::1, _r::7, r::1 <- pixels>>,
          do: [r, g, b]
    end)
    |> List.flatten()
    |> Stream.chunk_every(8)
    |> Stream.reject(fn bits -> Enum.all?(bits, &(&1 == 0)) end)
    |> Stream.map(fn bits -> for bit <- bits, into: <<>>, do: <<bit::1>> end)
    |> Stream.into(File.stream!("decode.txt", [:write]))
    |> Stream.run()
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
