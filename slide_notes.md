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

### Introduction

#### Slide 3 - Requirements

Unlike the original, the tcl port has some non-core dependencies:

[tcllib] for the [generator] and [coroutine] packages, and [tDOM] for
XML parsing.

Filenames will be `foo.tcl` instead of `foo.py`. They live in the
`coroutines/` subdirectory.

[tcllib]: https://www.tcl.tk/software/tcllib/
[generator]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/generator/generator.md
[coroutine]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/coroutine/tcllib_coroutine.md
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

All the generator examples use the [generator] package from
[tcllib]. Instead of just a plain `yield`, generators created using
this library have to call `generator yield`. When we get into using
coroutines directly, plain `yield` will come into play.

#### Slides 16 through 19 - Generators

See `countdown.tcl` for the tcl code. `generator foreach`, much like
Python's `in`, hides all the details.

#### Slide 20 - A Practical Example

See `follow.tcl` for the tcl code, and `logsim.tcl` to generate a
random logfile.

#### Slide 21 - A Pipeline Example

See `pipeline.tcl` for the tcl code.

#### Slide 23 - Yield as an Expression

Now we start getting to coroutines proper. Python `line = (yield)` is
tcl `set line [yield]`.

#### Slide 24 - Coroutines

Tcl coroutines are created by the
[`coroutine`](https://www.tcl.tk/man/tcl8.6/TclCmd/coroutine.htm)
command.

In python, a coroutine is an object created by invoking a function
that uses `yield`. In tcl, a coroutine is given a name (The
*coroutinne context) by the first argument to `coroutine` and invoked
by treating that name like a command. Since a lot of the time you
don't know how many coroutines executing a particular routine you'll
have until runtime, it's common practice to dynamically generate a
name and yield that name as the very first thing, storing it in a
variable, instead of using some hardcoded name like you would a normal
command. The [coroutine] package from [tcllib] makes this trivial with
`coroutine::util create ...`, and many of the example programs will
use it.

#### Slides 25 through 27

Unlike Python, where a coroutine doesn't execute until `next()` or
`send()` is called on it, a coroutine in tcl starts executing at once,
and the `coroutine` command returns the first `yield`ed value. There
is no priming like the slides talk about.

#### Slides 28 through 29

Tcl coroutines can be closed by renaming the coroutine context name to
an empty string:

    rename $coro ""
    
Further attempts to call that coroutine will then raise the error `TCL
LOOKUP COMMAND name`, which can be trapped by a `try`. The coroutine
itself immediately exits; the python example of the coroutine itself
catching a `GeneratorExit` exception doesn't apply.

They can also end via the currently executing command in the context
returning normally instead of yielding. They are not cleaned up
automatically - many of the examples to come do no cleanup, leaving
coroutines sitting around on exit. Long running code probably should
avoid this. It's much like how you have to manually destroy `TclOO`
objects. I haven't looked into it yet, but the [defer] package from
[tcllib] looks useful for automating this in many cases, or using `trace`.

[defer]: https://core.tcl-lang.org/tcllib/doc/trunk/embedded/md/tcllib/files/modules/defer/defer.md

#### Slide 30 - Throwing an Exception

The code running in a coroutine can of course call `error` or the
equivalent using `return`, but I don't know if it's possible for
something else to force it to do so like the Python `throw()`
method. Maybe with some `uplevel` trickery?

#### Slide 32 - A Bogus Example

See `bogus.tcl`.

### Part 2

#### Slide 38 - An Example

See `cofollow.tcl`.

I think this is the first example that, instead of using a
freestanding proc for the coroutine, uses a lambda expression -

    coroutine foo apply {{} {code here}}
    
This is handy for small routines that are only used in a coroutine,
allowing you to define them at point of use.

#### Slide 42 - A Filter Example

See `copipe.tcl`.

This one uses another style - a proc that returns a coroutine context
name. This can result in cleaner code at point of coroutine creation -
looks like a normal command call, without having to wrap it in a
`coroutine` at point of use. I use this style a lot in the subsequent
examples.

#### Slides 44 through 46 - Example: Broadcasting

See `cobroadcast.tcl` and `cobroadcast2.tcl`.

#### Slide 48 - A Digression

Beazley finally got his wish in python 3 a while back. I understand
there was much flogging from people who didn't like the new syntax.

#### Slides 49 through 52 - Coroutines and Objects

See `benchmark.tcl`.

Coroutine calls are faster than method calls in tcl too.

Since most of the example programs are straightforward ports of the
original Python code, and PYthon uses objects a lot, many of the tcl
versions use `TclOO` a lot.

### Part 3

#### Slide 58 - Minimal SAX Example

See `basicsax.tcl`.

Todo: See if there's a Pythonesque OO wrapper for tDOM's SAX interface.

#### Slide 60 - From SAX to Coroutines

See `cosax.tcl`.

#### Slide 63 - Buses To Dictionaries

See `buses.tcl`.

#### Slides 69 through 71

The earlier Python XML programs use an OO interface; these use a
lower-level one that mimics what tDOM provides. So refer to the
previous tcl programs.

#### Slide 72 - Going Lower

Not going to bother with a C version right now.

#### Slide 74 - Interlude

There are other tcl XML parsers, but tDOM is the fastest one in my tests.

### Part 4

Python threads and tcl threads have very different models; these
aren't going to be straightforward translations. Leave that part on
hold for now.

#### Slides 86 through 87 - A Subprocess Target

Instead of pickling like the Python version, just be lazy and take
advantage of Everything Is A String to send data over the pipe to
`busproc.tcl`.

### Part 5

Pretty much everything in here applies to tcl coroutines.

### Part 6

### Part 7

This section builds up a coroutine-based task scheduler, eventually
adding non-blocking I/O, which is very hard to do in tcl without
bringing the event loop into play. Luckily, it's easy to mix that with
the scheduler being developed here - on a one-shot readable or
writable event, schedule the appropriate task to be run. (The [TclX]
extension provides a `select` interface; with that you could use the
example same appropach as the python versions instead of using the
event loop; consider providing one of the programs written in that
style as an example?)

The python versions (`pyos2.py` through `pyos8.py`) use a simple while
loop to run through the queue of tasks. The tcl versions (`tclos2.tcl`
through `tclos7.tcl`) use the tcl event loop, with each task being run
by a method that's queued via `after idle`, runs a single task, and
then queues itself up again if there's anything pending to run.

[TclX]: https://tclx.sourceforge.net/

### Part 8

Tcl doesn't have the issue described and worked around here - any
command in the call stack in a coroutine context can yield.

#### Slides 173 through 175 - Coroutine Trampoling

`trampoline.tcl` is an example using `yieldto` to transfer control to
another subroutine that itself returns a new coroutine.

#### Slides 176 through 183 - An Implementation

That's overkill for the purpose of `tclos8.tcl` and `echoserver.tcl`,
though, which are much simpler than `pyos8.py` - there were no changes
made to the Task and Scheduler classes to add support for functions
that themselves yield back to the scheduler when called from a task.

### Part 9

The "OS" the last few parts create has potential for expansion (Things
like task priorities, for example), but is massive overkill for a lot
of uses. Much of the time simply using corouties as callbacks in the
event loop will give you the same effect of writing what looks like
normal serialized code that ends up actually running asynchronously
with other callbacks mixed in.

`blaster.tcl`, the program that spews connections at the echo servers,
is a example of this. So is `follow-el.tcl` (which should be compared
to `follow.tcl` and `cofollow.tcl`), and `echoserver-el.tcl`. All of
these make use of the utility functions in the [coroutine] package
that simplify mixing the event loop and coroutines.

Conclusion
----------

The End.
