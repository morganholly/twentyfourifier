var testfile = ""
var outputfile = ""

import nimPNG, arraymancer
import std/[enumerate, strformat]

type
    RGBA = object
        r: uint8
        g: uint8
        b: uint8
        a: uint8

proc read2d(png: PNGResult[string], x, y, w: int): char =
    result = png.data[y * w + x]

let png = loadPNG(testfile, LCT_RGBA, 8)

echo(png.width)
echo(png.height)
echo(len(png.data))
# for i, v in enumerate(png.data):
#     if i mod (w * 4) == 0:
#         echo("")
#     if i mod 4 == 0:
#         stdout.write("#")
#     stdout.write(fmt"{cast[int](v):>02x}")
#     if i mod 4 == 3:
#         stdout.write(" ")
assert len(png.data) mod 4 == 0
assert png.width mod 2 == 0
assert png.height mod 2 == 0
var image = newTensor[RGBA]([png.width, png.height])
for y in 0 ..< png.height:
    for x in 0 ..< png.width:
        image[y, x] = RGBA(
                        r: cast[uint8](png.data[4 * (y * png.width + x)]),
                        g: cast[uint8](png.data[4 * (y * png.width + x) + 1]),
                        b: cast[uint8](png.data[4 * (y * png.width + x) + 2]),
                        a: cast[uint8](png.data[4 * (y * png.width + x) + 3]))

var output: seq[uint8] = @[]
for y in 0 ..< png.height:
    for x in 0 ..< png.width:
        output &= @[image[y, x].r, image[y, x].g, image[y, x].b, image[y, x].a]
discard savePNG32(outputfile, output, png.width, png.height)

#3d2a42ff #574658ff #3d2a42ff #3d2a42ff #3d2a42ff #574658ff #574658ff #b29767ff #cdc397ff #b29767ff #8e574bff #222435ff #3d2a42ff #3d2a42ff #643633ff #19131dff 
#6e6979ff #6e6979ff #574658ff #3d2a42ff #959aa6ff #574658ff #3d2a42ff #8e574bff #b29767ff #643633ff #643633ff #8e574bff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff 
#959aa6ff #6e6979ff #574658ff #959aa6ff #959aa6ff #6e6979ff #3d2a42ff #222435ff #8e574bff #643633ff #643633ff #643633ff #222435ff #3d2a42ff #3d2a42ff #222435ff 
#3d2a42ff #222435ff #3d2a42ff #3d2a42ff #222435ff #222435ff #222435ff #222435ff #222435ff #8e574bff #643633ff #643633ff #222435ff #222435ff #3d2a42ff #222435ff 
#b29767ff #8e574bff #b29767ff #8e574bff #8e574bff #8e574bff #643633ff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff #222435ff #222435ff #3d2a42ff #3d2a42ff #222435ff 
#8e574bff #8e574bff #8e574bff #8e574bff #8e574bff #643633ff #643633ff #643633ff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff 
#643633ff #8e574bff #643633ff #643633ff #643633ff #643633ff #643633ff #643633ff #643633ff #3d2a42ff #222435ff #222435ff #643633ff #3d2a42ff #3d2a42ff #222435ff 
#19131dff #222435ff #222435ff #3d2a42ff #574658ff #574658ff #3d2a42ff #574658ff #222435ff #222435ff #19131dff #19131dff #643633ff #3d2a42ff #3d2a42ff #19131dff 
#222435ff #222435ff #3d2a42ff #574658ff #574658ff #574658ff #574658ff #3d2a42ff #3d2a42ff #222435ff #222435ff #19131dff #643633ff #3d2a42ff #3d2a42ff #19131dff 
#8e574bff #643633ff #643633ff #8e574bff #643633ff #643633ff #643633ff #643633ff #643633ff #3d2a42ff #3d2a42ff #222435ff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff 
#8e574bff #8e574bff #8e574bff #8e574bff #8e574bff #643633ff #643633ff #643633ff #3d2a42ff #3d2a42ff #222435ff #222435ff #3d2a42ff #222435ff #3d2a42ff #222435ff 
#b29767ff #b29767ff #8e574bff #8e574bff #8e574bff #8e574bff #643633ff #3d2a42ff #3d2a42ff #222435ff #222435ff #19131dff #222435ff #222435ff #3d2a42ff #222435ff 
#3d2a42ff #222435ff #222435ff #3d2a42ff #222435ff #222435ff #222435ff #222435ff #222435ff #8e574bff #643633ff #643633ff #222435ff #3d2a42ff #3d2a42ff #222435ff 
#574658ff #574658ff #959aa6ff #959aa6ff #574658ff #3d2a42ff #222435ff #222435ff #8e574bff #643633ff #643633ff #643633ff #222435ff #3d2a42ff #3d2a42ff #222435ff 
#3d2a42ff #959aa6ff #959aa6ff #959aa6ff #6e6979ff #574658ff #222435ff #8e574bff #b29767ff #643633ff #643633ff #8e574bff #3d2a42ff #3d2a42ff #3d2a42ff #222435ff 
#3d2a42ff #6e6979ff #6e6979ff #3d2a42ff #3d2a42ff #574658ff #3d2a42ff #b29767ff #cdc397ff #b29767ff #8e574bff #222435ff #3d2a42ff #3d2a42ff #643633ff #222435ff ⏎ 


