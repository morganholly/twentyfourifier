import arraymancer
import shared


proc upscaleRules* (upscaled: var Tensor[RGBA], map: var Tensor[RGBA], image: Tensor[RGBA], height, width: int): void =
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
    template out_corner_tl(): untyped = image[ym1, xm1]
    template out_corner_tr(): untyped = image[ym1, xp2]
    template out_corner_bl(): untyped = image[yp2, xm1]
    template out_corner_br(): untyped = image[yp2, xp2]
    template newpx_top(): untyped = upscaled[y3, x3+1]
    template newpx_left(): untyped = upscaled[y3+1, x3]
    template newpx_center(): untyped = upscaled[y3+1, x3+1]
    template newpx_right(): untyped = upscaled[y3+1, x3+2]
    template newpx_bottom(): untyped = upscaled[y3+2, x3+1]
    template map_tl(): untyped = map[y3, x3]
    template map_tc(): untyped = map[y3, x3+1]
    template map_tr(): untyped = map[y3, x3+2]
    template map_cl(): untyped = map[y3+1, x3]
    template map_cc(): untyped = map[y3+1, x3+1]
    template map_cr(): untyped = map[y3+1, x3+2]
    template map_bl(): untyped = map[y3+2, x3]
    template map_bc(): untyped = map[y3+2, x3+1]
    template map_br(): untyped = map[y3+2, x3+2]
    template map_all(value: untyped): untyped =
        map[y3, x3] = value
        map[y3, x3+1] = value
        map[y3, x3+2] = value
        map[y3+1, x3] = value
        map[y3+1, x3+1] = value
        map[y3+1, x3+2] = value
        map[y3+2, x3] = value
        map[y3+2, x3+1] = value
        map[y3+2, x3+2] = value
    template map_v(one, two, three: untyped): untyped =
        map[y3, x3] = one
        map[y3, x3+1] = one
        map[y3, x3+2] = one
        map[y3+1, x3] = two
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = two
        map[y3+2, x3] = three
        map[y3+2, x3+1] = three
        map[y3+2, x3+2] = three
    template map_h(one, two, three: untyped): untyped =
        map[y3, x3] = one
        map[y3, x3+1] = two
        map[y3, x3+2] = three
        map[y3+1, x3] = one
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = three
        map[y3+2, x3] = one
        map[y3+2, x3+1] = two
        map[y3+2, x3+2] = three
    template map_vt(value: untyped): untyped =
        map[y3, x3] = value
        map[y3, x3+1] = value
        map[y3, x3+2] = value
    template map_vb(value: untyped): untyped =
        map[y3+2, x3] = value
        map[y3+2, x3+1] = value
        map[y3+2, x3+2] = value
    template map_hl(value: untyped): untyped =
        map[y3, x3] = value
        map[y3+1, x3] = value
        map[y3+2, x3] = value
    template map_hr(value: untyped): untyped =
        map[y3, x3+2] = value
        map[y3+1, x3+2] = value
        map[y3+2, x3+2] = value
    template map_corner_tl(one, two: untyped): untyped =
        map[y3, x3] = one
        map[y3, x3+1] = one
        map[y3, x3+2] = one
        map[y3+1, x3] = one
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = two
        map[y3+2, x3] = one
        map[y3+2, x3+1] = two
        map[y3+2, x3+2] = two
    template map_corner_tr(one, two: untyped): untyped =
        map[y3, x3] = one
        map[y3, x3+1] = one
        map[y3, x3+2] = one
        map[y3+1, x3] = two
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = one
        map[y3+2, x3] = two
        map[y3+2, x3+1] = two
        map[y3+2, x3+2] = one
    template map_corner_bl(one, two: untyped): untyped =
        map[y3, x3] = one
        map[y3, x3+1] = two
        map[y3, x3+2] = two
        map[y3+1, x3] = one
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = two
        map[y3+2, x3] = one
        map[y3+2, x3+1] = one
        map[y3+2, x3+2] = one
    template map_corner_br(one, two: untyped): untyped =
        map[y3, x3] = two
        map[y3, x3+1] = two
        map[y3, x3+2] = one
        map[y3+1, x3] = two
        map[y3+1, x3+1] = two
        map[y3+1, x3+2] = one
        map[y3+2, x3] = one
        map[y3+2, x3+1] = one
        map[y3+2, x3+2] = one
    template map_diagonal(sides, left, right, center: untyped): untyped =
        map[y3, x3] = left
        map[y3, x3+1] = sides
        map[y3, x3+2] = right
        map[y3+1, x3] = sides
        map[y3+1, x3+1] = center
        map[y3+1, x3+2] = sides
        map[y3+2, x3] = right
        map[y3+2, x3+1] = sides
        map[y3+2, x3+2] = left
    for y in countup(0, height-1, 2):
        # echo("y:", y)
        var ym1, yp2: int
        if y == 0:
            ym1 = y
            yp2 = y + 2
        elif y >= height-2:
            ym1 = y-1
            yp2 = y + 1
        else:
            ym1 = y-1
            yp2 = y + 2
        for x in countup(0, width-1, 2):
            # echo("x:", x)
            var xm1, xp2: int
            if x == 0:
                xm1 = x
                xp2 = x + 2
            elif x >= width-2:
                xm1 = x-1
                xp2 = x + 1
            else:
                xm1 = x-1
                xp2 = x + 2
            # echo("x: ", x, " y:", y)
            # y,  x  y,  x+1
            # y+1,x  y+1,x+1
            # y,  x  y,  x+1  y,  x+2
            # y+1,x  y+1,x+1  y+1,x+2
            # y+2,x  y+2,x+1  y+2,x+2
            var x3 = scale(x)
            var y3 = scale(y)
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
                map_all(color("#400000"))
                continue
            newpx_top() = debugmagenta
            newpx_left() = debugmagenta
            newpx_center() = debugmagenta
            newpx_right() = debugmagenta
            newpx_bottom() = debugmagenta
            if c01 and c23:
                newpx_top() = top_left()
                newpx_bottom() = bottom_left()
                if ((y > ((height shr 1) - 1)) or y == 0) and (y < height - 2):
                    newpx_left() = top_left()
                    newpx_center() = top_left()
                    newpx_right() = top_left()
                    map_v(color("#3030B0"), color("#3030B0"), color("#006040"))
                else:
                    newpx_left() = bottom_left()
                    newpx_center() = bottom_left()
                    newpx_right() = bottom_left()
                    map_v(color("#3030B0"), color("#006040"), color("#006040"))
                continue
            let c13 = sum(top_right()) == sum(bottom_right())
            if c02 and c13:
                newpx_left() = top_left()
                newpx_right() = top_right()
                if ((x > ((width shr 1) - 1)) or x == 0) and (x < width - 2):
                    newpx_top() = top_left()
                    newpx_center() = top_left()
                    newpx_bottom() = top_left()
                    map_h(color("#3030B0"), color("#3030B0"), color("#006040"))
                else:
                    newpx_top() = top_right()
                    newpx_center() = top_right()
                    newpx_bottom() = top_right()
                    map_h(color("#3030B0"), color("#006040"), color("#006040"))
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
                map_corner_tr(color("#906020"), color("#402040"))
                continue
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
                map_corner_br(color("#906020"), color("#402040"))
                continue
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
                map_corner_bl(color("#906020"), color("#402040"))
                continue
            elif c02 and c01: # ◲
                newpx_top() = top_left()
                newpx_left() = top_left()
                newpx_center() = top_left()
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
                map_corner_tl(color("#906020"), color("#402040"))
                continue
            elif c01:
                newpx_top() = top_left()
                let cLeft = (top_left() == out_left_top()) and (bottom_left() == out_left_bottom())
                let cRight = (top_left() == out_right_top()) and (bottom_right() == out_right_bottom())
                if cLeft and cRight:
                    if dist(top_left(), bottom_left()) < dist(top_left(), bottom_right()):
                        newpx_left() = top_left()
                        newpx_center() = bottom_left()
                        newpx_right() = bottom_right()
                        if bottom_left() == out_bottom_left():
                            newpx_bottom() = bottom_left()
                        else:
                            newpx_bottom() = bottom_right()
                        map_h(color("#604000"), color("#604000"), color("#000000"))
                    else:
                        newpx_left() = bottom_left()
                        newpx_center() = bottom_right()
                        newpx_right() = top_left()
                        if bottom_right() == out_bottom_right():
                            newpx_bottom() = bottom_right()
                        else:
                            newpx_bottom() = bottom_left()
                        map_h(color("#000000"), color("#604000"), color("#604000"))
                elif cLeft:
                    newpx_left() = top_left()
                    newpx_center() = bottom_left()
                    newpx_right() = bottom_right()
                    if bottom_left() == out_bottom_left():
                        newpx_bottom() = bottom_left()
                    else:
                        newpx_bottom() = bottom_right()
                    map_h(color("#604000"), color("#000000"), color("#000000"))
                elif cRight:
                    newpx_left() = bottom_left()
                    newpx_center() = bottom_right()
                    newpx_right() = top_left()
                    if bottom_right() == out_bottom_right():
                        newpx_bottom() = bottom_right()
                    else:
                        newpx_bottom() = bottom_left()
                    map_h(color("#000000"), color("#000000"), color("#604000"))
                else:
                    if dist(top_left(), bottom_left()) < dist(top_left(), bottom_right()):
                        newpx_center() = bottom_left()
                        newpx_bottom() = bottom_right()
                    else:
                        newpx_center() = bottom_right()
                        newpx_bottom() = bottom_left()
                    newpx_right() = bottom_right()
                    newpx_left() = bottom_left()
                    map_h(color("#000000"), color("#000000"), color("#000000"))
                map_vt(color("#C0B030"))
                continue
            elif c13:
                newpx_right() = top_right()
                let cTop = (top_right() == out_top_right()) and (top_left() == out_top_left())
                let cBottom = (top_right() == out_bottom_right()) and (bottom_left() == out_bottom_left())
                if cTop and cBottom:
                    if dist(top_right(), top_left()) < dist(top_right(), bottom_left()):
                        newpx_top() = top_right()
                        newpx_center() = top_left()
                        newpx_bottom() = bottom_left()
                        if top_left() == out_left_top():
                            newpx_left() = top_left()
                        else:
                            newpx_left() = bottom_left()
                        map_v(color("#604000"), color("#604000"), color("#000000"))
                    else:
                        newpx_top() = top_right()
                        newpx_center() = bottom_left()
                        newpx_bottom() = top_right()
                        if bottom_left() == out_left_bottom():
                            newpx_left() = bottom_left()
                        else:
                            newpx_left() = top_left()
                        map_v(color("#000000"), color("#604000"), color("#604000"))
                elif cTop:
                    newpx_top() = top_right()
                    newpx_center() = top_left()
                    newpx_bottom() = bottom_left()
                    if top_left() == out_left_top():
                        newpx_left() = top_left()
                    else:
                        newpx_left() = bottom_left()
                    map_v(color("#604000"), color("#000000"), color("#000000"))
                elif cBottom:
                    newpx_top() = top_right()
                    newpx_center() = bottom_left()
                    newpx_bottom() = top_right()
                    if bottom_left() == out_left_bottom():
                        newpx_left() = bottom_left()
                    else:
                        newpx_left() = top_left()
                    map_v(color("#000000"), color("#000000"), color("#604000"))
                else:
                    if dist(top_right(), top_left()) < dist(top_right(), bottom_left()):
                        newpx_center() = top_left()
                        newpx_left() = bottom_left()
                    else:
                        newpx_center() = bottom_left()
                        newpx_left() = top_left()
                    newpx_bottom() = bottom_left()
                    newpx_top() = top_left()
                    map_v(color("#000000"), color("#000000"), color("#000000"))
                map_hr(color("#C0B030"))
                continue
            elif c23:
                newpx_bottom() = bottom_right()
                let cLeft = (bottom_left() == out_left_bottom()) and (top_left() == out_left_top())
                let cRight = (bottom_left() == out_right_bottom()) and (top_right() == out_right_top())
                if cLeft and cRight:
                    if dist(bottom_left(), top_left()) < dist(bottom_left(), top_right()):
                        newpx_left() = bottom_left()
                        newpx_center() = top_left()
                        newpx_right() = top_right()
                        if top_left() == out_top_left():
                            newpx_top() = top_left()
                        else:
                            newpx_top() = top_right()
                        map_h(color("#604000"), color("#604000"), color("#000000"))
                    else:
                        newpx_left() = top_left()
                        newpx_center() = top_right()
                        newpx_right() = bottom_left()
                        if top_right() == out_top_right():
                            newpx_top() = top_right()
                        else:
                            newpx_top() = top_left()
                        map_h(color("#000000"), color("#604000"), color("#604000"))
                elif cLeft:
                    newpx_left() = bottom_left()
                    newpx_center() = top_left()
                    newpx_right() = top_right()
                    if top_left() == out_top_left():
                        newpx_top() = top_left()
                    else:
                        newpx_top() = top_right()
                    map_h(color("#604000"), color("#000000"), color("#000000"))
                elif cRight:
                    newpx_left() = top_left()
                    newpx_center() = top_right()
                    newpx_right() = bottom_left()
                    if top_right() == out_top_right():
                        newpx_top() = top_right()
                    else:
                        newpx_top() = top_left()
                    map_h(color("#000000"), color("#000000"), color("#604000"))
                else:
                    if dist(bottom_left(), top_left()) < dist(bottom_left(), top_right()):
                        newpx_center() = top_left()
                        newpx_top() = top_right()
                    else:
                        newpx_center() = top_right()
                        newpx_top() = top_left()
                    newpx_right() = top_right()
                    newpx_left() = top_left()
                    map_h(color("#000000"), color("#000000"), color("#000000"))
                map_vb(color("#C0B030"))
                continue
            elif c02:
                newpx_left() = bottom_left()
                let cTop = (top_left() == out_top_left()) and (top_right() == out_top_right())
                let cBottom = (top_left() == out_bottom_left()) and (bottom_right() == out_bottom_right())
                if cTop and cBottom:
                    if dist(top_left(), top_right()) < dist(top_left(), bottom_right()):
                        newpx_top() = top_left()
                        newpx_center() = top_right()
                        newpx_bottom() = bottom_right()
                        if top_right() == out_right_top():
                            newpx_right() = top_right()
                        else:
                            newpx_right() = bottom_right()
                        map_v(color("#604000"), color("#604000"), color("#000000"))
                    else:
                        newpx_top() = top_left()
                        newpx_center() = bottom_right()
                        newpx_bottom() = top_left()
                        if bottom_right() == out_right_bottom():
                            newpx_right() = bottom_right()
                        else:
                            newpx_right() = top_right()
                        map_v(color("#000000"), color("#604000"), color("#604000"))
                elif cTop:
                    newpx_top() = top_left()
                    newpx_center() = top_right()
                    newpx_bottom() = bottom_right()
                    if top_right() == out_right_top():
                        newpx_right() = top_right()
                    else:
                        newpx_right() = bottom_right()
                    map_v(color("#604000"), color("#000000"), color("#000000"))
                elif cBottom:
                    newpx_top() = top_left()
                    newpx_center() = bottom_right()
                    newpx_bottom() = top_left()
                    if bottom_right() == out_right_bottom():
                        newpx_right() = bottom_right()
                    else:
                        newpx_right() = top_right()
                    map_v(color("#000000"), color("#000000"), color("#604000"))
                else:
                    if dist(top_left(), top_right()) < dist(top_left(), bottom_right()):
                        newpx_center() = top_right()
                        newpx_right() = bottom_right()
                    else:
                        newpx_center() = bottom_right()
                        newpx_right() = top_right()
                    newpx_bottom() = bottom_right()
                    newpx_top() = top_right()
                    map_v(color("#000000"), color("#000000"), color("#000000"))
                map_hl(color("#C0B030"))
                continue
            let c03 = sum(top_left()) == sum(bottom_right())
            let c12 = sum(top_right()) == sum(bottom_left())
            let arr_all = [top_left(),
                            top_right(),
                            bottom_left(),
                            bottom_right(),
                            out_top_left(),
                            out_top_right(),
                            out_right_top(),
                            out_right_bottom(),
                            out_bottom_right(),
                            out_bottom_left(),
                            out_left_bottom(),
                            out_left_top(),
                            newpx_top(),
                            newpx_left(),
                            newpx_center(),
                            newpx_right(),
                            newpx_bottom()]
            if c03 and not c12:
                map_diagonal(color("#000000"), color("#700040"), color("#000000"), color("#700040"))
                newpx_center() = top_left()
                if dist(top_left(), top_right()) < dist(top_left(), bottom_left()):
                    var newpx1 = closest(arr_all, avg(top_left(), top_right()))
                    newpx_top() = newpx1
                    newpx_right() = newpx1
                    newpx_left() = closest(arr_all, avg(bottom_left(), out_left_top()))
                    newpx_bottom() = closest(arr_all, avg(bottom_left(), out_bottom_right()))
                else:
                    var newpx1 = closest(arr_all, avg(top_left(), bottom_left()))
                    newpx_left() = newpx1
                    newpx_bottom() = newpx1
                    newpx_top() = closest(arr_all, avg(top_right(), out_top_left()))
                    newpx_right() = closest(arr_all, avg(top_right(), out_right_bottom()))
            elif c12 and not c03:
                map_diagonal(color("#000000"), color("#000000"), color("#007040"), color("#007040"))
                newpx_center() = top_right()
                if dist(top_right(), top_left()) < dist(top_right(), bottom_right()):
                    var newpx1 = closest(arr_all, avg(top_right(), top_left()))
                    newpx_top() = newpx1
                    newpx_left() = newpx1
                    newpx_right() = closest(arr_all, avg(bottom_right(), out_right_top()))
                    newpx_bottom() = closest(arr_all, avg(bottom_right(), out_bottom_left()))
                else:
                    var newpx1 = closest(arr_all, avg(top_right(), bottom_right()))
                    newpx_right() = newpx1
                    newpx_bottom() = newpx1
                    newpx_top() = closest(arr_all, avg(top_left(), out_top_right()))
                    newpx_left() = closest(arr_all, avg(top_left(), out_left_bottom()))
            let c0left = top_left() == out_left_top()
            let c0corner = top_left() == out_corner_tl()
            let c0top = top_left() == out_top_left()
            let c0count = (if c0left: 1 else: 0) + (if c0corner: 1 else: 0) + (if c0top: 1 else: 0)
            let c1right = top_right() == out_right_top()
            let c1corner = top_right() == out_corner_tr()
            let c1top = top_right() == out_top_right()
            let c1count = (if c1right: 1 else: 0) + (if c1corner: 1 else: 0) + (if c1top: 1 else: 0)
            let c2left = bottom_left() == out_left_bottom()
            let c2corner = bottom_left() == out_corner_bl()
            let c2bottom = bottom_left() == out_bottom_left()
            let c2count = (if c2left: 1 else: 0) + (if c2corner: 1 else: 0) + (if c2bottom: 1 else: 0)
            let c3right = bottom_right() == out_right_bottom()
            let c3corner = bottom_right() == out_corner_br()
            let c3bottom = bottom_right() == out_bottom_right()
            let c3count = (if c3right: 1 else: 0) + (if c3corner: 1 else: 0) + (if c3bottom: 1 else: 0)
            if c03 and c12:
                map_diagonal(color("#000000"), color("#700040"), color("#007040"), color("#4040A0"))
                discard
            else:
                # TODO maybe try sorting/constructing a tree of the relations to better fill in the pixels
                if c0count > c1count:
                    newpx_top() = top_left()
                elif c0count < c1count:
                    newpx_top() = top_right()
                else: # elif (c0count == 0) and (c1count == 0):
                    newpx_top() = closest(arr_all, avg(top_left(), top_right()))
                if c1count > c3count:
                    newpx_right() = top_right()
                elif c1count < c3count:
                    newpx_right() = bottom_right()
                else: # elif (c1count == 0) and (c3count == 0):
                    newpx_right() = closest(arr_all, avg(top_right(), bottom_right()))
                if c0count > c2count:
                    newpx_left() = top_left()
                elif c0count < c2count:
                    newpx_left() = bottom_left()
                else: # elif (c0count == 0) and (c2count == 0):
                    newpx_left() = closest(arr_all, avg(top_left(), bottom_left()))
                if c2count > c3count:
                    newpx_bottom() = bottom_left()
                elif c2count < c3count:
                    newpx_bottom() = bottom_right()
                else: # elif (c2count == 0) and (c3count == 0):
                    newpx_bottom() = closest(arr_all, avg(bottom_left(), bottom_right()))
                if c0count > c1count:
                    if c0count > c2count:
                        if c0count > c3count:
                            newpx_center() = top_left()
                        else:
                            newpx_center() = bottom_right()
                    else:
                        if c2count > c3count:
                            newpx_center() = bottom_left()
                        else:
                            newpx_center() = bottom_right()
                else:
                    if c1count > c2count:
                        if c1count > c3count:
                            newpx_center() = top_right()
                        else:
                            newpx_center() = bottom_right()
                    else:
                        if c2count > c3count:
                            newpx_center() = bottom_left()
                        else:
                            newpx_center() = bottom_right()
                map_diagonal(color("#402060"), color("#000000"), color("#000000"), color("#A00000"))