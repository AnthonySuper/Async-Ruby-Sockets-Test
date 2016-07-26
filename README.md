# KitchenSync
KitchenSync provides utilities for concurrent programming in Ruby.
It is not close to finished yet, however, the eventual goal is to make the usage of non-blocking, event-based IO completely transparent to the user.

KitchenSync uses Ruby's fibers to handle evented programming, so you don't need callbacks.
Instead, control is transparently passed between different fibers of execution, allowing you to write programs in a synchronous way while taking advantage of asynchronous features.

## Isn't that like threads?

Sort of.
However, Ruby's fibers do not have the overhead of system-level threads, potentially making them faster.
They also only pass control between each other when you need to wait for a value, which can make synchronization easier.

## How can I check it out?

Look at `test.rb`, which does something basically useless.
It technically makes use of threads instead of something like Epoll or Kqueue, however, you can see a clear benefit to the style of programming.
For an actual evented example, check out `socket_test.rb`, which does use an asynchronous, event-based API in a synchronous way.
