import std/[unittest, enumerate]
from zipper import zipper

proc myIter(c: int = 5): iterator: int =
    return iterator: int =
        for i in 0..<c:
            yield i

proc myIterStr(): auto =
    return iterator: auto =
        yield "a"
        yield "b"
        yield "c"

test "one iter":
    var expected = @[
      (0, ),
      (1, ),
      (2, ),
      (3, ),
      (4, )
    ]

    for (i, tpl) in enumerate(zipper(myIter())):
        check expected[i] == tpl

test "two iter and short circuit":
    var expected = @[
      (0, "a"),
      (1, "b"),
      (2, "c")
    ]

    for (i, tpl) in enumerate(zipper(myIter(), myIterStr())):
        check expected[i] == tpl

test "seq":
    var expected = @[
      (0, 5),
      (1, 6),
      (2, 7),
      (3, 8),
      (4, 9)
    ]

    for (i, tpl) in enumerate(zipper(myIter(), @[5, 6, 7, 8, 9])):
        check expected[i] == tpl


test "array":
    var expected = @[
      (0, 5),
      (1, 6),
      (2, 7),
      (3, 8),
      (4, 9)
    ]

    for (i, tpl) in enumerate(zipper(myIter(), [5, 6, 7, 8, 9])):
        check expected[i] == tpl

proc fnTest(elems: seq[int]): void =
    var expected = @[
        (0, 5),
        (1, 6),
        (2, 7),
        (3, 8),
        (4, 9)
    ]

    for (i, tpl) in enumerate(zipper(myIter(), elems)):
        check expected[i] == tpl

test "func":
    fnTest(@[5, 6, 7, 8, 9])

test "tuple":
    var input = @[
      (0, 5),
      (1, 6),
      (2, 7),
      (3, 8),
      (4, 9)
    ]

    var expected = @[
      ((0, 5), ),
      ((1, 6), ),
      ((2, 7), ),
      ((3, 8), ),
      ((4, 9), )
    ]

    for (i, tpl) in enumerate(zipper(input)):
        check expected[i] == tpl
