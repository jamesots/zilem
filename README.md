Zilem
=====

This is the Z80 emulator I wrote for my A-level computer science
project back in 1994. I don't remember how close it came to emulating
a real Z80 - I imagine I probably tried to emulate what was documented
in the Z80 manual, rather than trying to make it exactly match how a
real Z80 worked.

It is written in Turbo Pascal with the Turbo Vision text-based windowing
libraries.

There is a bug in Turbo Pascal which causes a runtime error if a programme
is started on a CPU running at more than 200MHz (see
http://www.pcmicro.com/elebbs/faq/rte200.html). ZILEMF.EXE has been
patched so that it will work on fast processors, while ZILEM.EXE is the
original version.
