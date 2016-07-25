require './promise.rb'

module DelayValue
  def self.give_after_delay(val, delay)
    p = Promise.new
    Thread.new do
      sleep(delay)
      p.resolve!(val)
    end
    return p
  end
end

