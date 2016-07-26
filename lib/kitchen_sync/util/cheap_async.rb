require 'thread'

module KitchenSync::Util
  class CheapAsync
    def self.perform(&block)
      p = KitchenSync::Promise.new
      Thread.new do
        sleep 0
        begin
          p.resolve!(block.call)
        rescue Exception => e
          p.reject!(e)
        end
      end
      p
    end
  end
end
