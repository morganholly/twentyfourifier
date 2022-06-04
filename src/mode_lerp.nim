import arraymancer
import shared

proc pick* (ar: array[4, RGBA]): RGBA =
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


proc upscaleLerp* (upscaled: var Tensor[RGBA], image: Tensor[RGBA], height, width: int): void =
    for y in countup(0, height-1, 2):
        var ym1, yp2: int
        if y == 0:
            ym1 = y
            yp2 = y + 1
        elif y == height-1:
            ym1 = y-1
            yp2 = y
        else:
            ym1 = y-1
            yp2 = y + 1
        for x in countup(0, width-1, 2):
            var xm1, xp2: int
            if x == 0:
                xm1 = x
                xp2 = x + 1
            elif x == width-1:
                xm1 = x-1
                xp2 = x
            else:
                xm1 = x-1
                xp2 = x + 1
            # echo("x: ", x, " y:", y)
            # y,  x  y,  x+1
            # y+1,x  y+1,x+1
            # y,  x  y,  x+1  y,  x+2
            # y+1,x  y+1,x+1  y+1,x+2
            # y+2,x  y+2,x+1  y+2,x+2
            var x3 = scale(x)
            var y3 = scale(y)
            upscaled[y3, x3] = image[y, x]
            upscaled[y3, x3+1] = pick([image[ym1, x], image[ym1, x+1], image[y, x], image[y, x+1]])
            upscaled[y3, x3+2] = image[y, x+1]
            upscaled[y3+1, x3] = pick([image[y, xm1], image[y+1, xm1], image[y, x], image[y+1, x]])
            upscaled[y3+1, x3+1] = pick([image[y+1, x], image[y+1, x+1], image[y, x], image[y, x+1]])
            upscaled[y3+1, x3+2] = pick([image[y, xp2], image[y+1, xp2], image[y, x+1], image[y+1, x+1]])
            upscaled[y3+2, x3] = image[y+1, x]
            upscaled[y3+2, x3+1] = pick([image[yp2, x], image[yp2, x+1], image[y, x], image[y, x+1]])
            upscaled[y3+2, x3+2] = image[y+1, x+1]