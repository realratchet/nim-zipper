# Zipper

Zipper is a macro that adds Python-like `zip` generator iterator to nim.

## Usage

```nim
from zipper import zipper

proc myIter(): iterator: int =
    return iterator: int =
        for i in 4..10:
            yield i

for tpl in zipper(["a", "b", "c"], @[0.0, 1.0, 2.0], myIter()):
    echo tpl

>>> ("a", 0.0, 4)
>>> ("b", 1.0, 5)
>>> ("c", 2.0, 6)
```

## Features

Zipper supports `array`, `seq` and `iterator` inputs and allows for `n>=1` number of iterators to be passed to it. Similarly to Python's `zip`, `zipper` will short-circuit to the shortest iterator if number of elements in the iterators is not equal.

## Known issues

Cannot be used with `openArray` due to GC model marking the iterators as unpredictable.

Destructuring cannot be done at the `for` loop level, i.e., `for (a, b) in zipper(...)` is not possible. As far as I can tell this is a limitation in the syntax tree parsing as of Nim `2.0.2`.
