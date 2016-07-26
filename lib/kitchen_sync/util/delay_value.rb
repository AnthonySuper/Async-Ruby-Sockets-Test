module KitchenSync::Util
  module DelayValue
    def self.give_after_delay(val, delay)
      p = KitchenSync::Promise.new
      Thread.new do
        sleep(delay)
        p.resolve!(val)
      end
      return p
    end
  end
end
