# Steganography

  Taken from [Dr. Mark Boady's lesson on Spycraft](https://algorithms.boady.net/content/099_cool/001_steg.html?highlight=steganography),
  > Steganography is a type of spycraft. It is a method of hiding data inside of images [James Stanger, 2020]. This practice has been used for centuries. People want to communicate secretly with others, but need to do it in a public place. They hide the message they want to send inside an image. The image can be posted in a public place. Anyone who sees it will just enjoy it as an image. Only those people that know how the message is encoded can reveal the secret payload within.

  **Obviously if you really wanted to keep the message secret you would encrypt it, and you would use a unique image rather than one pulled off of wikipedia so there'd be nothing to compare it to!**

  # How it works
  The image is parsed to seperate the various parts of an image. As described below, bmp is used to keep things simple (no compression for example), but can be modified to accommodate other formats.
  Bitmap has a standard format, so the script parses out the vairous components (header, pixel array, etc.). The pixels are turned into a list of list of tuples, representing the RGBA color for each pixel where:
  - R is the red value
  - G is the green value
  - B is the blue value
  - A is the alpha transparency level
  
  So, we'd end up with pixels like below:
  ```elixir
  [
    [
      {117, 152, 54, 255},
      {117, 150, 56, 255},
      ...
    ],
    [
      {116, 148, 58, 255},
      {114, 147, 53, 255},
      ...
    ],
    ...
  ]
  ```

  We reject the alpha channel, this leaves us with:
  ```elixir
  [
    [
      {117, 152, 54},
      {117, 150, 56},
      ...
    ],
    [
      {116, 148, 58},
      {114, 147, 53},
      ...
    ],
    ...
  ]
  ```

  Because of the fact that for most humans ![RGB Color](https://img.shields.io/badge/RGB-199%2C56%2C113-C73871?style=flat&labelColor=black)
  looks like ![RGB Color](https://img.shields.io/badge/RGB-198%2C57%2C112-C63970?style=flat&labelColor=black), we can change just the least significant
  bit by can an encoding either a `0` or `1`. Also note that in that example, all three pixels are changed but very often we may only change 1 pixel, or none in the case where
  they all happen to end in the intended `0` or `1` already.
  
  Since we can encode `0's` and `1's`, we can encode ASCII. Per Boady:
  > If we want to represent the letter “a” it has character code 97. We can then represent 97 as a binary value. In binary 97 is 0110 0001. Each character takes exactly 8 bits.
  > We can hide our bits in side a pixel. We store 1 bit in each color code. We place our bit in the last digit of the color code. That means we can fit 3 bits in each pixel. We need 3 pixels to fit a whole letter, with one
  > extra bit.

  So, if we had 3 pixels like
  ```elixir
  [
    {119, 150, 59},
    {117, 151, 60},
    {116, 151, 61}
  ]
  ```
  The 3 pixels above in (unchanged) binary form are:

  ```elixir
  [
    {1110111, 10010110, 111011},
    {1110101, 10010111, 111100},
    {1110100, 10010111, 111101}
  ]  
  ```

  Suppose we wanted to encode `"a"` in an image, the character code for "a" is (`97` which in binary is `01100001`). So, we'd take 3 pixels and change the least significant bit for each of RGA to be a 0 or a 1 til we "spell out" `0110 0001`

  ```elixir
  # "a" = <<97>> = <<0b01100001>>
  [
  #        0         1       1
    {1110110, 10010111, 111011},
  #        0         0       0
    {1110100, 10010110, 111100},
  #        0         1       unchanged or used for next pixel
    {1110100, 10010111, 111101}
  ]

  # In decimal, this is
  [
    {118, 151, 59},
    {116, 150, 60},
    {116, 151, 61}
  ]

  # Vs. the original
  [
    {119, 150, 59},
    {117, 151, 60},
    {116, 151, 61}
  ]
   ```

  # Usage
  ```bash
  elixir steganography.exs
  ```
  This will parse out the text from the image and write it to a file
  (`decode.txt`), it will also print out the raw bytes.

  Dr. Boady wrote the encoder and decoder in Python, this is a naive Elixir
  translation of his Python code (decoder only).

  # Example
  Can you tell the difference between hamlet_encoded.bmp and original.jpg?
  hamlet_encoded.bmp has the entire text of Hamlet encoded in it (from [Project
  Gutenberg](https://www.gutenberg.org/ebooks/1524)). Can you tell any
  difference between this and the original.jpg? 
  
  >"We save the output image as a BMP or TIFF file. These image formats have no
  compression, so we can be sure every pixel will stay exactly how we want it.
  This method can be modified for compressed images like JPG, but this requires
  making changes the compression won’t effect. A BMP/TIFF file is easier to work
  with but much larger."- Boady

  ## Original (taken from wikipedia [here](https://commons.wikimedia.org/w/index.php?curid=27124271))
  ![screenshot](original.jpg)

  ## Hamlet Encoded
  ![screenshot](hamlet_encoded.bmp)
  
  # Characters
  On a the topic of how meaning can be encoded,
  [from Dr. Boady](https://algorithms.boady.net/content/001_binary/007_chars.html?highlight=babel):
  >"The [Library of Babel](https://libraryofbabel.info/) takes this concept and generates all possible books with a certain number of characters."
  
