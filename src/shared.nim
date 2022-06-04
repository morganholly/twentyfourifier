import nimPNG
import std/[enumerate, strformat, random, strutils]
randomize()

type
    RGBA* = object
        r*: uint8
        g*: uint8
        b*: uint8
        a*: uint8

proc color* (s: string): RGBA =
    var s2 = s.strip(chars = {' ', '#', '_'})
    if len(s2) == 8:
        result = RGBA(r: cast[uint8](parseHexInt(s2[0..<2])),
                        g: cast[uint8](parseHexInt(s2[2..<4])),
                        b: cast[uint8](parseHexInt(s2[4..<6])),
                        a: cast[uint8](parseHexInt(s2[6..<8])))
    elif len(s2) == 6:
        result = RGBA(r: cast[uint8](parseHexInt(s2[0..<2])),
                        g: cast[uint8](parseHexInt(s2[2..<4])),
                        b: cast[uint8](parseHexInt(s2[4..<6])),
                        a: 255'u8)
    else:
        raise newException(ValueError, "input string must contain 6 or 8 hex chars")

proc hexcode* (color: RGBA): string =
    result = "#" & fmt"{cast[int](color.r):>02x}" & fmt"{cast[int](color.g):>02x}" & fmt"{cast[int](color.b):>02x}" & fmt"{cast[int](color.a):>02x}"

proc `==`* (left: RGBA, right: RGBA): bool =
    result = (left.r == right.r) and (left.g == right.g) and (left.b == right.b) and (left.a == right.a)

proc avg* (left: RGBA, right: RGBA): RGBA =
    result = RGBA(r: cast[uint8]((cast[int32](left.r) + cast[int32](right.r)) shr 1), g: cast[uint8]((cast[int32](left.g) + cast[int32](right.g)) shr 1), b: cast[uint8]((cast[int32](left.b) + cast[int32](right.b)) shr 1), a: cast[uint8]((cast[int32](left.a) + cast[int32](right.a)) shr 1))

proc dist* (a: RGBA, b: RGBA): int =
    var rmean = ( cast[int](a.r) + cast[int](b.r) ) shr 1
    var r = cast[int](a.r) - cast[int](b.r)
    var g = cast[int](a.g) - cast[int](b.g)
    var b = cast[int](a.b) - cast[int](b.b)
    result = (((512+rmean)*r*r) shr 8) + 4*g*g + (((767-rmean)*b*b) shr 8)

proc closest* (opt: openArray[RGBA], other: RGBA): RGBA =
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

proc sum* (val: RGBA): int32 =
    result = (cast[int32](val.r) shl 24) + (cast[int32](val.g) shl 16) + (cast[int32](val.b) shl 8) + cast[int32](val.a)

proc scale* (x: int): int =
    result = (x shr 1) * 3

let debugmagenta* = RGBA(r: 255'u8, g: 0'u8, b: 255'u8, a: 255'u8)