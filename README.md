# Fiber-Based Ruby Events Test

## The hell is this?

This is mostly something I'm screwing with, using Ruby's fibers.
I think that being able to do nonblocking socket-type stuff is important, but callbacks are terrible (as is the type of stuff EventMachine uses).
So this is a way to fix that.

## How can I check it out?

Look at `test.rb`, which does something basically useless.

## This just uses threads

Currently yes, but that's because `IO.select` is hard to figure out and I am stupid.
However, even with the threads, this does make some stuff easier.
It looks a hell of a lot cleaner than throwing Thread.new everywhere, for one thing.


