require 'thread'
require 'fiber'
require_relative './promise'

Thread.abort_on_exception = true

class EventManager
  def self.run(&block)
    @manager = self.new
    @manager.set_thread!(Thread.new do
      @manager.loop!(&block)
    end).join
  end

  def self.current
    @manager
  end

  def self.broadcast(id, data)
    @manager.broadcast(id, data)
  end

  def self.async(&block)
    @manager.async(&block)
  end

  def self.has_listener?(id)
    @manager.has_listener? id
  end

  def self.transfer_fiber
    (Thread.current[:fiber_context] || @manager).transfer_fiber
  end

  def self.add_poller(poller)
    @manager.add_poller(poller)
  end

  def initialize
    @listeners = {}
    @pollers = []
    @resumers = []
    @queue = Queue.new
  end

  attr_reader :fiber


  def loop!(&block)
    # This gets complicated, so we try to explain this as much as we can.
    
    # First, define an overall fiber that holds our sub-fibers
    mainfiber = Fiber.new do
      # the loopfiber runs the event loop
      # We can't transfer control to this fiber until the setup
      # block is finished running.
      loopfiber = Fiber.new do
        loop do
          # First, poll for events
          @pollers.each{|p| p.call}

          if @listeners.empty?
            @resumers.each do |res|
              if res.alive?
                res.transfer
              end
            end
            mainfiber.transfer
          end
          handle_event(@queue.pop)
        end
      end


      # The blockfiber runs to setup our events and listeners.
      # Once that's finished, we transfer control to our loop fiber.
      # From then on, we always want to transfer control to the loop fiber.
      # This is why we set @fiber = loopfiber
      blockfiber = Fiber.new do
        instance_eval(&block)
        @fiber = loopfiber
        loopfiber.resume
      end

      # Allow all of our events to run properly
      while blockfiber.alive? do
        blockfiber.transfer
      end
    end

    # initially we want to run our setup block, so we set our 
    # @fiber to the overall main fiber
    @fiber = mainfiber
    # We then run it 
    @fiber.resume 
  end

  def listen(id, listener)
    @listeners[id] = listener
  end

  def handle_event(event)
    id, data = event
    handler = @listeners.delete(id)
    if handler.is_a? Proc
      handler.call(data)
    else
      handler.transfer(data)
    end
  end

  def broadcast(id, data)
    @queue << [id, data]
  end

  def set_thread!(thread)
    @thread = thread
  end

  def async(&block)
    async_fiber = AsyncFiber.new(self, &block).make_fiber
    @resumers << async_fiber
    async_fiber.resume
  end

  def has_listener?(id)
    @listeners.has_key? id
  end

  def add_poller(poller)
    @pollers << poller
  end

  def nesting_level
    0
  end

  def transfer_fiber
    @fiber
  end

end

class AsyncFiber
  def initialize(context, &block)
    @context = context
    @block = block
    @nesting_level = context.nesting_level + 1
    @finished = false
  end

  attr_reader :fiber
  attr_reader :nesting_level

  def make_fiber
    @fiber = Fiber.new do
      Thread.current[:fiber_context] = @context
      instance_eval(&@block)
      # Mark ourselves as being done with our synchronous work
      @finished = true
      # Transfer control to our nearest unfinished parent, which may be
      # the root context
      transfer_fiber.transfer
    end
    @fiber
  end

  def async(&block)
    AsyncFiber.new(self, &block).make_fiber.transfer
  end

  def transfer_fiber
    if @finished
      @context.transfer_fiber
    else
      @fiber
    end
  end

  protected

  def transfer_to_unfinished!
    ctx = @context
    while ctx.is_a?(self.class) && ctx.finished?
      ctx = ctx.context
    end
    ctx.fiber.transfer
  end

  def context
    @context
  end

  def finished?
    @finished
  end
end
