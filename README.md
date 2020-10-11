A Curious Course On Coroutines And Concurrency - TCL edition
============================================================

TCL versions of the example programs in David Beazley's Python talk [A
Curious Course On Coroutines And Concurrency], and notes to go along
with his slides on how TCL coroutines differ from Python coroutines.


Dependencies
------------

tcl 8.6 for coroutines, [tcllib] for the [generator] and [coroutine]
packages, and [tDOM] for XML parsing. If your OS's tcl distribution
splits threads into a separate package (Like Ubuntu), you'll want that
too.

[A Curious Course On Coroutines And Concurrency]: https://dabeaz.com/coroutines/index.html
[tcllib]: https://www.tcl.tk/software/tcllib/
[generator]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/generator/generator.md
[coroutine]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/coroutine/tcllib_coroutine.md
[tDOM]: http://tdom.org/index.html/dir?ci=release
