from PIL import Image

image = Image.open("wario.png")
pixels = image.load()

out_file = open("wario.bin", "wb")

for y in range(256):
  for x in range(128):
    try:
      out_file.write(bytes(chr(pixels[x, y]),'utf-8'))
    except IndexError:
      out_file.write(bytes(chr(0),'utf-8'))

