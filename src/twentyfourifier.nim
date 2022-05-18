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

proc dist(a: RGBA, b: RGBA): int =
    var rmean = ( cast[int](a.r) + cast[int](b.r) ) shr 1
    var r = cast[int](a.r) - cast[int](b.r)
    var g = cast[int](a.g) - cast[int](b.g)
    var b = cast[int](a.b) - cast[int](b.b)
    result = (((512+rmean)*r*r) shr 8) + 4*g*g + (((767-rmean)*b*b) shr 8)

proc closest(opt: openArray[RGBA], other: RGBA): RGBA =
    # c approximation
    # var dists: seq[int32] = @[]
    var min = int.high
    var minindex = -1
    for i, c in enumerate(opt):
        # var rmean = ( cast[int](c.r) + cast[int](other.r) ) shr 1
        # var r = cast[int](c.r) - cast[int](other.r)
        # var g = cast[int](c.g) - cast[int](other.g)
        # var b = cast[int](c.b) - cast[int](other.b)
        # var dist = (((512+rmean)*r*r) shr 8) + 4*g*g + (((767-rmean)*b*b) shr 8)
        var dist = dist(c, other)
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
        let rng = rand(1)
        # echo("x: ", x, " y:", y)
        # y,  x  y,  x+1
        # y+1,x  y+1,x+1
        # y,  x  y,  x+1  y,  x+2
        # y+1,x  y+1,x+1  y+1,x+2
        # y+2,x  y+2,x+1  y+2,x+2
        var x3 = scale(x)
        var y3 = scale(y)
        template top_left(): untyped = image[y, x]
        template top_right(): untyped = image[y, x+1]
        template bottom_left(): untyped = image[y+1, x]
        template bottom_right(): untyped = image[y+1, x+1]
        template out_top_left(): untyped = image[ym1, x]
        template out_top_right(): untyped = image[ym1, x+1]
        template out_right_top(): untyped = image[y, xp2]
        template out_right_bottom(): untyped = image[y+1, xp2]
        template out_bottom_right(): untyped = image[yp2, x+1]
        template out_bottom_left(): untyped = image[yp2, x]
        template out_left_bottom(): untyped = image[y+1, xm1]
        template out_left_top(): untyped = image[y, xm1]
        template newpx_top(): untyped = upscaled[y3, x3+1]
        template newpx_left(): untyped = upscaled[y3+1, x3]
        template newpx_center(): untyped = upscaled[y3+1, x3+1]
        template newpx_right(): untyped = upscaled[y3+1, x3+2]
        template newpx_bottom(): untyped = upscaled[y3+2, x3+1]
        # var ar = [image[y, x], image[y, x+1], image[y+1, x], image[y+1, x+1]]
        # # var ex = [image[ym1, x], image[ym1, x+1], image[y, xp2], image[y+1, xp2], image[y+1, xm1], image[yp2, x], image[yp2, x+1], image[y, xm1]] # why did this make it work right before????
        # var ex = [image[ym1, x], image[ym1, x+1], image[y, xp2], image[y+1, xp2], image[yp2, x+1], image[yp2, x], image[y+1, xm1], image[y, xm1]]
        upscaled[y3, x3] = top_left()
        upscaled[y3, x3+2] = top_right()
        upscaled[y3+2, x3] = bottom_left()
        upscaled[y3+2, x3+2] = bottom_right()
        let c01 = sum(top_left()) == sum(top_right())
        let c23 = sum(bottom_left()) == sum(bottom_right())
        let c02 = sum(top_left()) == sum(bottom_left())
        if c01 and c23 and c02:
            newpx_top() = top_left()
            newpx_left() = top_left()
            newpx_center() = top_left()
            newpx_right() = top_left()
            newpx_bottom() = top_left()
            continue
        newpx_top() = debugmagenta
        newpx_left() = debugmagenta
        newpx_center() = debugmagenta
        newpx_right() = debugmagenta
        newpx_bottom() = debugmagenta
        if c01 and c23:
            newpx_top() = top_left()
            newpx_bottom() = bottom_left()
            # echo("y: ", y, " ", hexcode(top_left()), " ", hexcode(bottom_left()), " ", ((y > ((png.height shr 1) - 1)) or y == 0) and (y < png.height - 2))
            if ((y > ((png.height shr 1) - 1)) or y == 0) and (y < png.height - 2):
                newpx_left() = top_left()
                newpx_center() = top_left()
                newpx_right() = top_left()
            else:
                newpx_left() = bottom_left()
                newpx_center() = bottom_left()
                newpx_right() = bottom_left()
            continue
        let c13 = sum(top_right()) == sum(bottom_right())
        if c02 and c13:
            newpx_left() = top_left()
            newpx_right() = top_right()
            # echo("x: ", x, " ", hexcode(top_left()), " ", hexcode(top_right()), " ", ((x > ((png.width shr 1) - 1)) or x == 0) and (x < png.width - 2))
            if ((x > ((png.width shr 1) - 1)) or x == 0) and (x < png.width - 2):
                newpx_top() = top_left()
                newpx_center() = top_left()
                newpx_bottom() = top_left()
            else:
                newpx_top() = top_right()
                newpx_center() = top_right()
                newpx_bottom() = top_right()
            continue
        # TODO make the corners not look like shit
        elif c01 and c13: # ◱
            newpx_top() = top_right()
            newpx_right() = top_right()
            newpx_center() = top_right()
            case (if out_left_top() == top_right(): 1 else: 0) + (if out_bottom_right() == top_right(): 2 else: 0):
                of 0:
                    newpx_left() = bottom_left()
                    newpx_bottom() = bottom_left()
                of 1:
                    newpx_left() = bottom_left()
                    newpx_bottom() = top_right()
                of 2:
                    newpx_left() = top_right()
                    newpx_bottom() = bottom_left()
                of 3:
                    newpx_left() = bottom_left()
                    newpx_bottom() = bottom_left()
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            continue
            # if out_left_top() == top_right():
            #     newpx_left() = top_right()
            # else:
            #     newpx_left() = bottom_left()
            # if out_bottom_right() == top_right():
            #     newpx_bottom() = top_right()
            # else:
            #     newpx_bottom() = bottom_left()
        elif c13 and c23: # ◰
            newpx_right() = bottom_right()
            newpx_bottom() = bottom_right()
            newpx_center() = bottom_right()
            case (if out_top_right() == bottom_right(): 1 else: 0) + (if out_left_bottom() == bottom_right(): 2 else: 0):
                of 0:
                    newpx_top() = top_left()
                    newpx_left() = top_left()
                of 1:
                    newpx_top() = top_left()
                    newpx_left() = bottom_right()
                of 2:
                    newpx_top() = bottom_right()
                    newpx_left() = top_left()
                of 3:
                    newpx_top() = top_left()
                    newpx_left() = top_left()
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            continue
            # if out_top_right() == bottom_right():
            #     newpx_top() = bottom_right()
            # else:
            #     newpx_top() = top_left()
            # if out_left_bottom() == bottom_right():
            #     newpx_left() = bottom_right()
            # else:
            #     newpx_left() = top_left()
        elif c23 and c02: # ◳
            newpx_left() = bottom_left()
            newpx_bottom() = bottom_left()
            newpx_center() = bottom_left()
            case (if out_top_left() == bottom_left(): 1 else: 0) + (if out_right_bottom() == bottom_left(): 2 else: 0):
                of 0:
                    newpx_top() = top_right()
                    newpx_right() = top_right()
                of 1:
                    newpx_top() = top_right()
                    newpx_right() = bottom_left()
                of 2:
                    newpx_top() = bottom_left()
                    newpx_right() = top_right()
                of 3:
                    newpx_top() = top_right()
                    newpx_right() = top_right()
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            continue
            # if out_top_left() == bottom_left():
            #     newpx_top() = bottom_left()
            # else:
            #     newpx_top() = top_right()
            # if out_right_bottom() == bottom_left():
            #     newpx_right() = bottom_left()
            # else:
            #     newpx_right() = top_right()
        elif c02 and c01: # ◲
            newpx_top() = top_left()
            newpx_left() = top_left()
            newpx_center() = top_left()
            # echo((if out_right_top() == top_left(): 1 else: 0) + (if out_bottom_left() == top_left(): 2 else: 0))
            # echo(hexcode(out_right_top()), " ", hexcode(top_left()))
            # for a in ar:
            #     stdout_.write(hexcode(a) & ", ")
            # echo()
            # for e in ex:
            #     stdout_.write(hexcode(e) & ", ")
            # echo()
            # echo(x, " ", xm1, " ", xp2, " ", y, " ", ym1, " ", yp2)
            case (if out_right_top() == top_left(): 1 else: 0) + (if out_bottom_left() == top_left(): 2 else: 0):
                of 0:
                    newpx_right() = bottom_right()
                    newpx_bottom() = bottom_right()
                of 1:
                    newpx_right() = bottom_right()
                    newpx_bottom() = top_left()
                of 2:
                    newpx_right() = top_left()
                    newpx_bottom() = bottom_right()
                of 3:
                    newpx_right() = bottom_right()
                    newpx_bottom() = bottom_right()
                else:
                    raise newException(ArithmeticDefect, "1 or 0 + 2 or 0 should be at most 3 and at least 0.")
            continue
            # if out_right_top() == top_left():
            #     newpx_right() = top_left()
            # else:
            #     newpx_right() = bottom_right()
            # if out_bottom_left() == top_left():
            #     newpx_bottom() = top_left()
            # else:
            #     newpx_bottom() = bottom_right()
        elif c01:
            newpx_top() = top_left() # top_
            let cLeft = (top_left() == out_left_top()) and (bottom_left() == out_left_bottom())
            let cRight = (top_left() == out_right_top()) and (bottom_right() == out_right_bottom())
            if cLeft and cRight:
                if dist(top_left(), bottom_left()) < dist(top_left(), bottom_right()): # left < right, dist to 0/1
                    newpx_left() = top_left()
                    newpx_center() = bottom_left()
                    newpx_right() = bottom_right()
                    if bottom_left() == out_bottom_left():
                        newpx_bottom() = bottom_left()
                    else:
                        newpx_bottom() = bottom_right()
                else:
                    newpx_left() = bottom_left()
                    newpx_center() = bottom_right()
                    newpx_right() = top_left()
                    if bottom_right() == out_bottom_right():
                        newpx_bottom() = bottom_right()
                    else:
                        newpx_bottom() = bottom_left()
            elif cLeft:
                newpx_left() = top_left()
                newpx_center() = bottom_left()
                newpx_right() = bottom_right()
                if bottom_left() == out_bottom_left():
                    newpx_bottom() = bottom_left()
                else:
                    newpx_bottom() = bottom_right()
            elif cRight:
                newpx_left() = bottom_left()
                newpx_center() = bottom_right()
                newpx_right() = top_left()
                if bottom_right() == out_bottom_right():
                    newpx_bottom() = bottom_right()
                else:
                    newpx_bottom() = bottom_left()
            else:
                if dist(top_left(), bottom_left()) < dist(top_left(), bottom_right()): # left < right, dist to 0/1
                    newpx_center() = bottom_left()
                    newpx_bottom() = bottom_right()
                else:
                    newpx_center() = bottom_right()
                    newpx_bottom() = bottom_left()
                newpx_right() = bottom_right()
                newpx_left() = bottom_left()
            continue
            # echo(x, " ", y, " ", cLeft, " ", cRight)
            # for a in ar:
            #     stdout_.write(hexcode(a) & ", ")
            # echo()
            # for e in ex:
            #     stdout_.write(hexcode(e) & ", ")
            # echo()
        elif c13:
            newpx_right() = top_right() # right
            # newpx_center() = top_left() # ar[0+(2*rng)] # center
            # newpx_top() = top_left() # top_
            # newpx_bottom() = bottom_left() # bottom_
            # newpx_left() = top_left() # ar[0+(2*rng)] # left
            let cTop = (top_right() == out_top_right()) and (top_left() == out_top_left())
            let cBottom = (top_right() == out_bottom_right()) and (bottom_left() == out_bottom_left())
            if cTop and cBottom:
                if dist(top_right(), top_left()) < dist(top_right(), bottom_left()): # top < bottom, dist to 1/3
                    newpx_top() = top_right()
                    newpx_center() = top_left()
                    newpx_bottom() = bottom_left()
                    if top_left() == out_left_top():
                        newpx_left() = top_left()
                    else:
                        newpx_left() = bottom_left()
                else:
                    newpx_top() = top_right()
                    newpx_center() = bottom_left()
                    newpx_bottom() = top_right()
                    if bottom_left() == out_left_bottom():
                        newpx_left() = bottom_left()
                    else:
                        newpx_left() = top_left()
            elif cTop:
                newpx_top() = top_right()
                newpx_center() = top_left()
                newpx_bottom() = bottom_left()
                if top_left() == out_left_top():
                    newpx_left() = top_left()
                else:
                    newpx_left() = bottom_left()
            elif cBottom:
                newpx_top() = top_right()
                newpx_center() = bottom_left()
                newpx_bottom() = top_right()
                if bottom_left() == out_left_bottom():
                    newpx_left() = bottom_left()
                else:
                    newpx_left() = top_left()
            else:
                if dist(top_right(), top_left()) < dist(top_right(), bottom_left()): # top < bottom, dist to 1/3
                    newpx_center() = top_left()
                    newpx_left() = bottom_left()
                else:
                    newpx_center() = bottom_left()
                    newpx_left() = top_left()
                newpx_bottom() = bottom_left()
                newpx_top() = top_left()
            continue
        elif c23:
            newpx_bottom() = bottom_right() # bottom_
            let cLeft = (bottom_left() == out_left_bottom()) and (top_left() == out_left_top())
            let cRight = (bottom_left() == out_right_bottom()) and (top_right() == out_right_top())
            if cLeft and cRight:
                if dist(bottom_left(), top_left()) < dist(bottom_left(), top_right()): # left < right, dist to 2/3
                    newpx_left() = bottom_left()
                    newpx_center() = top_left()
                    newpx_right() = top_right()
                    if top_left() == out_top_left():
                        newpx_top() = top_left()
                    else:
                        newpx_top() = top_right()
                else:
                    newpx_left() = top_left()
                    newpx_center() = top_right()
                    newpx_right() = bottom_left()
                    if top_right() == out_top_right():
                        newpx_top() = top_right()
                    else:
                        newpx_top() = top_left()
            elif cLeft:
                newpx_left() = bottom_left()
                newpx_center() = top_left()
                newpx_right() = top_right()
                if top_left() == out_top_left():
                    newpx_top() = top_left()
                else:
                    newpx_top() = top_right()
            elif cRight:
                newpx_left() = top_left()
                newpx_center() = top_right()
                newpx_right() = bottom_left()
                if top_right() == out_top_right():
                    newpx_top() = top_right()
                else:
                    newpx_top() = top_left()
            else:
                if dist(bottom_left(), top_left()) < dist(bottom_left(), top_right()): # left < right, dist to 2/3
                    newpx_center() = top_left()
                    newpx_top() = top_right()
                else:
                    newpx_center() = top_right()
                    newpx_top() = top_left()
                newpx_right() = top_right()
                newpx_left() = top_left()
            continue
        elif c02:
            newpx_left() = bottom_left() # left
            # newpx_center() = top_right() # ar[1+(2*rng)] # center
            # newpx_top() = top_right() # top_
            # newpx_bottom() = bottom_right() # bottom_
            # newpx_right() = top_right() # ar[1+(2*rng)] # right
            let cTop = (top_left() == out_top_left()) and (top_right() == out_top_right())
            let cBottom = (top_left() == out_bottom_left()) and (bottom_right() == out_bottom_right())
            if cTop and cBottom:
                if dist(top_left(), top_right()) < dist(top_left(), bottom_right()): # top < bottom, dist to 1/3
                    newpx_top() = top_left()
                    newpx_center() = top_right()
                    newpx_bottom() = bottom_right()
                    if top_right() == out_right_top():
                        newpx_right() = top_right()
                    else:
                        newpx_right() = bottom_right()
                else:
                    newpx_top() = top_left()
                    newpx_center() = bottom_right()
                    newpx_bottom() = top_left()
                    if bottom_right() == out_right_bottom():
                        newpx_right() = bottom_right()
                    else:
                        newpx_right() = top_right()
            elif cTop:
                newpx_top() = top_left()
                newpx_center() = top_right()
                newpx_bottom() = bottom_right()
                if top_right() == out_right_top():
                    newpx_right() = top_right()
                else:
                    newpx_right() = bottom_right()
            elif cBottom:
                newpx_top() = top_left()
                newpx_center() = bottom_right()
                newpx_bottom() = top_left()
                if bottom_right() == out_right_bottom():
                    newpx_right() = bottom_right()
                else:
                    newpx_right() = top_right()
            else:
                if dist(top_left(), top_right()) < dist(top_left(), bottom_right()): # top < bottom, dist to 1/3
                    newpx_center() = top_right()
                    newpx_right() = bottom_right()
                else:
                    newpx_center() = bottom_right()
                    newpx_right() = top_right()
                newpx_bottom() = bottom_right()
                newpx_top() = top_right()
            continue
        # else:
            # TODO do this better
            # if rng:
            #     newpx_top() = top_left()
            #     newpx_left() = bottom_left()
            #     newpx_center() = debugmagenta
            #     newpx_right() = top_right()
            #     newpx_bottom() = bottom_right()
            # else:
            #     newpx_top() = top_right()
            #     newpx_left() = top_left()
            #     newpx_center() = debugmagenta
            #     newpx_right() = bottom_right()
            #     newpx_bottom() = bottom_left()
            # newpx_top() = closest([top_left(), top_right(), bottom_left(), bottom_right()], avg(top_left(), top_right()))
            # newpx_left() = closest([top_left(), top_right(), bottom_left(), bottom_right()], avg(top_right(), bottom_left()))
            # newpx_center() = closest([top_left(), top_right(), bottom_left(), bottom_right()], avg(avg(top_left(), top_right()), avg(bottom_left(), bottom_right())))
            # newpx_right() = closest([top_left(), top_right(), bottom_left(), bottom_right()], avg(bottom_left(), bottom_right()))
            # newpx_bottom() = closest([top_left(), top_right(), bottom_left(), bottom_right()], avg(bottom_right(), top_left()))

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


