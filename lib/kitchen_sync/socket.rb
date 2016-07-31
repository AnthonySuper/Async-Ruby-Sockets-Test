require 'nio'
require_relative './promise'
require 'socket'
require 'pry'

module KitchenSync
  class Socket
    def self.selector
      if @selector
        @selector
      else
        @selector = ::NIO::Selector.new
        l = lambda do
          if @selector.empty?
            EventManager.remove_poller(l)
          end
          @selector.select(0.5) do |ready|
            ready.value.call
          end
        end
        EventManager.add_poller(l)
        @selector
      end
    end

    def self.use(socket, mode: :rw, &block)
      raise "need a block to do that" unless block_given?
      monitor = self.selector.register(socket, mode)
      s = self.new(monitor)
      block.call(s)
      monitor.close
    end

    def initialize(monitor)
      @monitor = monitor
      @monitor.value = lambda{}
    end

    def read(size)
      p = Promise.new
      @monitor.value = lambda do
        if @monitor.readable?
          p.resolve!(@monitor.io.read_nonblock(size))
        end
      end
      p
    end

    def write(data)
      p = Promise.new
      @monitor.value = lambda do
        if @monitor.writeable?
          p.resolve!(@monitor.io.write_nonblock(data))
        end
      end
      p
    end
  end
end
