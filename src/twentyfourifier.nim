var testfile = ""
var outputfile = ""

import nimPNG, arraymancer
import std/[enumerate, strformat, random]
randomize()

type
    RGBA = object
        r: uint8
        g: uint8
        b: uint8
        a: uint8

proc hexcode(color: RGBA): string =
    result = "#" & fmt"{cast[int](color.r):>02x}" & fmt"{cast[int](color.g):>02x}" & fmt"{cast[int](color.b):>02x}" & fmt"{cast[int](color.a):>02x}"

proc `==`(left: RGBA, right: RGBA): bool =
    result = (left.r == right.r) and (left.g == right.g) and (left.b == right.b) and (left.a == right.a)

proc avg(left: RGBA, right: RGBA): RGBA =
    result = RGBA(r: cast[uint8]((cast[int32](left.r) + cast[int32](right.r)) shr 1), g: cast[uint8]((cast[int32](left.g) + cast[int32](right.g)) shr 1), b: cast[uint8]((cast[int32](left.b) + cast[int32](right.b)) shr 1), a: cast[uint8]((cast[int32](left.a) + cast[int32](right.a)) shr 1))

proc closest(opt: openArray[RGBA], other: RGBA): RGBA =
    # c approximation
    # var dists: seq[int32] = @[]
    var min = int32.high
    var minindex = -1
    for i, c in enumerate(opt):
        var rmean = ( cast[int32](c.r) + cast[int32](other.r) ) shr 1
        var r = cast[int32](c.r) - cast[int32](other.r)
        var g = cast[int32](c.g) - cast[int32](other.g)
        var b = cast[int32](c.b) - cast[int32](other.b)
        var dist = (((512+rmean)*r*r) shr 8) + 4*g*g + (((767-rmean)*b*b) shr 8)
        if dist == 0:
            return c
        elif dist < min:
            min = dist
            minindex = i
        # dists &= @[dist]
    return opt[minindex]

proc sum(val: RGBA): int32 =
    result = (cast[int32](val.r) shl 24) + (cast[int32](val.g) shl 16) + (cast[int32](val.b) shl 8) + cast[int32](val.a)

proc pick(ar: array[4, RGBA]): RGBA =
    let c01 = sum(ar[0]) == sum(ar[1])
    let c23 = sum(ar[2]) == sum(ar[3])
    let c02 = sum(ar[0]) == sum(ar[2])
    if c01 and c23 and c02:
        result = ar[0]
    elif c01 and c23:
        result = closest(ar, avg(ar[0], ar[2]))
    else:
        let c13 = sum(ar[1]) == sum(ar[3])
        if c02 and c13:
            result = closest(ar, avg(ar[0], ar[1]))
        let c12 = sum(ar[1]) == sum(ar[2])
        let c30 = sum(ar[3]) == sum(ar[0])
        if c12 and c30:
            result = closest(ar, avg(ar[1], ar[3]))
        else:
            result = closest(ar, avg(avg(ar[0], ar[1]), avg(ar[2], ar[3])))

proc read2d(png: PNGResult[string], x, y, w: int): char =
    result = png.data[y * w + x]

