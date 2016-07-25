class CheapAsync
  def self.perform(&block)
    p = Promise.new
    Thread.new do
      sleep 0
      block.call(p)
    end
    p
  end
end
