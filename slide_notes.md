A Curious Course On Coroutines And Concurrency - TCL edition
============================================================

Introduction
------------

Notes on the slides of David Beazley's [A Curious Course On Coroutines
And Concurrency] talk describing how tcl coroutines differ from Python
ones.

[A Curious Course On Coroutines And Concurrency]: https://dabeaz.com/coroutines/index.html


The slides
----------

### Slide 3 - Requirements

Unlike the original, the tcl port has some non-core dependencies:

[tcllib] for the [generator] package, and [tDOM] for XML parsing. If
your OS's tcl distribution splits threads into a separate package
(Like Ubuntu), you'll want that too.


Filenames will be `foo.tcl` instead of `foo.py`. They live in the
`coroutines/` subdirectory.

[tcllib]: https://www.tcl.tk/software/tcllib/
[generator]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/generator/generator.md
[tDOM]: http://tdom.org/index.html/dir?ci=release