proc scale(x: int): int =
    result = (x shr 1) * 3

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
let outwidth = scale(png.width)
let outheight= scale(png.height)
let debugmagenta = RGBA(r: 255'u8, g: 0'u8, b: 255'u8, a: 255'u8)
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
# for y in countup(0, png.height-1, 2):
#     var ym1, yp2: int
#     if y == 0:
#         ym1 = y
#         yp2 = y + 1
#     elif y == png.height-1:
#         ym1 = y-1
#         yp2 = y
#     else:
#         ym1 = y-1
#         yp2 = y + 1
#     for x in countup(0, png.width-1, 2):
#         var xm1, xp2: int
#         if x == 0:
#             xm1 = x
#             xp2 = x + 1
#         elif x == png.width-1:
#             xm1 = x-1
#             xp2 = x
#         else:
#             xm1 = x-1
#             xp2 = x + 1
#         # echo("x: ", x, " y:", y)
#         # y,  x  y,  x+1
#         # y+1,x  y+1,x+1
#         # y,  x  y,  x+1  y,  x+2
#         # y+1,x  y+1,x+1  y+1,x+2
#         # y+2,x  y+2,x+1  y+2,x+2
#         var x3 = scale(x)
#         var y3 = scale(y)
#         upscaled[y3, x3] = image[y, x]
#         upscaled[y3, x3+1] = pick([image[ym1, x], image[ym1, x+1], image[y, x], image[y, x+1]])
#         upscaled[y3, x3+2] = image[y, x+1]
#         upscaled[y3+1, x3] = pick([image[y, xm1], image[y+1, xm1], image[y, x], image[y+1, x]])
#         upscaled[y3+1, x3+1] = pick([image[y+1, x], image[y+1, x+1], image[y, x], image[y, x+1]])
#         upscaled[y3+1, x3+2] = pick([image[y, xp2], image[y+1, xp2], image[y, x+1], image[y+1, x+1]])
#         upscaled[y3+2, x3] = image[y+1, x]
#         upscaled[y3+2, x3+1] = pick([image[yp2, x], image[yp2, x+1], image[y, x], image[y, x+1]])
#         upscaled[y3+2, x3+2] = image[y+1, x+1]
for y in countup(0, png.height-1, 2):
    # echo("y:", y)
    var ym1, yp2: int
    if y == 0:
        ym1 = y
        yp2 = y + 2
    elif y >= png.height-2:
        ym1 = y-1
        yp2 = y + 1
    else:
        ym1 = y-1
        yp2 = y + 2
    for x in countup(0, png.width-1, 2):
        # echo("x:", x)
        var xm1, xp2: int
        if x == 0:
            xm1 = x
            xp2 = x + 2
        elif x >= png.width-2:
            xm1 = x-1
            xp2 = x + 1
        else:
            xm1 = x-1
            xp2 = x + 2
        let rng = 1 == rand(1)
        # echo("x: ", x, " y:", y)
        # y,  x  y,  x+1
        # y+1,x  y+1,x+1
        # y,  x  y,  x+1  y,  x+2
        # y+1,x  y+1,x+1  y+1,x+2
        # y+2,x  y+2,x+1  y+2,x+2
        var x3 = scale(x)
        var y3 = scale(y)
        var ar = [image[y, x], image[y, x+1], image[y+1, x], image[y+1, x+1]]
        var ex = [image[ym1, x], image[ym1, x+1], image[y, xp2], image[y+1, xp2], image[y+1, xm1], image[yp2, x], image[yp2, x+1], image[y, xm1]]
        upscaled[y3, x3] = ar[0]
        upscaled[y3, x3+2] = ar[1]
        upscaled[y3+2, x3] = ar[2]
        upscaled[y3+2, x3+2] = ar[3]
        let c01 = sum(ar[0]) == sum(ar[1])
        let c23 = sum(ar[2]) == sum(ar[3])
        let c02 = sum(ar[0]) == sum(ar[2])
        if c01 and c23 and c02:
            upscaled[y3, x3+1] = ar[0]
            upscaled[y3+1, x3] = ar[0]
            upscaled[y3+1, x3+1] = ar[0]
            upscaled[y3+1, x3+2] = ar[0]
            upscaled[y3+2, x3+1] = ar[0]
            continue
        upscaled[y3, x3+1] = debugmagenta
        upscaled[y3+1, x3] = debugmagenta
        upscaled[y3+1, x3+1] = debugmagenta
        upscaled[y3+1, x3+2] = debugmagenta
        upscaled[y3+2, x3+1] = debugmagenta
        if c01 and c23:
            upscaled[y3, x3+1] = ar[0]
            upscaled[y3+2, x3+1] = ar[2]
            echo("y: ", y, " ", hexcode(ar[0]), " ", hexcode(ar[2]), " ", ((y > ((png.height shr 1) - 1)) or y == 0) and (y < png.height - 2))
            if ((y > ((png.height shr 1) - 1)) or y == 0) and (y < png.height - 2):
                upscaled[y3+1, x3] = ar[0]
                upscaled[y3+1, x3+1] = ar[0]
                upscaled[y3+1, x3+2] = ar[0]
            else:
                upscaled[y3+1, x3] = ar[2]
                upscaled[y3+1, x3+1] = ar[2]
                upscaled[y3+1, x3+2] = ar[2]
        let c13 = sum(ar[1]) == sum(ar[3])
        if c02 and c13:
            upscaled[y3+1, x3] = ar[0]
            upscaled[y3+1, x3+2] = ar[1]
            echo("x: ", x, " ", hexcode(ar[0]), " ", hexcode(ar[1]), " ", ((x > ((png.width shr 1) - 1)) or x == 0) and (x < png.width - 2))
            if ((x > ((png.width shr 1) - 1)) or x == 0) and (x < png.width - 2):
                upscaled[y3, x3+1] = ar[0]
                upscaled[y3+1, x3+1] = ar[0]
                upscaled[y3+2, x3+1] = ar[0]
            else:
                upscaled[y3, x3+1] = ar[1]
                upscaled[y3+1, x3+1] = ar[1]
                upscaled[y3+2, x3+1] = ar[1]
        elif c01 and c13: # ◱
            upscaled[y3, x3+1] = ar[1]
            upscaled[y3+1, x3+2] = ar[1]
            upscaled[y3+1, x3+1] = ar[1]
            case (if ex[7] == ar[1]: 1 else: 0) + (if ex[4] == ar[1]: 2 else: 0):
                of 0:
                    upscaled[y3+1, x3] = ar[2]
                    upscaled[y3+2, x3+1] = ar[2]
                of 1:
                    upscaled[y3+1, x3] = ar[2]
                    upscaled[y3+2, x3+1] = ar[1]
                of 2:
                    upscaled[y3+1, x3] = ar[1]
                    upscaled[y3+2, x3+1] = ar[2]
                of 3:
                    upscaled[y3+1, x3] = ar[2]
                    upscaled[y3+2, x3+1] = ar[2]
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            # if ex[7] == ar[1]:
            #     upscaled[y3+1, x3] = ar[1]
            # else:
            #     upscaled[y3+1, x3] = ar[2]
            # if ex[4] == ar[1]:
            #     upscaled[y3+2, x3+1] = ar[1]
            # else:
            #     upscaled[y3+2, x3+1] = ar[2]
        elif c13 and c23: # ◰
            upscaled[y3+1, x3+2] = ar[3]
            upscaled[y3+2, x3+1] = ar[3]
            upscaled[y3+1, x3+1] = ar[3]
            case (if ex[1] == ar[3]: 1 else: 0) + (if ex[6] == ar[3]: 2 else: 0):
                of 0:
                    upscaled[y3, x3+1] = ar[0]
                    upscaled[y3+1, x3] = ar[0]
                of 1:
                    upscaled[y3, x3+1] = ar[0]
                    upscaled[y3+1, x3] = ar[3]
                of 2:
                    upscaled[y3, x3+1] = ar[3]
                    upscaled[y3+1, x3] = ar[0]
                of 3:
                    upscaled[y3, x3+1] = ar[0]
                    upscaled[y3+1, x3] = ar[0]
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            # if ex[1] == ar[3]:
            #     upscaled[y3, x3+1] = ar[3]
            # else:
            #     upscaled[y3, x3+1] = ar[0]
            # if ex[6] == ar[3]:
            #     upscaled[y3+1, x3] = ar[3]
            # else:
            #     upscaled[y3+1, x3] = ar[0]
        elif c23 and c02: # ◳
            upscaled[y3+1, x3] = ar[2]
            upscaled[y3+2, x3+1] = ar[2]
            upscaled[y3+1, x3+1] = ar[2]
            case (if ex[0] == ar[2]: 1 else: 0) + (if ex[3] == ar[2]: 2 else: 0):
                of 0:
                    upscaled[y3, x3+1] = ar[1]
                    upscaled[y3+1, x3+2] = ar[1]
                of 1:
                    upscaled[y3, x3+1] = ar[1]
                    upscaled[y3+1, x3+2] = ar[2]
                of 2:
                    upscaled[y3, x3+1] = ar[2]
                    upscaled[y3+1, x3+2] = ar[1]
                of 3:
                    upscaled[y3, x3+1] = ar[1]
                    upscaled[y3+1, x3+2] = ar[1]
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            # if ex[0] == ar[2]:
            #     upscaled[y3, x3+1] = ar[2]
            # else:
            #     upscaled[y3, x3+1] = ar[1]
            # if ex[3] == ar[2]:
            #     upscaled[y3+1, x3+2] = ar[2]
            # else:
            #     upscaled[y3+1, x3+2] = ar[1]
        elif c02 and c01: # ◲
            upscaled[y3, x3+1] = ar[0]
            upscaled[y3+1, x3] = ar[0]
            upscaled[y3+1, x3+1] = ar[0]
            # echo((if ex[2] == ar[0]: 1 else: 0) + (if ex[5] == ar[0]: 2 else: 0))
            # echo(hexcode(ex[2]), " ", hexcode(ar[0]))
            # for a in ar:
            #     stdout.write(hexcode(a) & ", ")
            # echo()
            # for e in ex:
            #     stdout.write(hexcode(e) & ", ")
            # echo()
            # echo(x, " ", xm1, " ", xp2, " ", y, " ", ym1, " ", yp2)
            case (if ex[2] == ar[0]: 1 else: 0) + (if ex[5] == ar[0]: 2 else: 0):
                of 0:
                    upscaled[y3+1, x3+2] = ar[3]
                    upscaled[y3+2, x3+1] = ar[3]
                of 1:
                    upscaled[y3+1, x3+2] = ar[3]
                    upscaled[y3+2, x3+1] = ar[0]
                of 2:
                    upscaled[y3+1, x3+2] = ar[0]
                    upscaled[y3+2, x3+1] = ar[3]
                of 3:
                    upscaled[y3+1, x3+2] = ar[3]
                    upscaled[y3+2, x3+1] = ar[3]
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            # if ex[2] == ar[0]:
            #     upscaled[y3+1, x3+2] = ar[0]
            # else:
            #     upscaled[y3+1, x3+2] = ar[3]
            # if ex[5] == ar[0]:
            #     upscaled[y3+2, x3+1] = ar[0]
            # else:
            #     upscaled[y3+2, x3+1] = ar[3]
        else:
            # TODO do this better
            if rng:
                upscaled[y3, x3+1] = ar[0]
                upscaled[y3+1, x3] = ar[2]
                upscaled[y3+1, x3+1] = debugmagenta
                upscaled[y3+1, x3+2] = ar[1]
                upscaled[y3+2, x3+1] = ar[3]
            else:
                upscaled[y3, x3+1] = ar[1]
                upscaled[y3+1, x3] = ar[0]
                upscaled[y3+1, x3+1] = debugmagenta
                upscaled[y3+1, x3+2] = ar[3]
                upscaled[y3+2, x3+1] = ar[2]

var output: seq[uint8] = @[]
for y in 0 ..< outheight:
    for x in 0 ..< outwidth:
        output &= @[upscaled[y, x].r, upscaled[y, x].g, upscaled[y, x].b, upscaled[y, x].a]
discard savePNG32(outputfile, output, outwidth, outheight)

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


