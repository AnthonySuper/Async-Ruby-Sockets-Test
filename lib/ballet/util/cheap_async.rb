require 'thread'

module Ballet::Util
  class CheapAsync
    def self.perform(&block)
      p = Ballet::Promise.new
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
