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

#### Slide 3 - Requirements

Unlike the original, the tcl port has some non-core dependencies:

[tcllib] for the [generator] package, and [tDOM] for XML parsing. If
your OS's tcl distribution splits threads into a separate package
(Like Ubuntu), you'll want that too.


Filenames will be `foo.tcl` instead of `foo.py`. They live in the
`coroutines/` subdirectory.

[tcllib]: https://www.tcl.tk/software/tcllib/
[generator]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/generator/generator.md
[tDOM]: http://tdom.org/index.html/dir?ci=release

#### Slide 6 - About Me

I (Shawn, not Dave) only learned tcl a few years ago, but quickly fell
in love. I have no big name programs or books to my credit.

#### Slide 8 - Coroutines and Generators

tcl got coroutine support in 8.6. It's never had native generators,
but they're trivial to create on top of coroutines. The [tcllib]
[generator] package does just that, and we'll use it in the generator
examples, because it solves a few things you have to worry about with
direct coroutines, like telling when they exit.

#### Slide 14 - Performance Details

I'm using Ubuntu 18.04 on a dinky old Chromebook for most stuff. Run
your own benchmarks to get more accurate numbers for your systems!

### Part 1

#### Slides 16-19 - Generators

See `countdown.tcl` for the tcl code. `generator foreach`, much like
Python's `in`, hides all the details about having to repeatedly invoke
the generator to get new values.

#### Slide 20 - A Practical Example

See `follow.tcl` for the tcl code. David's original log file
simulator, `logsim.py`, is included with minimal changes to make it
run under Python 3.

#### Slide 21 - A Pipeline Example

See `pipeline.tcl` for the tcl code.

### Part 2

### Part 3

##### Slides 69 through 71

The earlier Python XML programs use an OO interface; these use a
lower-level one that mimics what tDOM provides. So refer to the
previous tcl programs.

#### Slide 72 - Going Lower

Not going to bother with a C version right now.

#### Slide 74 - Interlude

There are other tcl XML parsers, but tDOM is the fastest one in my tests.

### Part 4

Python threads and tcl threads have very different models; these
aren't going to be straightforward translations. On hold for now.

### Part 5

### Part 6

### Part 7

Substitute `tclosN.tcl` for `pyosN.py`.
