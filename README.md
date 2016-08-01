# Ballet
Ballet provides utilities for concurrent programming in Ruby.
It is not close to finished yet, however, the eventual goal is to make the usage of non-blocking, event-based IO completely transparent to the user.

Ballet uses Ruby's fibers to handle evented programming, so you don't need callbacks.
Instead, control is transparently passed between different fibers of execution, allowing you to write programs in a synchronous way while taking advantage of asynchronous features.

