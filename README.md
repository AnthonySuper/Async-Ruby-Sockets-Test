# Fiber-Based Ruby Events Test

## The hell is this?

This is mostly something I'm screwing with, using Ruby's fibers.
I think that being able to do nonblocking socket-type stuff is important, but callbacks are terrible (as is the type of stuff EventMachine uses).
So this is a way to do non-blocking stuff without callbacks.

Basically, if you've used async/await in JS or C# or something, this is that, but in Ruby.
Also, it works across threads, which is kind of neat.

## How can I check it out?

Look at `test.rb`, which does something basically useless.

## This just uses threads

Currently yes, but that's because `IO.select` is hard to figure out and I am stupid.
However, even with the threads, this does make some stuff easier.
It looks a hell of a lot cleaner than throwing Thread.new everywhere, for one thing.
It also ensures that certain things are synchronous automatically, when threads can switch anywhere.

## Unlike you, I'm smart, and can use IO.Select. You want me to PR?

Sure!

## Are you going to make this a gem?

Once I can figure out non-threaded, non-blocking IO, probably.
Even without that component this gem is useful for certain tasks, so maybe I'll release it anyway.
It's going to need formal tests and documentation before I'm really comfortable with doing so, however.

## Select is a terrible way to do non-blocking IO, why are you planning on using it?

Oh, yeah, you're right.
Well, uh, until I can implement Kqueue, I guess?
Or Epoll.
Or some other variety of async IO.
Unfortunately, I think Ruby only supports `select` out of the box, which kind of sucks.
If you have any ideas on how to fix that, shoot me a message, I guess?

