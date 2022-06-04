var testfile = ""
var outputfile = ""
var mapfile = ""

import nimPNG, arraymancer
import shared, mode_rules, mode_lerp


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
let outwidth* = scale(png.width)
let outheight* = scale(png.height)
echo(outwidth, " ",  outheight)
var image = newTensor[RGBA]([png.width, png.height])
for y in 0 ..< png.height:
    for x in 0 ..< png.width:
        image[y, x] = RGBA(
                        r: cast[uint8](png.data[4 * (y * png.width + x)]),
                        g: cast[uint8](png.data[4 * (y * png.width + x) + 1]),
                        b: cast[uint8](png.data[4 * (y * png.width + x) + 2]),
                        a: cast[uint8](png.data[4 * (y * png.width + x) + 3]))

var upscaled = newTensor[RGBA]([outwidth, outheight])
var map = newTensor[RGBA]([outwidth, outheight])

upscaleRules(upscaled, map, image, png.height, png.width)

var output: seq[uint8] = @[]
for y in 0 ..< outheight:
    for x in 0 ..< outwidth:
        output &= @[upscaled[y, x].r, upscaled[y, x].g, upscaled[y, x].b, upscaled[y, x].a]
discard savePNG32(outputfile, output, outwidth, outheight)
var map_out: seq[uint8] = @[]
for y in 0 ..< outheight:
    for x in 0 ..< outwidth:
        # if map[y, x].a > 0:
        map_out &= @[map[y, x].r, map[y, x].g, map[y, x].b, map[y, x].a]
        # else:
        #     map_out &= @[upscaled[y, x].r shr 1, upscaled[y, x].g shr 1, upscaled[y, x].b shr 1, upscaled[y, x].a]
discard savePNG32(mapfile, map_out, outwidth, outheight)

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


