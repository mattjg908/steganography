defmodule Steganography do
  # 1 byte each for R, G, B- since this only supports 24-bit there's no alpha
  @bytes_per_pixel 3

  def read_bmp(file_path) do
    <<"BM", _file_size::little-32, _reserved::little-32, pixel_offset::little-32,
      _header_size::little-32, img_width_in_pixels::little-32, _height::little-32,
      _planes::little-16, 24::little-16, _rest::binary>> = bin = File.read!(file_path)

    <<_::binary-size(pixel_offset), pixel_data::binary>> = bin

    pixel_data
    |> :binary.bin_to_list()
    # BMP row sizes must be multiples of 4, logic below may/not add padding
    |> Enum.chunk_every(_row = div(img_width_in_pixels * @bytes_per_pixel + 3, 4) * 4)
    |> Enum.reverse()
    |> Stream.map(&:binary.list_to_bin/1)
    |> Stream.flat_map(fn row ->
      for <<pixels::binary-size(img_width_in_pixels * @bytes_per_pixel) <- row>>,
          <<_b::7, b::1, _g::7, g::1, _r::7, r::1 <- pixels>>,
          do: [r, g, b]
    end)
    |> Stream.flat_map(& &1)
    |> Stream.chunk_every(8)
    |> Stream.reject(fn bits -> Enum.all?(bits, &(&1 == 0)) end)
    |> Stream.map(fn bits -> for bit <- bits, into: <<>>, do: <<bit::1>> end)
    |> Stream.into(File.stream!("decode.txt", [:write]))
    |> Stream.run()
  end
end

Steganography.read_bmp("hamlet_encoded.bmp")
